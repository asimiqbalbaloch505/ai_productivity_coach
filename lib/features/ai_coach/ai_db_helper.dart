import 'package:supabase_flutter/supabase_flutter.dart';

import 'ai_models.dart';

class CoachPlan {
  const CoachPlan({required this.title, required this.explanation});

  final String title;
  final String explanation;
}

class AiDbHelper {
  AiDbHelper({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ---------------------------------------------------------------------------
  // AUTHENTICATION
  // ---------------------------------------------------------------------------

  String _requireUserId() {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in first to use chat history.');
    }

    return user.id;
  }

  // ---------------------------------------------------------------------------
  // AI COACH CONTEXT
  // ---------------------------------------------------------------------------

  /// Keeps compatibility with the existing AI Coach screen.
  /// The Edge Function currently loads the demo user's records on the server.
  Future<CoachContext> loadCoachContext() async {
    return CoachContext(
      tasks: [],
      habits: [],
      habitLogs: [],
      focusSessions: [],
    );
  }

  // ---------------------------------------------------------------------------
  // DAILY PLAN GENERATION
  // ---------------------------------------------------------------------------

  Future<CoachPlan> generateDailyPlan(
    CoachContext context, {
    List<String> previousPlans = const [],
  }) async {
    await _ensureAuthenticatedProfile();

    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'smooth-api',
        body: {'action': 'plan', 'previous_plans': previousPlans},
      );
    } on FunctionsHttpException catch (error) {
      throw Exception(
        error.status >= 500
            ? 'The AI coach is temporarily unavailable. Please try again shortly.'
            : 'The AI coach could not generate guidance (HTTP ${error.status}).',
      );
    } on FunctionException catch (error) {
      throw Exception(
        error.status == 0 || error.status >= 500
            ? 'The AI coach is temporarily unavailable. Please try again shortly.'
            : 'The AI coach could not generate guidance (HTTP ${error.status}).',
      );
    }

    final data = response.data;

    if (response.status < 200 || response.status >= 300) {
      throw Exception(
        'Could not generate the daily plan: ${_errorMessage(data)}',
      );
    }

    if (data is Map) {
      // Prefer the structured response, with backward compatibility.
      final titleValue = data['title'] ?? data['answer'];
      final explanationValue = data['explanation'];

      final title = titleValue is String ? titleValue.trim() : '';
      final explanation = explanationValue is String
          ? explanationValue.trim()
          : '';

      if (title.isNotEmpty) {
        return CoachPlan(
          title: title,
          explanation: explanation.isNotEmpty
              ? explanation
              : 'A small, achievable step to help you make progress today.',
        );
      }
    }

    throw Exception('The AI function returned an unexpected response.');
  }

  Future<void> _ensureAuthenticatedProfile() async {
    final user = _client.auth.currentUser;
    final session = _client.auth.currentSession;
    if (user == null || session == null || session.user.id != user.id) {
      throw StateError('Please sign in first to use your AI coach.');
    }

    try {
      final profile = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null) return;
    } catch (_) {
      await _upsertProfile(user);
      await _client.from('profiles').select('id').eq('id', user.id).single();
      return;
    }

    await _upsertProfile(user);
    await _client.from('profiles').select('id').eq('id', user.id).single();
  }

  Future<void> _upsertProfile(User user) async {
    await _client.from('profiles').upsert({'id': user.id});
  }

  // ---------------------------------------------------------------------------
  // CONVERSATION HISTORY
  // ---------------------------------------------------------------------------

  /// Creates a new conversation using the user's first message as its title.
  /// Returns the newly created conversation ID.
  Future<String> createConversation(String firstMessage) async {
    final userId = _requireUserId();
    final cleanMessage = firstMessage.trim();

    final title = cleanMessage.isEmpty
        ? 'New conversation'
        : cleanMessage.length > 45
        ? '${cleanMessage.substring(0, 45)}...'
        : cleanMessage;

    final result = await _client
        .from('ai_conversations')
        .insert({'user_id': userId, 'title': title})
        .select('id')
        .single();

    return result['id'].toString();
  }

  /// Gets this user's conversations, with the most recently active first.
  Future<List<Map<String, dynamic>>> listConversations() async {
    final userId = _requireUserId();

    final result = await _client
        .from('ai_conversations')
        .select('id, title, created_at, updated_at')
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return List<Map<String, dynamic>>.from(result);
  }

  /// Saves a user or assistant message.
  Future<void> saveConversationMessage({
    required String conversationId,
    required String content,
    required bool isUser,
  }) async {
    final userId = _requireUserId();
    final cleanContent = content.trim();

    if (cleanContent.isEmpty) {
      throw Exception('Cannot save an empty message.');
    }

    // The conversation ID and user ID are checked against each other
    // by the database's Row Level Security policy.
    await _client.from('ai_messages').insert({
      'conversation_id': conversationId,
      'user_id': userId,
      'role': isUser ? 'user' : 'assistant',
      'content': cleanContent,
    });

    // Update the conversation's activity time for history ordering.
    await _client
        .from('ai_conversations')
        .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', conversationId)
        .eq('user_id', userId);
  }

  /// Loads all messages in chronological order for one conversation.
  Future<List<Map<String, dynamic>>> loadConversationMessages(
    String conversationId,
  ) async {
    final userId = _requireUserId();

    // Confirm that the selected conversation belongs to this user.
    final conversation = await _client
        .from('ai_conversations')
        .select('id')
        .eq('id', conversationId)
        .eq('user_id', userId)
        .maybeSingle();

    if (conversation == null) {
      throw Exception('This conversation could not be found.');
    }

    final result = await _client
        .from('ai_messages')
        .select('role, content, created_at')
        .eq('conversation_id', conversationId)
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(result);
  }

  /// Deletes a conversation. Its messages are deleted automatically
  /// by the foreign key's ON DELETE CASCADE rule.
  Future<void> deleteConversation(String conversationId) async {
    final userId = _requireUserId();

    await _client
        .from('ai_conversations')
        .delete()
        .eq('id', conversationId)
        .eq('user_id', userId);
  }

  // ---------------------------------------------------------------------------
  // AI CHAT
  // ---------------------------------------------------------------------------

  /// Sends a question to the AI.
  ///
  /// [history] contains earlier messages in chronological order.
  /// Each entry should contain:
  /// {'role': 'user' or 'assistant', 'content': 'message text'}
  ///
  /// The Edge Function must support the optional history field for the
  /// AI to actually use previous messages when generating its answer.
  Future<String> askCoach({
    required String question,
    required CoachContext context,
    List<Map<String, String>> history = const [],
  }) async {
    final cleanQuestion = question.trim();

    if (cleanQuestion.isEmpty) {
      throw Exception('Please enter a question.');
    }

    // Send only valid roles and non-empty message content.
    // Limit history to the most recent 20 messages.
    final cleanHistory = history
        .where((message) {
          final role = message['role'];
          final content = message['content'];

          return (role == 'user' || role == 'assistant') &&
              content != null &&
              content.trim().isNotEmpty;
        })
        .toList()
        .take(20)
        .map(
          (message) => {
            'role': message['role']!,
            'content': message['content']!.trim(),
          },
        )
        .toList();

    final response = await _client.functions.invoke(
      'smooth-api',
      body: {
        'action': 'chat',
        'message': cleanQuestion,
        'history': cleanHistory,
      },
    );

    final data = response.data;

    if (response.status < 200 || response.status >= 300) {
      throw Exception('Could not get an AI response: ${_errorMessage(data)}');
    }

    if (data is Map && data['answer'] is String) {
      final answer = (data['answer'] as String).trim();

      if (answer.isNotEmpty) {
        return answer;
      }
    }

    throw Exception('The AI function returned an unexpected response.');
  }

  // ---------------------------------------------------------------------------
  // ADD DAILY PLAN TO TASKS
  // ---------------------------------------------------------------------------

  /// Saves only the task title. The explanation is display-only.
  Future<void> addPlanToToday(String plan) async {
    final title = plan.trim();

    if (title.isEmpty) {
      throw Exception('There is no plan to save.');
    }

    final response = await _client.functions.invoke(
      'smooth-api',
      body: {'action': 'add_task', 'title': title},
    );

    final data = response.data;

    if (response.status < 200 || response.status >= 300) {
      throw Exception(
        'Could not add the plan to today: ${_errorMessage(data)}',
      );
    }

    if (data is! Map || data['success'] != true) {
      throw Exception('The server did not confirm that the task was saved.');
    }
  }

  // ---------------------------------------------------------------------------
  // ERROR HANDLING
  // ---------------------------------------------------------------------------

  String _errorMessage(dynamic data) {
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }

    return data?.toString() ?? 'Unknown server error';
  }
}
