class DashboardException implements Exception {
  final String message;
  final bool isOffline;
  const DashboardException(this.message, {this.isOffline = false});
  @override
  String toString() => message;
}

class DashTask {
  final String id;
  final String title;
  final String priority; // LOW | MEDIUM | HIGH
  final DateTime? deadline;
  final bool isCompleted;

  const DashTask({
    required this.id,
    required this.title,
    required this.priority,
    required this.deadline,
    required this.isCompleted,
  });

  factory DashTask.fromMap(Map<String, dynamic> m) => DashTask(
        id: m['id'] as String,
        title: (m['title'] ?? '') as String,
        priority: (m['priority'] ?? 'MEDIUM') as String,
        deadline: m['deadline'] == null
            ? null
            : DateTime.parse(m['deadline'] as String).toLocal(),
        isCompleted: (m['is_completed'] ?? false) as bool,
      );

  DashTask copyWith({bool? isCompleted}) => DashTask(
        id: id,
        title: title,
        priority: priority,
        deadline: deadline,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  bool get isOverdue =>
      !isCompleted && deadline != null && deadline!.isBefore(DateTime.now());

  /// "Due in 2h", "Due today", "Due tomorrow", "Overdue", "Completed".
  String get statusLabel {
    if (isCompleted) return 'Completed';
    final d = deadline;
    if (d == null) return 'No deadline';
    final now = DateTime.now();
    if (d.isBefore(now)) return 'Overdue';
    final today = DateTime(now.year, now.month, now.day);
    final dayDiff = DateTime(d.year, d.month, d.day).difference(today).inDays;
    if (dayDiff == 0) {
      final diff = d.difference(now);
      if (diff.inMinutes < 60) return 'Due in ${diff.inMinutes.clamp(1, 59)}m';
      return 'Due in ${diff.inHours}h';
    }
    if (dayDiff == 1) return 'Due tomorrow';
    const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Due ${mo[d.month - 1]} ${d.day}';
  }
}

class DashHabit {
  final String id;
  final String title;
  final String frequency; // DAILY | WEEKLY
  final int streak;
  final int weekDone; // COMPLETED logs in the last 7 days
  final bool doneToday;
  final bool skippedToday;

  const DashHabit({
    required this.id,
    required this.title,
    required this.frequency,
    required this.streak,
    required this.weekDone,
    required this.doneToday,
    required this.skippedToday,
  });

  int get target => frequency == 'WEEKLY' ? 1 : 7;
  int get shownDone => weekDone > target ? target : weekDone;
  double get progress => shownDone / target;
}

class DashboardData {
  final String fullName;
  final List<DashTask> tasks;
  final List<DashHabit> habits;
  final int focusMinutesToday;

  /// Focus minutes per hour of day (0-23) over the last 30 days.
  final List<int> focusMinutesByHour;
  final int unreadNotifications;

  const DashboardData({
    required this.fullName,
    required this.tasks,
    required this.habits,
    required this.focusMinutesToday,
    required this.focusMinutesByHour,
    required this.unreadNotifications,
  });

  DashboardData copyWith({List<DashTask>? tasks}) => DashboardData(
        fullName: fullName,
        tasks: tasks ?? this.tasks,
        habits: habits,
        focusMinutesToday: focusMinutesToday,
        focusMinutesByHour: focusMinutesByHour,
        unreadNotifications: unreadNotifications,
      );

  String get firstName {
    final n = fullName.trim();
    return n.isEmpty ? 'there' : n.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  List<DashTask> get _dueToday =>
      tasks.where((t) => t.deadline != null && _isToday(t.deadline!)).toList();

  int get tasksTodayTotal => _dueToday.length;
  int get tasksTodayDone => _dueToday.where((t) => t.isCompleted).length;

  int get bestStreak =>
      habits.isEmpty ? 0 : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

  /// Tasks for "Next up": overdue + today (done or not) + upcoming, by deadline.
  List<DashTask> get nextUp {
    final list = tasks.where((t) {
      if (!t.isCompleted) return true;
      return t.deadline != null && _isToday(t.deadline!);
    }).toList();
    list.sort((a, b) {
      if (a.deadline == null && b.deadline == null) return 0;
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    });
    return list.take(4).toList();
  }

  /// Best 2-hour window for focus, from real session history. Null when no data.
  int? get peakStartHour {
    int? best;
    var bestMin = 0;
    for (var h = 0; h <= 22; h++) {
      final m = focusMinutesByHour[h] + focusMinutesByHour[h + 1];
      if (m > bestMin) {
        bestMin = m;
        best = h;
      }
    }
    return best;
  }

  /// Copy for the "Your day, simplified" card, built from the user's own history.
  String get insightText {
    final s = peakStartHour;
    if (s == null) {
      return 'Complete a few focus sessions and we will show you the hours when you work best.';
    }
    final e = s + 2;
    final String when;
    if (e <= 12) {
      when = 'before noon';
    } else if (s >= 17) {
      when = 'in the evening';
    } else if (s >= 12) {
      when = 'in the afternoon';
    } else {
      when = 'around midday';
    }
    return 'You tend to finish deep work $when. Protect ${_range(s, e)} for your highest-impact task.';
  }

  static String _h12(int h) => '${h % 12 == 0 ? 12 : h % 12}:00';
  static String _ap(int h) => (h % 24) >= 12 ? 'PM' : 'AM';
  static String _range(int s, int e) {
    final sameHalf = _ap(s) == _ap(e) || e == 24 && _ap(s) == 'PM';
    return sameHalf
        ? '${_h12(s)}–${_h12(e)} ${_ap(s)}'
        : '${_h12(s)} ${_ap(s)}–${_h12(e)} ${_ap(e)}';
  }
}

/// Navigation targets. The dashboard never imports other modules' screens;
/// the integrator (main.dart) maps these to real routes.
enum DashboardDestination {
  tasks,
  habits,
  focus,
  aiCoach,
  analytics,
  profile,
  notifications,
}
