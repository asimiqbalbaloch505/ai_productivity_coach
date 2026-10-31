enum FocusSessionType {
  focus('FOCUS'),
  shortBreak('SHORT_BREAK'),
  longBreak('LONG_BREAK');

  const FocusSessionType(this.dbValue);

  final String dbValue;

  static FocusSessionType fromDb(Object? value) {
    final normalized = value?.toString().toUpperCase();
    if (normalized == null || normalized.isEmpty) return FocusSessionType.focus;
    return FocusSessionType.values.firstWhere(
      (type) => type.dbValue == normalized,
      orElse: () => throw FormatException('Unknown focus session type: $value'),
    );
  }
}

class FocusSession {
  const FocusSession({
    required this.id,
    required this.durationMinutes,
    required this.completedAt,
    required this.type,
    this.taskId,
  });

  final String id;
  final int durationMinutes;
  final DateTime completedAt;
  final FocusSessionType type;
  final String? taskId;

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id']?.toString() ?? '',
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 0,
      completedAt: DateTime.parse(map['completed_at'] as String).toLocal(),
      type: FocusSessionType.fromDb(map['session_type']),
      taskId: map['task_id']?.toString(),
    );
  }
}

class FocusSummary {
  const FocusSummary({
    required this.todayMinutes,
    required this.weekSessions,
    required this.averageFocusPercent,
  });

  final int todayMinutes;
  final int weekSessions;
  final int averageFocusPercent;
}

class HabitConsistency {
  const HabitConsistency({required this.title, required this.completionRate});

  final String title;
  final double completionRate;
}

class FocusAnalyticsData {
  const FocusAnalyticsData({
    required this.taskCompletionPercent,
    required this.focusedMinutes,
    required this.habitConsistencyPercent,
    required this.dailyFocusMinutes,
    required this.habits,
  });

  final int taskCompletionPercent;
  final int focusedMinutes;
  final int habitConsistencyPercent;
  final List<int> dailyFocusMinutes;
  final List<HabitConsistency> habits;
}
