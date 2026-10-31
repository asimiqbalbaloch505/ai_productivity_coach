import 'package:supabase_flutter/supabase_flutter.dart';

/// All database access for the Notifications feature stays in this module.
class NotificationHelper {
  final SupabaseClient? _client;
  final bool demoMode;

  NotificationHelper({SupabaseClient? client, this.demoMode = false})
    : _client = demoMode ? null : (client ?? Supabase.instance.client);

  static final List<AppNotification> _demoNotifications = [
    AppNotification(
      id: 'demo-1',
      userId: 'demo-user',
      title: 'Your 9:00 AM planning reminder',
      body: 'Take two minutes to choose your top three.',
      type: 'PLAN',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    AppNotification(
      id: 'demo-2',
      userId: 'demo-user',
      title: 'Habit streak protected',
      body: 'You completed Morning walk for 7 days.',
      type: 'HABIT',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'demo-3',
      userId: 'demo-user',
      title: 'Weekly progress is ready',
      body: 'You focused for 4h 35m last week.',
      type: 'PLAN',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    AppNotification(
      id: 'demo-4',
      userId: 'demo-user',
      title: 'Task overdue',
      body: 'Reply to Jordan is past due.',
      type: 'OVERDUE',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
  static NotificationPreferences _demoPreferences =
      const NotificationPreferences();

  String get _userId {
    final id = _client!.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Please sign in to view your notifications.');
    }
    return id;
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    if (demoMode) return List<AppNotification>.from(_demoNotifications);
    final response = await _client!
        .from('notifications')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(
      response,
    ).map(NotificationModel.fromMap).toList();
  }

  Future<List<NotificationModel>> getNotifications() => fetchNotifications();

  Future<void> sendNotification({
    required String title,
    required String body,
    String type = 'system',
  }) async {
    if (demoMode) {
      _demoNotifications.insert(
        0,
        AppNotification(
          id: 'demo-${DateTime.now().microsecondsSinceEpoch}',
          userId: 'demo-user',
          title: title,
          body: body,
          type: type,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );
      return;
    }

    await _client!.from('notifications').insert({
      'user_id': _userId,
      'title': title,
      'message': body,
      'type': type,
      'is_read': false,
    });
  }

  Future<void> markAsRead(String notificationId) async {
    if (demoMode) {
      final index = _demoNotifications.indexWhere(
        (n) => n.id == notificationId,
      );
      if (index >= 0) {
        _demoNotifications[index] = _demoNotifications[index].copyWith(
          isRead: true,
        );
      }
      return;
    }
    await _client!
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', _userId);
  }

  Future<void> markAllAsRead() async {
    if (demoMode) {
      for (var i = 0; i < _demoNotifications.length; i++) {
        _demoNotifications[i] = _demoNotifications[i].copyWith(isRead: true);
      }
      return;
    }
    await _client!
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _userId)
        .eq('is_read', false);
  }

  Future<NotificationPreferences> getPreferences() async {
    if (demoMode) return _demoPreferences;
    final userId = _userId;
    final record = await _client!
        .from('notification_settings')
        .select(
          'task_reminders, habit_reminders, daily_planning_notif, weekly_summary_notif',
        )
        .eq('user_id', userId)
        .maybeSingle();
    return record == null
        ? const NotificationPreferences()
        : NotificationPreferences.fromJson(record);
  }

  Future<void> savePreferences(NotificationPreferences preferences) async {
    if (demoMode) {
      _demoPreferences = preferences;
      return;
    }
    await _client!.from('notification_settings').upsert({
      'user_id': _userId,
      ...preferences.toJson(),
    }, onConflict: 'user_id');
  }
}

Future<void> sendNotification({
  required String title,
  required String body,
  String type = 'system',
}) =>
    NotificationHelper().sendNotification(title: title, body: body, type: type);

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'REMINDER',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel.fromMap(json);

  String get message => body;

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id,
    userId: userId,
    title: title,
    body: body,
    type: type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}

typedef AppNotification = NotificationModel;

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
