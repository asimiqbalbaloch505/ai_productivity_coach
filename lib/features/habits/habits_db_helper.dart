// lib/features/habits/habits_db_helper.dart
// All Supabase access for the Habits module lives here
// (tables: habits, habit_logs, and a read of profiles.full_name).

import 'package:supabase_flutter/supabase_flutter.dart';

import 'habit_models.dart';

class HabitsDBHelper {
  // Resolved lazily so that merely creating a screen never throws if
  // Supabase has not been initialised yet.
  SupabaseClient get _supabase => Supabase.instance.client;

  // ------------------------------------------------------------------ habits

  /// Habits of the signed-in user. If nobody is signed in yet, all habits
  /// are returned so the seed data can be tested before auth is merged.
  Future<List<Habit>> getHabits() async {
    final uid = _supabase.auth.currentUser?.id;
    var query = _supabase.from('habits').select();
    if (uid != null) {
      query = query.eq('user_id', uid);
    }
    final data = await query.order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data).map(Habit.fromMap).toList();
  }

  Future<void> addHabit({
    required String title,
    required HabitFrequency frequency,
    String? reminderTime,
    int? goalDays,
    String? cue,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required to create a habit.');
    }
    final base = <String, dynamic>{
      'user_id': user.id,
      'title': title.trim(),
      'frequency': frequency.dbValue,
      'streak_count': 0,
    };
    final extras = <String, dynamic>{};
    if (reminderTime != null) extras['reminder_time'] = reminderTime;
    if (goalDays != null) extras['goal_days'] = goalDays;
    if (cue != null) extras['cue'] = cue;
    try {
      await _supabase.from('habits').insert({...base, ...extras});
    } on PostgrestException catch (e) {
      // The optional columns are not in the table yet -> save the core fields.
      if (_isMissingColumn(e)) {
        await _supabase.from('habits').insert(base);
      } else {
        rethrow;
      }
    }
  }

  Future<void> updateHabit({
    required String id,
    required String title,
    required HabitFrequency frequency,
    String? reminderTime,
    int? goalDays,
    String? cue,
  }) async {
    final base = <String, dynamic>{
      'title': title.trim(),
      'frequency': frequency.dbValue,
    };
    final extras = <String, dynamic>{
      'reminder_time': reminderTime,
      'goal_days': goalDays,
      'cue': cue,
    };
    try {
      await _supabase.from('habits').update({...base, ...extras}).eq('id', id);
    } on PostgrestException catch (e) {
      if (_isMissingColumn(e)) {
        await _supabase.from('habits').update(base).eq('id', id);
      } else {
        rethrow;
      }
    }
  }

  /// Logs are removed automatically (ON DELETE CASCADE).
  Future<void> deleteHabit(String id) async {
    await _supabase.from('habits').delete().eq('id', id);
  }

  bool _isMissingColumn(PostgrestException e) {
    final message = e.message.toLowerCase();
    return e.code == 'PGRST204' ||
        e.code == '42703' ||
        (message.contains('column') &&
            (message.contains('schema cache') ||
                message.contains('does not exist')));
  }

  // -------------------------------------------------------------- habit_logs

  /// Logs for the given habits on or after [from].
  Future<List<HabitLog>> getLogsSince(
    List<String> habitIds,
    DateTime from,
  ) async {
    if (habitIds.isEmpty) return [];
    final data = await _supabase
        .from('habit_logs')
        .select()
        .inFilter('habit_id', habitIds)
        .gte('completed_at', formatDbDate(from));
    return List<Map<String, dynamic>>.from(data).map(HabitLog.fromMap).toList();
  }

  /// Marks the habit as completed / skipped for today (one log per habit per
  /// day) and returns the recalculated streak.
  Future<int> setLog(Habit habit, HabitLogStatus status) async {
    final today = formatDbDate(dateOnly(DateTime.now()));
    final existing = await _supabase
        .from('habit_logs')
        .select('id')
        .eq('habit_id', habit.id)
        .eq('completed_at', today);
    final rows = List<Map<String, dynamic>>.from(existing);

    if (rows.isEmpty) {
      await _supabase.from('habit_logs').insert({
        'habit_id': habit.id,
        'completed_at': today,
        'status': status.dbValue,
      });
    } else {
      await _supabase
          .from('habit_logs')
          .update({'status': status.dbValue})
          .eq('id', rows.first['id'] as String);
    }
    return _recalculateStreak(habit);
  }

  /// Removes today's log (undo) and returns the new streak.
  Future<int> clearLog(Habit habit) async {
    await _supabase
        .from('habit_logs')
        .delete()
        .eq('habit_id', habit.id)
        .eq('completed_at', formatDbDate(dateOnly(DateTime.now())));
    return _recalculateStreak(habit);
  }

  Future<int> _recalculateStreak(Habit habit) async {
    final data = await _supabase
        .from('habit_logs')
        .select('completed_at')
        .eq('habit_id', habit.id)
        .eq('status', HabitLogStatus.completed.dbValue);
    final dates = List<Map<String, dynamic>>.from(data)
        .map((row) => dateOnly(DateTime.parse(row['completed_at'] as String)))
        .toList();

    final streak = computeStreak(dates, habit.frequency, DateTime.now());
    await _supabase
        .from('habits')
        .update({'streak_count': streak})
        .eq('id', habit.id);
    return streak;
  }

  // ----------------------------------------------------------------- profile

  /// Full name of the signed-in user (for the avatar initials), or null.
  Future<String?> getProfileName() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _supabase
        .from('profiles')
        .select('full_name')
        .eq('id', uid)
        .maybeSingle();
    return row?['full_name'] as String?;
  }

  // ------------------------------------------------------------------ streak

  /// Counts consecutive periods with at least one COMPLETED check-in.
  /// Daily habits count days, weekly habits count weeks (Monday start).
  /// The streak runs up to today / this week; if the current period has no
  /// check-in yet it is not counted but does not break the streak. A skipped
  /// or missed period breaks it.
  static int computeStreak(
    List<DateTime> completedDates,
    HabitFrequency frequency,
    DateTime now,
  ) {
    final today = dateOnly(now);
    final isWeekly = frequency == HabitFrequency.weekly;

    final periods = completedDates
        .map((d) => isWeekly ? startOfWeek(d) : dateOnly(d))
        .toSet();

    DateTime step(DateTime d, int by) => addDays(d, isWeekly ? 7 * by : by);

    var cursor = isWeekly ? startOfWeek(today) : today;
    if (!periods.contains(cursor)) {
      cursor = step(cursor, -1);
    }
    var streak = 0;
    while (periods.contains(cursor)) {
      streak++;
      cursor = step(cursor, -1);
    }
    return streak;
  }
}
