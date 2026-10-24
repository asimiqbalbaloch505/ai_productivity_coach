import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard_models.dart';

/// Data access for the dashboard (supabase_flutter v2 API).
class DashboardDBHelper {
  /// [overrideUserId] lets you test with seeded data before Auth is merged.
  DashboardDBHelper({this.overrideUserId});

  final String? overrideUserId;
  final _supabase = Supabase.instance.client;

  String get _uid {
    final id = overrideUserId ?? _supabase.auth.currentUser?.id;
    if (id == null) {
      throw const DashboardException('You are signed out. Log in to see your day.');
    }
    return id;
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DashboardException _wrap(Object e) {
    if (e is DashboardException) return e;
    if (e is SocketException) {
      return const DashboardException(
          'No internet connection. Check your network and try again.',
          isOffline: true);
    }
    if (e is TimeoutException) {
      return const DashboardException('The request timed out. Try again.', isOffline: true);
    }
    if (e is PostgrestException) {
      return DashboardException('Could not load your data: ${e.message}');
    }
    return DashboardException('Something went wrong. Try again.');
  }

  Future<DashboardData> fetchDashboard() async {
    final uid = _uid;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final monthStart = today.subtract(const Duration(days: 29));

    try {
      final profileF = _supabase.from('profiles').select().eq('id', uid).maybeSingle();
      final tasksF = _supabase.from('tasks').select().eq('user_id', uid);
      final habitsF = _supabase.from('habits').select().eq('user_id', uid);
      final focusF = _supabase
          .from('focus_sessions')
          .select()
          .eq('user_id', uid)
          .gte('completed_at', monthStart.toUtc().toIso8601String());
      final unreadF = _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', uid)
          .eq('is_read', false);

      final profile = await profileF;
      final taskRows = List<Map<String, dynamic>>.from(await tasksF);
      final habitRows = List<Map<String, dynamic>>.from(await habitsF);
      final focusRows = List<Map<String, dynamic>>.from(await focusF);
      final unreadRows = List<Map<String, dynamic>>.from(await unreadF);

      // Habit logs for the last 7 days (needs habit ids first).
      final ids = habitRows.map((h) => h['id'] as String).toList();
      final weekDone = <String, int>{};
      final todayStatus = <String, String>{};
      if (ids.isNotEmpty) {
        final logs = List<Map<String, dynamic>>.from(await _supabase
            .from('habit_logs')
            .select()
            .inFilter('habit_id', ids)
            .gte('completed_at', _dateOnly(weekStart)));
        final todayStr = _dateOnly(today);
        for (final l in logs) {
          final id = l['habit_id'] as String;
          final status = (l['status'] ?? 'COMPLETED') as String;
          if (status == 'COMPLETED') weekDone[id] = (weekDone[id] ?? 0) + 1;
          if (l['completed_at'] == todayStr && todayStatus[id] != 'COMPLETED') {
            todayStatus[id] = status;
          }
        }
      }

      final habits = habitRows
          .map((h) => DashHabit(
                id: h['id'] as String,
                title: (h['title'] ?? '') as String,
                frequency: (h['frequency'] ?? 'DAILY') as String,
                streak: (h['streak_count'] ?? 0) as int,
                weekDone: weekDone[h['id']] ?? 0,
                doneToday: todayStatus[h['id']] == 'COMPLETED',
                skippedToday: todayStatus[h['id']] == 'SKIPPED',
              ))
          .toList();

      var minutesToday = 0;
      final byHour = List<int>.filled(24, 0);
      for (final f in focusRows) {
        final at = DateTime.parse(f['completed_at'] as String).toLocal();
        final mins = (f['duration_minutes'] ?? 0) as int;
        byHour[at.hour] += mins;
        if (at.year == today.year && at.month == today.month && at.day == today.day) {
          minutesToday += mins;
        }
      }

      return DashboardData(
        fullName: (profile?['full_name'] ?? '') as String,
        tasks: taskRows.map(DashTask.fromMap).toList(),
        habits: habits,
        focusMinutesToday: minutesToday,
        focusMinutesByHour: byHour,
        unreadNotifications: unreadRows.length,
      );
    } catch (e) {
      throw _wrap(e);
    }
  }

  /// Checkbox on a "Next up" row.
  Future<void> setTaskCompleted(String taskId, bool value) async {
    try {
      await _supabase
          .from('tasks')
          .update({'is_completed': value})
          .eq('id', taskId)
          .eq('user_id', _uid);
    } catch (e) {
      throw _wrap(e);
    }
  }
}
