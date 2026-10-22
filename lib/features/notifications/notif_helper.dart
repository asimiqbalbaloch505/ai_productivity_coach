import 'package:supabase_flutter/supabase_flutter.dart';

/// All database access for the Notifications feature stays in this module.
class NotificationHelper {
  final SupabaseClient? _client;
  final bool demoMode;

  NotificationHelper({SupabaseClient? client, this.demoMode = false})
      : _client = demoMode ? null : (client ?? Supabase.instance.client);

  static final List<AppNotification> _demoNotifications = [
    AppNotification(id: 'demo-1', title: 'Your 9:00 AM planning reminder',
      message: 'Take two minutes to choose your top three.',
      type: 'PLAN', isRead: false, createdAt: DateTime.now().subtract(const Duration(minutes: 12))),
    AppNotification(id: 'demo-2', title: 'Habit streak protected',
      message: 'You completed Morning walk for 7 days.',
      type: 'HABIT', isRead: false, createdAt: DateTime.now().subtract(const Duration(hours: 2))),
    AppNotification(id: 'demo-3', title: 'Weekly progress is ready',
      message: 'You focused for 4h 35m last week.',
      type: 'PLAN', isRead: true, createdAt: DateTime.now().subtract(const Duration(hours: 5))),
    AppNotification(id: 'demo-4', title: 'Task overdue',
      message: 'Reply to Jordan is past due.',
      type: 'OVERDUE', isRead: true, createdAt: DateTime.now().subtract(const Duration(days: 2))),
  ];
  static NotificationPreferences _demoPreferences = const NotificationPreferences();

  String get _userId {
    final id = _client!.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Please sign in to view your notifications.');
    }
    return id;
  }

  Future<List<AppNotification>> getNotifications() async {
    if (demoMode) return List<AppNotification>.from(_demoNotifications);
    final response = await _client!
        .from('notifications')
        .select('id, user_id, title, message, type, is_read, created_at')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((value) => AppNotification.fromJson(Map<String, dynamic>.from(value)))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    if (demoMode) {
      final index = _demoNotifications.indexWhere((n) => n.id == notificationId);
      if (index >= 0) _demoNotifications[index] = _demoNotifications[index].copyWith(isRead: true);
      return;
    }
    await _client!.from('notifications').update({'is_read': true})
        .eq('id', notificationId).eq('user_id', _userId);
  }

  Future<void> markAllAsRead() async {
    if (demoMode) {
      for (var i = 0; i < _demoNotifications.length; i++) {
        _demoNotifications[i] = _demoNotifications[i].copyWith(isRead: true);
      }
      return;
    }
    await _client!.from('notifications').update({'is_read': true})
        .eq('user_id', _userId).eq('is_read', false);
  }

  Future<NotificationPreferences> getPreferences() async {
    if (demoMode) return _demoPreferences;
    final userId = _userId;
    final record = await _client!.from('notification_settings')
        .select('task_reminders, habit_reminders, daily_planning_notif, weekly_summary_notif')
        .eq('user_id', userId).maybeSingle();
    return record == null
        ? const NotificationPreferences()
        : NotificationPreferences.fromJson(record);
  }

  Future<void> savePreferences(NotificationPreferences preferences) async {
    if (demoMode) { _demoPreferences = preferences; return; }
    await _client!.from('notification_settings').upsert({
      'user_id': _userId,
      ...preferences.toJson(),
    }, onConflict: 'user_id');
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'REMINDER',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal(),
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        message: message,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

class NotificationPreferences {
  final bool taskReminders;
  final bool habitReminders;
  final bool dailyPlanning;
  final bool weeklySummary;

  const NotificationPreferences({
    this.taskReminders = true,
    this.habitReminders = true,
    this.dailyPlanning = true,
    this.weeklySummary = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      taskReminders: json['task_reminders'] as bool? ?? true,
      habitReminders: json['habit_reminders'] as bool? ?? true,
      dailyPlanning: json['daily_planning_notif'] as bool? ?? true,
      weeklySummary: json['weekly_summary_notif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'task_reminders': taskReminders,
        'habit_reminders': habitReminders,
        'daily_planning_notif': dailyPlanning,
        'weekly_summary_notif': weeklySummary,
      };

  NotificationPreferences copyWith({
    bool? taskReminders,
    bool? habitReminders,
    bool? dailyPlanning,
    bool? weeklySummary,
  }) => NotificationPreferences(
        taskReminders: taskReminders ?? this.taskReminders,
        habitReminders: habitReminders ?? this.habitReminders,
        dailyPlanning: dailyPlanning ?? this.dailyPlanning,
        weeklySummary: weeklySummary ?? this.weeklySummary,
      );
}
