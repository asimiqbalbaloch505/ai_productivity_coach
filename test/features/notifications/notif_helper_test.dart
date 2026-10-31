import 'package:flutter_test/flutter_test.dart';

import 'package:ai_productivity_coach/features/notifications/notif_helper.dart';

void main() {
  group('NotificationModel', () {
    test('maps the notifications table schema', () {
      final notification = NotificationModel.fromMap({
        'id': 'notification-1',
        'user_id': 'user-1',
        'title': 'A reminder',
        'body': 'Body value.',
        'message': 'Review today priorities.',
        'type': 'system',
        'is_read': false,
        'created_at': '2026-10-31T08:30:00.000Z',
      });

      expect(notification.id, 'notification-1');
      expect(notification.userId, 'user-1');
      expect(notification.title, 'A reminder');
      expect(notification.body, 'Body value.');
      expect(notification.type, 'system');
      expect(notification.isRead, isFalse);
      expect(notification.createdAt, isNotNull);
    });

    test('falls back to message when body is absent', () {
      final notification = NotificationModel.fromMap({
        'id': 'notification-2',
        'user_id': 'user-1',
        'title': 'Legacy notification',
        'message': 'Legacy message.',
        'type': 'system',
        'is_read': true,
        'created_at': '2026-10-31T08:30:00.000Z',
      });

      expect(notification.body, 'Legacy message.');
    });
  });

  test('demo helper can dispatch and mark notifications as read', () async {
    final helper = NotificationHelper(demoMode: true);

    await helper.sendNotification(
      title: 'Dispatch test',
      body: 'A new notification.',
    );

    final dispatched = (await helper.fetchNotifications()).first;
    expect(dispatched.title, 'Dispatch test');
    expect(dispatched.body, 'A new notification.');
    expect(dispatched.type, 'system');
    expect(dispatched.isRead, isFalse);

    await helper.markAllAsRead();

    expect(
      (await helper.fetchNotifications()).every(
        (notification) => notification.isRead,
      ),
      isTrue,
    );
  });
}
