import 'package:flutter/material.dart';

import '../../auth/screens/login_screen.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../dashboard_db_helper.dart';
import '../dashboard_models.dart';
import '../dashboard_theme.dart';
import '../widgets/dashboard_widgets.dart';

/// "Today" screen of the daywise design.
///
/// Navigation is delegated through [onNavigate] so this module never imports
/// another member's folder; the lead maps each destination to a route.
class DashboardScreen extends StatefulWidget {
  final void Function(DashboardDestination destination)? onNavigate;

  /// Optional: test with a seeded user before Auth is integrated.
  final String? testUserId;

  /// The app shell (main.dart) already renders the bottom bar, so this is off by
  /// default. Set true only when running this screen on its own.
  final bool showBottomNav;

  const DashboardScreen({
    super.key,
    this.onNavigate,
    this.testUserId,
    this.showBottomNav = false,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardDBHelper _db = DashboardDBHelper(
    overrideUserId: widget.testUserId,
  );

  DashboardData? _data;
  DashboardException? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _loading = true);
    try {
      final d = await _db.fetchDashboard();
      if (!mounted) return;
      setState(() {
        _data = d;
        _error = null;
        _loading = false;
      });
    } on DashboardException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _go(DashboardDestination d) => widget.onNavigate?.call(d);

  void _openNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationScreen()));
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _retry() {
    if (_error?.message == 'You are signed out. Log in to see your day.') {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    _load();
  }

  Future<void> _toggleTask(DashTask task) async {
    final data = _data;
    if (data == null) return;
    final next = !task.isCompleted;
    List<DashTask> swap(bool completed) => [
      for (final t in data.tasks)
        t.id == task.id ? t.copyWith(isCompleted: completed) : t,
    ];
    setState(() => _data = data.copyWith(tasks: swap(next))); // optimistic
    try {
      await _db.setTaskCompleted(task.id, next);
    } on DashboardException catch (e) {
      if (!mounted) return;
      setState(() => _data = _data?.copyWith(tasks: swap(!next)));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't update the task. ${e.message}")),
      );
    }
  }

  void _onNavTap(int i) {
    switch (i) {
      case 1:
        _go(DashboardDestination.tasks);
      case 2:
        _go(DashboardDestination.habits);
      case 3:
        _go(DashboardDestination.focus);
      case 4:
        _go(DashboardDestination.aiCoach);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _dateLabel {
    const wd = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const mo = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final n = DateTime.now();
    return '${wd[n.weekday - 1]}, ${mo[n.month - 1]} ${n.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashColors.background,
      bottomNavigationBar: widget.showBottomNav
          ? DashboardBottomNav(current: 0, onTap: _onNavTap)
          : null,
      body: SafeArea(
        bottom: false,
        child: _loading && _data == null
            ? const DashboardSkeleton()
            : (_error != null && _data == null)
            ? DashboardErrorView(
                message: _error!.message,
                isOffline: _error!.isOffline,
                onRetry: _retry,
              )
            : RefreshIndicator(
                color: DashColors.primary,
                onRefresh: () => _load(showSpinner: false),
                child: _content(_data!),
              ),
      ),
    );
  }

  Widget _content(DashboardData d) {
    final nextUp = d.nextUp;
    final habits = d.habits.take(3).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        DashDims.pagePad,
        8,
        DashDims.pagePad,
        24,
      ),
      children: [
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DashColors.lavender,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Showing your last loaded data. ${_error!.message}',
              style: const TextStyle(
                fontSize: 13,
                color: DashColors.lavenderText,
              ),
            ),
          ),
        DashHeader(
          initials: d.initials,
          hasUnread: d.unreadNotifications > 0,
          onBell: _openNotifications,
          onAvatar: _openProfile,
        ),
        const SizedBox(height: 14),
        DateRow(
          label: _dateLabel,
          onCalendar: () => _go(DashboardDestination.tasks),
        ),
        const SizedBox(height: 22),
        Text('$_greeting, ${d.firstName}', style: DashText.greeting),
        const SizedBox(height: 6),
        const Text(
          'A focused day starts with one clear next step.',
          style: DashText.subtitle,
        ),
        const SizedBox(height: 22),
        InsightCard(
          text: d.insightText,
          onViewPlan: () => _go(DashboardDestination.aiCoach),
        ),
        const SizedBox(height: 28),
        const SectionTitle('Today at a glance'),
        const SizedBox(height: 12),
        Row(
          children: [
            GlanceCard(
              value: '${d.tasksTodayDone} / ${d.tasksTodayTotal}',
              label: 'tasks',
              highlight: 'completed',
            ),
            const SizedBox(width: DashDims.gap),
            GlanceCard(
              value: '${d.bestStreak} day',
              label: 'streak',
              highlight: 'best this week',
            ),
            const SizedBox(width: DashDims.gap),
            GlanceCard(value: '${d.focusMinutesToday} min', label: 'focused'),
          ],
        ),
        const SizedBox(height: 28),
        const SectionTitle('Next up'),
        const SizedBox(height: 12),
        if (nextUp.isEmpty)
          DashEmptyCard(
            message: 'Nothing planned yet. Add a task to shape your day.',
            actionLabel: 'Open tasks',
            onAction: () => _go(DashboardDestination.tasks),
          )
        else
          NextUpCard(
            tasks: nextUp,
            onToggle: _toggleTask,
            onTapTask: () => _go(DashboardDestination.tasks),
          ),
        const SizedBox(height: 12),
        CoachPromptCard(onAsk: () => _go(DashboardDestination.aiCoach)),
        const SizedBox(height: 28),
        SectionTitle(
          'Habits today',
          action: 'See all',
          onAction: () => _go(DashboardDestination.habits),
        ),
        const SizedBox(height: 12),
        if (habits.isEmpty)
          DashEmptyCard(
            message: 'No habits yet. Start with one small daily habit.',
            actionLabel: 'Open habits',
            onAction: () => _go(DashboardDestination.habits),
          )
        else
          HabitsTodayCard(habits: habits),
      ],
    );
  }
}
