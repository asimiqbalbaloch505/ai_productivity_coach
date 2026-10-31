import 'package:supabase_flutter/supabase_flutter.dart';

import 'focus_analytics_models.dart';

class FocusAnalyticsDbHelper {
  FocusAnalyticsDbHelper({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('A signed-in user is required to use focus analytics.');
    }
    return userId;
  }

  Future<List<FocusSession>> fetchSessions({
    required DateTime from,
    required DateTime until,
  }) async {
    final rows = await _client
        .from('focus_sessions')
        .select()
        .eq('user_id', _userId)
        .gte('completed_at', from.toUtc().toIso8601String())
        .lt('completed_at', until.toUtc().toIso8601String())
        .order('completed_at', ascending: true);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map(FocusSession.fromMap).toList();
  }

  Future<void> saveSession({
    required int durationMinutes,
    required FocusSessionType type,
    required DateTime completedAt,
    String? taskId,
  }) async {
    await _client.from('focus_sessions').insert({
      'user_id': _userId,
      'duration_minutes': durationMinutes,
      'completed_at': completedAt.toUtc().toIso8601String(),
      'session_type': type.dbValue,
      'task_id': taskId,
    });
  }

  Future<FocusSummary> fetchSummary() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final sessions = await fetchSessions(
      from: weekStart,
      until: now.add(const Duration(seconds: 1)),
    );
    final focusSessions = sessions
        .where((session) => session.type == FocusSessionType.focus)
        .toList();
    final todayMinutes = focusSessions
        .where((session) {
          final at = session.completedAt;
          return at.year == today.year &&
              at.month == today.month &&
              at.day == today.day;
        })
        .fold<int>(0, (total, session) => total + session.durationMinutes);
    final average = focusSessions.isEmpty
        ? 0
        : (focusSessions.fold<int>(
                    0,
                    (total, session) => total + session.durationMinutes,
                  ) /
                  (focusSessions.length * 25) *
                  100)
              .round()
              .clamp(0, 100)
              .toInt();
    return FocusSummary(
      todayMinutes: todayMinutes,
      weekSessions: focusSessions.length,
      averageFocusPercent: average,
    );
  }

  Future<FocusAnalyticsData> fetchAnalytics(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final userId = _userId;
    final sessionRows = await _client
        .from('focus_sessions')
        .select()
        .eq('user_id', userId)
        .gte('completed_at', weekStart.toUtc().toIso8601String())
        .lt('completed_at', weekEnd.toUtc().toIso8601String())
        .order('completed_at', ascending: true);
    final sessions = List<Map<String, dynamic>>.from(sessionRows)
        .map(FocusSession.fromMap)
        .where((session) => session.type == FocusSessionType.focus)
        .toList();

    final taskRows = await _client
        .from('tasks')
        .select('is_completed, deadline')
        .eq('user_id', userId)
        .gte('deadline', weekStart.toUtc().toIso8601String())
        .lt('deadline', weekEnd.toUtc().toIso8601String());
    final tasks = List<Map<String, dynamic>>.from(taskRows);
    final completedTasks = tasks
        .where((task) => task['is_completed'] == true)
        .length;

    final habitRows = await _client
        .from('habits')
        .select()
        .eq('user_id', userId);
    final habits = List<Map<String, dynamic>>.from(habitRows);
    final dailyFocusMinutes = List<int>.filled(7, 0);
    var focusedMinutes = 0;
    for (final session in sessions) {
      final dayIndex = DateTime(
        session.completedAt.year,
        session.completedAt.month,
        session.completedAt.day,
      ).difference(weekStart).inDays;
      if (dayIndex >= 0 && dayIndex < dailyFocusMinutes.length) {
        dailyFocusMinutes[dayIndex] += session.durationMinutes;
        focusedMinutes += session.durationMinutes;
      }
    }

    final habitIds = habits.map((habit) => habit['id'].toString()).toList();
    final completedByHabit = <String, int>{};
    if (habitIds.isNotEmpty) {
      final logs = await _client
          .from('habit_logs')
          .select('habit_id, status')
          .inFilter('habit_id', habitIds)
          .gte('completed_at', _formatDate(weekStart))
          .lt('completed_at', _formatDate(weekEnd));
      for (final log in List<Map<String, dynamic>>.from(logs)) {
        if ((log['status'] as String?)?.toUpperCase() == 'COMPLETED') {
          final id = log['habit_id'].toString();
          completedByHabit[id] = (completedByHabit[id] ?? 0) + 1;
        }
      }
    }

    var expectedHabitCompletions = 0;
    var completedHabitCompletions = 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final elapsedDays = todayDate.isBefore(weekStart)
        ? 0
        : (todayDate.difference(weekStart).inDays + 1).clamp(0, 7).toInt();
    final habitConsistency = <HabitConsistency>[];
    for (final habit in habits) {
      final id = habit['id'].toString();
      final isWeekly =
          (habit['frequency'] as String?)?.toUpperCase() == 'WEEKLY';
      final target = isWeekly ? 1 : elapsedDays;
      if (target == 0) continue;
      final completed = (completedByHabit[id] ?? 0).clamp(0, target);
      expectedHabitCompletions += target;
      completedHabitCompletions += completed;
      habitConsistency.add(
        HabitConsistency(
          title: (habit['title'] as String?) ?? 'Habit',
          completionRate: completed / target,
        ),
      );
    }
    habitConsistency.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );

    return FocusAnalyticsData(
      taskCompletionPercent: tasks.isEmpty
          ? 0
          : (completedTasks / tasks.length * 100).round(),
      focusedMinutes: focusedMinutes,
      habitConsistencyPercent: expectedHabitCompletions == 0
          ? 0
          : (completedHabitCompletions / expectedHabitCompletions * 100)
                .round(),
      dailyFocusMinutes: dailyFocusMinutes,
      habits: habitConsistency,
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
