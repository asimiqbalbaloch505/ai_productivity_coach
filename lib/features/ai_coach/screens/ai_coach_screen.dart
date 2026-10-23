import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../notifications/screens/notification_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../ai_db_helper.dart';
import '../ai_models.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  static const Color cream = Color(0xFFFBF6E9);
  static const Color green = Color(0xFF087C4B);
  static const Color lavender = Color(0xFFEAE6FF);
  static const Color ink = Color(0xFF292923);
  static const Color muted = Color(0xFF77766F);
  static const Color bubble = Color(0xFFFFFEF9);
  static const Color line = Color(0xFFECE5D8);

  final AiDbHelper _db = AiDbHelper();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<CoachMessage> _messages = [];

  CoachContext? _coachContext;
  CoachPlan? _dailyPlan;

  String? _error;
  String? _conversationId;

  bool _loading = true;
  bool _generatingPlan = false;
  bool _sending = false;
  bool _saving = false;
  bool _historyLoading = false;

  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _initializeCoach();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // INITIALIZATION AND DAILY PLAN
  // ---------------------------------------------------------

  Future<void> _initializeCoach() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await _db.loadCoachContext();

      if (!mounted) return;

      setState(() {
        _coachContext = data;
        _loading = false;
      });

      await _createPlan();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _createPlan() async {
    final data = _coachContext;

    if (data == null || _generatingPlan) return;

    setState(() {
      _generatingPlan = true;
      _error = null;
    });

    try {
      final plan = await _db.generateDailyPlan(data);

      if (!mounted) return;

      setState(() {
        _dailyPlan = plan;
        _generatingPlan = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _generatingPlan = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _addPlan() async {
    final plan = _dailyPlan;

    if (plan == null || _saving) return;

    setState(() => _saving = true);

    try {
      // Save the task title, not its explanatory text.
      await _db.addPlanToToday(plan.title);

      if (!mounted) return;

      _showMessage('Your plan was added to today’s tasks.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ---------------------------------------------------------
  // CONVERSATION MANAGEMENT
  // ---------------------------------------------------------

  Future<void> _startNewConversation() async {
    if (_sending) {
      _showMessage('Please wait for the current response to finish.');
      return;
    }

    setState(() {
      _conversationId = null;
      _messages.clear();
      _error = null;
      _controller.clear();
    });

    _scrollToBottom();
  }

  Future<String> _ensureConversation(String firstMessage) async {
    if (_conversationId != null) {
      return _conversationId!;
    }

    final id = await _db.createConversation(firstMessage);

    if (!mounted) {
      throw Exception('The screen was closed.');
    }

    setState(() {
      _conversationId = id;
    });

    return id;
  }

  Future<void> _loadConversation(String id) async {
    if (_sending) {
      _showMessage('Please wait for the current response to finish.');
      return;
    }

    Navigator.of(context).pop();

    setState(() {
      _loading = true;
      _error = null;
      _messages.clear();
      _conversationId = id;
    });

    try {
      final rows = await _db.loadConversationMessages(id);

      if (!mounted) return;

      final loadedMessages = rows.map((row) {
        final role = row['role']?.toString() ?? 'assistant';
        final content = row['content']?.toString() ?? '';
        final createdAt = DateTime.tryParse(
          row['created_at']?.toString() ?? '',
        );

        return CoachMessage(
          text: content,
          isUser: role == 'user',
          createdAt: createdAt ?? DateTime.now(),
        );
      }).toList();

      setState(() {
        _messages
          ..clear()
          ..addAll(loadedMessages);
        _loading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });

      _showMessage(_friendlyError(e));
    }
  }

  Future<void> _refreshHistory() async {
    setState(() => _historyLoading = true);

    try {
      final conversations = await _db.listConversations();

      if (!mounted) return;

      setState(() {
        _conversations = conversations;
        _historyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _historyLoading = false);
      _showMessage(_friendlyError(e));
    }
  }

  Future<void> _showHistory() async {
    await _refreshHistory();

    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cream,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.72,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Conversation history',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Refresh history',
                            onPressed: () async {
                              await _refreshHistory();
                              if (context.mounted) {
                                setSheetState(() {});
                              }
                            },
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.of(sheetContext).pop();
                            await _startNewConversation();
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Start a new conversation'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: green,
                            side: const BorderSide(color: green),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _historyLoading
                            ? const Center(
                          child: CircularProgressIndicator(
                            color: green,
                          ),
                        )
                            : _conversations.isEmpty
                            ? const Center(
                          child: Text(
                            'No saved conversations yet.\n'
                                'Your chats will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: muted,
                              height: 1.5,
                            ),
                          ),
                        )
                            : ListView.separated(
                          itemCount: _conversations.length,
                          separatorBuilder: (_, __) =>
                          const Divider(color: line),
                          itemBuilder: (context, index) {
                            final conversation =
                            _conversations[index];

                            final id =
                                conversation['id']?.toString() ?? '';
                            final title =
                                conversation['title']?.toString() ??
                                    'Conversation';
                            final updatedAt = DateTime.tryParse(
                              conversation['updated_at']
                                  ?.toString() ??
                                  '',
                            );

                            return ListTile(
                              contentPadding:
                              const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 3,
                              ),
                              leading: const CircleAvatar(
                                backgroundColor: lavender,
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF51458B),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                ),
                              ),
                              subtitle: Text(
                                updatedAt == null
                                    ? 'Saved conversation'
                                    : _formatDate(updatedAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: muted,
                                ),
                              ),
                              onTap: id.isEmpty
                                  ? null
                                  : () => _loadConversation(id),
                              trailing: IconButton(
                                tooltip: 'Delete conversation',
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: muted,
                                ),
                                onPressed: id.isEmpty
                                    ? null
                                    : () async {
                                  final confirmed =
                                  await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) =>
                                        AlertDialog(
                                          backgroundColor: cream,
                                          title: const Text(
                                            'Delete conversation?',
                                          ),
                                          content: const Text(
                                            'This will permanently '
                                                'delete this conversation '
                                                'and its messages.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                    dialogContext,
                                                    false,
                                                  ),
                                              child: const Text(
                                                'Cancel',
                                              ),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                    dialogContext,
                                                    true,
                                                  ),
                                              style: FilledButton
                                                  .styleFrom(
                                                backgroundColor:
                                                green,
                                              ),
                                              child: const Text(
                                                'Delete',
                                              ),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (confirmed != true) return;

                                  try {
                                    await _db.deleteConversation(
                                      id,
                                    );

                                    if (_conversationId == id) {
                                      setState(() {
                                        _conversationId = null;
                                        _messages.clear();
                                      });
                                    }

                                    await _refreshHistory();

                                    if (context.mounted) {
                                      setSheetState(() {});
                                    }
                                  } catch (e) {
                                    _showMessage(
                                      _friendlyError(e),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();

    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;

    if (sameDay) {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      final period = local.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $hour:$minute $period';
    }

    return '${local.day}/${local.month}/${local.year}';
  }

  // ---------------------------------------------------------
  // CHAT: SAVE MESSAGES AND SEND HISTORY TO GEMINI
  // ---------------------------------------------------------

  Future<void> _sendMessage([String? suggestion]) async {
    final text = (suggestion ?? _controller.text).trim();

    if (text.isEmpty || _sending) return;

    final data = _coachContext;

    if (data == null) {
      _showMessage('Your productivity data is not ready. Please retry.');
      return;
    }

    setState(() {
      _controller.clear();
      _sending = true;
      _error = null;

      _messages.add(
        CoachMessage(
          text: text,
          isUser: true,
          createdAt: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();

    try {
      final conversationId = await _ensureConversation(text);

      // Persist the user's message before asking Gemini.
      await _db.saveConversationMessage(
        conversationId: conversationId,
        content: text,
        isUser: true,
      );

      // Pass the previous turns to Gemini, excluding the message
      // just sent because it is already supplied as "question".
      final history = _messages
          .take(_messages.length - 1)
          .map(
            (message) => <String, String>{
          'role': message.isUser ? 'user' : 'assistant',
          'content': message.text,
        },
      )
          .toList();

      final answer = await _db.askCoach(
        question: text,
        context: data,
        history: history,
      );

      // Persist the assistant's reply as well.
      await _db.saveConversationMessage(
        conversationId: conversationId,
        content: answer,
        isUser: false,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(
          CoachMessage(
            text: answer,
            isUser: false,
            createdAt: DateTime.now(),
          ),
        );
        _sending = false;
      });

      // Refresh titles and updated timestamps for the history list.
      _refreshHistorySilently();
    } catch (e) {
      if (!mounted) return;

      final friendly = _friendlyError(e);

      setState(() {
        _messages.add(
          CoachMessage(
            text: 'I could not get a response. $friendly',
            isUser: false,
            createdAt: DateTime.now(),
          ),
        );
        _sending = false;
        _error = friendly;
      });
    }

    _scrollToBottom();
  }

  Future<void> _refreshHistorySilently() async {
    try {
      final rows = await _db.listConversations();

      if (!mounted) return;

      setState(() => _conversations = rows);
    } catch (_) {
      // A history refresh should not interrupt a successful chat response.
    }
  }

  // ---------------------------------------------------------
  // ERROR HANDLING AND SMALL HELPERS
  // ---------------------------------------------------------

  String _friendlyError(Object error) {
    final message = error.toString();
    final lower = message.toLowerCase();

    if (lower.contains('sign in first') ||
        lower.contains('authsessionmissing') ||
        lower.contains('not authenticated')) {
      return 'Please sign in to use your personal AI coach.';
    }

    if (lower.contains('smooth-api') ||
        lower.contains('functionexception') ||
        lower.contains('404')) {
      return 'Check that your smooth-api Edge Function is deployed.';
    }

    if (lower.contains('row-level security') ||
        lower.contains('permission denied') ||
        lower.contains('42501')) {
      return 'Supabase denied access. Check your database permissions.';
    }

    return message.replaceFirst('Exception: ', '');
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ---------------------------------------------------------
  // MARKDOWN RENDERER
  // ---------------------------------------------------------

  Widget _markdown(
      String text, {
        required bool isUser,
        double fontSize = 14,
      }) {
    final textColor = isUser ? Colors.white : ink;

    return MarkdownBody(
      data: text,
      selectable: true,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: fontSize,
          height: 1.5,
          color: textColor,
        ),
        h1: TextStyle(
          fontSize: fontSize + 6,
          height: 1.3,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        h2: TextStyle(
          fontSize: fontSize + 3,
          height: 1.3,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        h3: TextStyle(
          fontSize: fontSize + 1,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        strong: TextStyle(
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        em: TextStyle(
          fontStyle: FontStyle.italic,
          color: textColor,
        ),
        listBullet: TextStyle(
          fontSize: fontSize,
          height: 1.5,
          color: textColor,
        ),
        blockquote: TextStyle(
          fontSize: fontSize,
          height: 1.5,
          color: textColor,
        ),
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        blockquoteDecoration: BoxDecoration(
          color: isUser
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFF2EEE5),
          border: const Border(
            left: BorderSide(color: green, width: 3),
          ),
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize - 1,
          color: textColor,
          backgroundColor: isUser
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFECE8DE),
        ),
        codeblockDecoration: BoxDecoration(
          color: isUser
              ? Colors.black.withValues(alpha: 0.12)
              : const Color(0xFFECE8DE),
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: const EdgeInsets.all(10),
        a: const TextStyle(
          color: Color(0xFF51458B),
          decoration: TextDecoration.underline,
        ),
        horizontalRuleDecoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: line),
          ),
        ),
        tableHead: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        tableBody: TextStyle(
          fontSize: fontSize,
          color: textColor,
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // MAIN UI
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                children: [
                  _heading(),
                  const SizedBox(height: 16),
                  _planCard(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _errorCard(),
                  ],
                  const SizedBox(height: 14),
                  if (_messages.isEmpty && !_loading)
                    _emptyConversation(),
                  ..._messages.map(
                        (message) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _chatBubble(
                        message.text,
                        isUser: message.isUser,
                      ),
                    ),
                  ),
                  if (_sending)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 5, 0, 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: green,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Daywise is thinking...',
                            style: TextStyle(
                              fontSize: 13,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            const Text(
              'daywise',
              style: TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                size: 22,
                color: ink,
              ),
            ),

            // Profile button displays the signed-in user's initials.
            IconButton(
              tooltip: 'Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.person_3_rounded,
                size: 22,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _heading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your AI coach',
                style: TextStyle(
                  fontSize: 23,
                  height: 1.25,
                  color: ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _showHistory,
              icon: const Icon(Icons.history, size: 16, color: muted),
              label: const Text(
                'History',
                style: TextStyle(fontSize: 12, color: muted),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 36),
              ),
            ),
            IconButton(
              tooltip: 'New conversation',
              onPressed: _sending ? null : _startNewConversation,
              icon: const Icon(
                Icons.add_comment_outlined,
                color: green,
                size: 21,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Personalized guidance from your real patterns.',
          style: TextStyle(fontSize: 13, color: muted, height: 1.4),
        ),
      ],
    );
  }

  Widget _planCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lavender,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: Color(0xFF51458B),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A small shift for today',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading || _generatingPlan)
            const Row(
              children: [
                SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: green,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Preparing your personalized plan...',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: ink,
                    ),
                  ),
                ),
              ],
            )
          else if (_dailyPlan != null) ...[
            _markdown(
              _dailyPlan!.title,
              isUser: false,
              fontSize: 15,
            ),
            const SizedBox(height: 6),
            Text(
              _dailyPlan!.explanation,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: ink,
              ),
            ),
          ] else
            const Text(
              'Your small shift could not be generated. Please try again.',
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: ink,
              ),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                height: 40,
                child: FilledButton(
                  onPressed: _dailyPlan == null || _saving ? null : _addPlan,
                  style: FilledButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Add to today',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _generatingPlan || _coachContext == null
                    ? null
                    : _createPlan,
                icon: const Icon(Icons.refresh, size: 17),
                label: const Text('Regenerate'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF51458B),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyConversation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chatBubble(
          'Your productivity coach is ready. Ask a question or choose a '
              'suggestion below to get personalized guidance.',
          isUser: false,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _smallSuggestion(
              'How can I improve my focus?',
                  () => _sendMessage('How can I improve my focus?'),
            ),
            _smallSuggestion(
              'Help me prioritize',
                  () => _sendMessage(
                'Help me prioritize my unfinished tasks.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chatBubble(String text, {required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: isUser ? green : bubble,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(15),
              topRight: const Radius.circular(15),
              bottomLeft: Radius.circular(isUser ? 15 : 5),
              bottomRight: Radius.circular(isUser ? 5 : 15),
            ),
            border: isUser ? null : Border.all(color: line),
          ),
          child: _markdown(
            text,
            isUser: isUser,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _smallSuggestion(String label, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFF0EADB),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: _sending ? null : onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 10,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: ink),
          ),
        ),
      ),
    );
  }

  Widget _composer() {
    return Container(
      color: cream,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: bubble,
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    style: const TextStyle(fontSize: 14, color: ink),
                    decoration: const InputDecoration(
                      hintText: 'Ask anything about your progress',
                      hintStyle: TextStyle(fontSize: 13, color: muted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      onPressed: _sending ? null : () => _sendMessage(),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(
                        Icons.arrow_upward_rounded,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _smallSuggestion(
                  'Plan my day',
                      () => _sendMessage(
                    'Help me make a realistic plan for today using my tasks.',
                  ),
                ),
                const SizedBox(width: 7),
                _smallSuggestion(
                  'Review my week',
                      () => _sendMessage(
                    'Review my available productivity records and summarize them.',
                  ),
                ),
                const SizedBox(width: 7),
                _smallSuggestion(
                  'Find a pattern',
                      () => _sendMessage(
                    'Find patterns in my habits and focus sessions.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 19,
            color: Color(0xFF9B3022),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF79291E),
              ),
            ),
          ),
          TextButton(
            onPressed: _initializeCoach,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}