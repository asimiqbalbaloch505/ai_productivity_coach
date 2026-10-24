// lib/features/habits/habit_models.dart
// Models + date helpers for the Habits module (tables: habits, habit_logs).

enum HabitFrequency {
  daily,
  weekly;

  /// Value stored in the database ('DAILY' / 'WEEKLY').
  String get dbValue => name.toUpperCase();

  String get label => this == HabitFrequency.daily ? 'Daily' : 'Weekly';

  /// Unit used for streaks / goals ("day" or "week").
  String get unit => this == HabitFrequency.daily ? 'day' : 'week';

  static HabitFrequency fromDb(String? value) =>
      (value ?? '').toUpperCase() == 'WEEKLY'
          ? HabitFrequency.weekly
          : HabitFrequency.daily;
}

enum HabitLogStatus {
  completed,
  skipped;

  /// Value stored in the database ('COMPLETED' / 'SKIPPED').
  String get dbValue => name.toUpperCase();

  static HabitLogStatus fromDb(String? value) =>
      (value ?? '').toUpperCase() == 'SKIPPED'
          ? HabitLogStatus.skipped
          : HabitLogStatus.completed;
}

class Habit {
  final String id;
  final String? userId;
  final String title;
  final HabitFrequency frequency;
  final int streakCount;
  final DateTime? createdAt;

  /// Optional extras shown on the "Build a habit" screen. They are only
  /// stored when the matching columns exist in Supabase
  /// (reminder_time, goal_days, cue) – see README_HABITS.md.
  final String? reminderTime; // 'HH:mm' (24h)
  final int? goalDays;
  final String? cue;

  const Habit({
    required this.id,
    this.userId,
    required this.title,
    required this.frequency,
    this.streakCount = 0,
    this.createdAt,
    this.reminderTime,
    this.goalDays,
    this.cue,
  });

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      title: (map['title'] as String?) ?? '',
      frequency: HabitFrequency.fromDb(map['frequency'] as String?),
      streakCount: (map['streak_count'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String)?.toLocal(),
      reminderTime: map['reminder_time'] as String?,
      goalDays: (map['goal_days'] as num?)?.toInt(),
      cue: map['cue'] as String?,
    );
  }

  /// Hour (0-23) of the reminder, defaults to 20 (8 PM).
  int get reminderHour => _parseTime(reminderTime)?.$1 ?? 20;

  /// Minute of the reminder, defaults to 0.
  int get reminderMinute => _parseTime(reminderTime)?.$2 ?? 0;

  static (int, int)? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (h, m);
  }
}

class HabitLog {
  final String id;
  final String habitId;
  final DateTime completedAt; // date only (local midnight)
  final HabitLogStatus status;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.completedAt,
    required this.status,
  });

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    final raw = (map['completed_at'] as String?) ?? '';
    final parsed = DateTime.tryParse(raw) ?? DateTime.now();
    return HabitLog(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      completedAt: dateOnly(parsed),
      status: HabitLogStatus.fromDb(map['status'] as String?),
    );
  }
}

// ---------------------------------------------------------------------------
// Date / time helpers
// ---------------------------------------------------------------------------

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Date [days] days after (or before, if negative) [d], at local midnight.
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Monday of the week containing [d].
DateTime startOfWeek(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// 'yyyy-MM-dd' – the format Postgres DATE columns expect.
String formatDbDate(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

const List<String> kWeekdayShort = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// e.g. 20:00 -> "8:00 PM"
String formatTime12(int hour, int minute) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final suffix = hour < 12 ? 'AM' : 'PM';
  return '$h12:${minute.toString().padLeft(2, '0')} $suffix';
}

/// 20:00 -> "20:00" (what we store in the database).
String formatTime24(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';