import 'package:flutter_test/flutter_test.dart';

import 'package:ai_productivity_coach/features/dashboard/dashboard_models.dart';

void main() {
  test('dashboard derives user summary from loaded records', () {
    final today = DateTime.now();
    final data = DashboardData(
      fullName: 'Mujawwad Khan',
      tasks: [
        DashTask(
          id: 'task-1',
          title: 'Finish dashboard',
          priority: 'HIGH',
          deadline: today,
          isCompleted: true,
        ),
      ],
      habits: const [
        DashHabit(
          id: 'habit-1',
          title: 'Read',
          frequency: 'DAILY',
          streak: 4,
          weekDone: 3,
          doneToday: true,
          skippedToday: false,
        ),
      ],
      focusMinutesToday: 45,
      focusMinutesByHour: [
        30,
        20,
        ...List.filled(22, 0),
      ],
      unreadNotifications: 1,
    );

    expect(data.firstName, 'Mujawwad');
    expect(data.initials, 'MK');
    expect(data.tasksTodayTotal, 1);
    expect(data.tasksTodayDone, 1);
    expect(data.bestStreak, 4);
    expect(data.nextUp, hasLength(1));
    expect(data.insightText, contains('finish deep work'));
  });
}
