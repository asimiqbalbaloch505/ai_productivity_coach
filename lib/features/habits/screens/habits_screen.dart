// lib/features/habits/screens/habits_screen.dart
// "Habits" (daywise Screen 3): momentum card, daily + weekly habit lists,
// check-ins (complete / skip / undo) and streak counters.

import 'package:flutter/material.dart';

import '../habit_models.dart';
import '../habit_styles.dart';
import '../habits_db_helper.dart';
import 'add_habit_screen.dart';

enum _DayState { full, partial, none }

class HabitsScreen extends StatefulWidget {
  /// Optional hooks so the integrator (main.dart) can wire the header icons
  /// to the notifications / profile screens without this module importing
  /// other teams' folders.
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const HabitsScreen({
    super.key,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _db = HabitsDBHelper();

  List<Habit> _habits = [];

  /// habitId -> (date -> log) for the last 14 days.
  final Map<String, Map<DateTime, HabitLog>> _logs = {};
  final Set<String> _busyIds = {};

  bool _loading = true;
  String? _error;
  String _initials = 'U';
  bool _lastWeek = false; // "This week" / "Last week" selector

  @override
  void initState() {
    super.initState();
    _load();
  }

  // -------------------------------------------------------------------- data

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _loading = true);
    try {
      final habits = await _db.getHabits();
      final today = dateOnly(DateTime.now());
      final logs = await _db.getLogsSince(
        habits.map((h) => h.id).toList(),
        addDays(today, -13),
      );

      final grouped = <String, Map<DateTime, HabitLog>>{};
      for (final log in logs) {
        grouped.putIfAbsent(log.habitId, () => {})[log.completedAt] = log;
      }

      String? name;
      try {
        name = await _db.getProfileName();
      } catch (_) {
        name = null; // initials are cosmetic – never fail the screen for them
      }

      if (!mounted) return;
      setState(() {
        _habits = habits;
        _logs
          ..clear()
          ..addAll(grouped);
        _initials = _initialsOf(name);
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _initialsOf(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  // ----------------------------------------------------------------- derived

  DateTime get _today => dateOnly(DateTime.now());

  List<Habit> get _dailyHabits =>
      _habits.where((h) => h.frequency == HabitFrequency.daily).toList();

  List<Habit> get _weeklyHabits =>
      _habits.where((h) => h.frequency == HabitFrequency.weekly).toList();

  HabitLog? _todayLog(Habit habit) => _logs[habit.id]?[_today];

  bool _completedOn(Habit habit, DateTime day) =>
      _logs[habit.id]?[day]?.status == HabitLogStatus.completed;

  int _daysDoneThisWeek(Habit habit) {
    final weekStart = startOfWeek(_today);
    final byDay = _logs[habit.id];
    if (byDay == null) return 0;
    return byDay.entries
        .where((e) =>
    !e.key.isBefore(weekStart) &&
        !e.key.isAfter(_today) &&
        e.value.status == HabitLogStatus.completed)
        .length;
  }

  /// The 7 days shown in the momentum card (ending today, or 7 days earlier
  /// for "Last week").
  List<DateTime> get _windowDays {
    final end = addDays(_today, _lastWeek ? -7 : 0);
    return [for (var i = 6; i >= 0; i--) addDays(end, -i)];
  }

  int get _completionPercent {
    final days = _windowDays;
    final daily = _dailyHabits;
    final weekly = _weeklyHabits;
    final total = daily.length * 7 + weekly.length;
    if (total == 0) return 0;

    var done = 0;
    for (final habit in daily) {
      for (final day in days) {
        if (_completedOn(habit, day)) done++;
      }
    }
    for (final habit in weekly) {
      if (days.any((day) => _completedOn(habit, day))) done++;
    }
    return (done * 100 / total).round();
  }

  _DayState _dayState(DateTime day) {
    final daily = _dailyHabits;
    final pool = daily.isNotEmpty ? daily : _habits;
    if (pool.isEmpty) return _DayState.none;
    final done = pool.where((h) => _completedOn(h, day)).length;
    if (done == pool.length) return _DayState.full;
    if (done > 0) return _DayState.partial;
    return _DayState.none;
  }

  // ----------------------------------------------------------------- actions

  Future<void> _run(
      Habit habit,
      Future<int> Function() action, {
        String? message,
      }) async {
    setState(() => _busyIds.add(habit.id));
    try {
      await action();
      await _load(showSpinner: false);
      if (message != null) _snack(message);
    } catch (e) {
      _snack('Something went wrong: $e', error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(habit.id));
    }
  }

  Future<void> _toggleComplete(Habit habit) {
    final isDone = _todayLog(habit)?.status == HabitLogStatus.completed;
    if (isDone) {
      return _run(habit, () => _db.clearLog(habit));
    }
    return _run(
      habit,
          () => _db.setLog(habit, HabitLogStatus.completed),
      message: 'Nice! "${habit.title}" completed',
    );
  }

  Future<void> _showActions(Habit habit) async {
    final hasLog = _todayLog(habit) != null;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: HabitColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  habit.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: HabitColors.textDark,
                  ),
                ),
              ),
            ),
            _actionTile(ctx, Icons.check_circle_outline_rounded,
                'Mark as completed', 'complete'),
            _actionTile(
                ctx, Icons.skip_next_rounded, 'Skip for today', 'skip'),
            if (hasLog)
              _actionTile(ctx, Icons.undo_rounded, "Clear today's check-in",
                  'clear'),
            _actionTile(ctx, Icons.edit_outlined, 'Edit habit', 'edit'),
            _actionTile(ctx, Icons.delete_outline_rounded, 'Delete habit',
                'delete',
                color: HabitColors.danger),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    switch (action) {
      case 'complete':
        await _run(
          habit,
              () => _db.setLog(habit, HabitLogStatus.completed),
          message: 'Nice! "${habit.title}" completed',
        );
      case 'skip':
        await _run(
          habit,
              () => _db.setLog(habit, HabitLogStatus.skipped),
          message: '"${habit.title}" skipped for today',
        );
      case 'clear':
        await _run(habit, () => _db.clearLog(habit));
      case 'edit':
        await _openForm(habit: habit);
      case 'delete':
        await _delete(habit);
    }
  }

  Widget _actionTile(
      BuildContext ctx,
      IconData icon,
      String label,
      String value, {
        Color color = HabitColors.textDark,
      }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: () => Navigator.of(ctx).pop(value),
    );
  }

  Future<void> _delete(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HabitColors.card,
        title: const Text('Delete habit?'),
        content: Text(
          '"${habit.title}" and all of its check-ins will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: HabitColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _db.deleteHabit(habit.id);
      await _load(showSpinner: false);
      _snack('Habit deleted');
    } catch (e) {
      _snack('Could not delete habit: $e', error: true);
    }
  }

  Future<void> _openForm({Habit? habit}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddHabitScreen(habit: habit)),
    );
    if (saved == true) await _load(showSpinner: false);
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? HabitColors.danger : HabitColors.textDark,
        ),
      );
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: HabitColors.primary,
          onRefresh: () => _load(showSpinner: false),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator(color: HabitColors.primary)),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(HabitStyles.screenPadding),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.cloud_off_rounded,
              size: 52, color: HabitColors.textMuted),
          const SizedBox(height: 12),
          const Text(
            'Could not load your habits',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: HabitColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: HabitColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: HabitColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    final daily = _dailyHabits;
    final weekly = _weeklyHabits;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        HabitStyles.screenPadding,
        14,
        HabitStyles.screenPadding,
        24,
      ),
      children: [
        _buildTopBar(),
        const SizedBox(height: 18),
        _buildTitleRow(),
        const SizedBox(height: 16),
        _buildMomentumCard(),
        if (_habits.isEmpty) ...[
          const SizedBox(height: 28),
          _buildEmptyState(),
        ],
        if (daily.isNotEmpty) ...[
          const SizedBox(height: 22),
          _buildSectionHeader('Daily habits', showMenu: true),
          const SizedBox(height: 8),
          for (final habit in daily) _buildCard(habit),
        ],
        if (weekly.isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildSectionHeader('Weekly habits'),
          const SizedBox(height: 8),
          for (final habit in weekly) _buildCard(habit),
        ],
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: () => _openForm(),
            style: OutlinedButton.styleFrom(
              foregroundColor: HabitColors.primary,
              side: const BorderSide(color: HabitColors.primary),
              backgroundColor: HabitColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 18),
                SizedBox(width: 6),
                Text(
                  'New habit',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const Text(
          'daywise',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: HabitColors.primary,
            letterSpacing: -0.4,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: widget.onNotificationsTap,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_none_rounded,
                    size: 22, color: HabitColors.textDark),
                Positioned(
                  top: 4,
                  right: 6,
                  child: CircleAvatar(
                    radius: 3.5,
                    backgroundColor: HabitColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: widget.onProfileTap,
          child: CircleAvatar(
            radius: 15,
            backgroundColor: HabitColors.momentumCard,
            child: Text(
              _initials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: HabitColors.textDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        const Text(
          'Habits',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: HabitColors.textDark,
          ),
        ),
        const SizedBox(width: 12),
        PopupMenuButton<bool>(
          onSelected: (lastWeek) => setState(() => _lastWeek = lastWeek),
          color: HabitColors.card,
          itemBuilder: (_) => const [
            PopupMenuItem(value: false, child: Text('This week')),
            PopupMenuItem(value: true, child: Text('Last week')),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _lastWeek ? 'Last week' : 'This week',
                style: const TextStyle(
                  fontSize: 13,
                  color: HabitColors.textMuted,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: HabitColors.textMuted),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _openForm(),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: HabitColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildMomentumCard() {
    final percent = _completionPercent;
    final days = _windowDays;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HabitColors.momentumCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  percent >= 50
                      ? "You're building momentum"
                      : 'Keep it going',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: HabitColors.primaryDark,
                  ),
                ),
              ),
              const Icon(Icons.trending_up_rounded,
                  size: 20, color: HabitColors.primary),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$percent% completion ${_lastWeek ? 'last week' : 'this week'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: HabitColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in days)
                Column(
                  children: [
                    _dayDot(_dayState(day)),
                    const SizedBox(height: 6),
                    Text(
                      kWeekdayShort[day.weekday - 1],
                      style: const TextStyle(
                        fontSize: 11,
                        color: HabitColors.textMuted,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayDot(_DayState state) {
    final Color fill;
    final Color border;
    switch (state) {
      case _DayState.full:
        fill = HabitColors.primary;
        border = HabitColors.primary;
      case _DayState.partial:
        fill = HabitColors.amber;
        border = HabitColors.amber;
      case _DayState.none:
        fill = HabitColors.background;
        border = HabitColors.track;
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showMenu = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: HabitColors.textDark,
            ),
          ),
        ),
        if (showMenu)
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            color: HabitColors.card,
            icon: const Icon(Icons.more_horiz_rounded,
                color: HabitColors.textMuted),
            onSelected: (value) {
              if (value == 'new') _openForm();
              if (value == 'refresh') _load();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'new', child: Text('New habit')),
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            ],
          ),
      ],
    );
  }

  Widget _buildCard(Habit habit) {
    final isWeekly = habit.frequency == HabitFrequency.weekly;
    final log = _todayLog(habit);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _HabitCard(
        title: habit.title,
        subtitle: isWeekly
            ? '${_daysDoneThisWeek(habit)} of 7 days · '
            '${habit.streakCount} ${habit.frequency.unit} streak'
            : '${habit.streakCount} ${habit.frequency.unit} streak',
        status: log?.status,
        isWeekly: isWeekly,
        daysDone: isWeekly ? _daysDoneThisWeek(habit) : 0,
        busy: _busyIds.contains(habit.id),
        onToggle: () => _toggleComplete(habit),
        onTap: () => _showActions(habit),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: HabitStyles.cardDecoration(radius: 14),
      child: const Column(
        children: [
          Icon(Icons.sync_rounded, size: 40, color: HabitColors.primary),
          SizedBox(height: 12),
          Text(
            'No habits yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: HabitColors.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap "New habit" to build your first one.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: HabitColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Habit card
// ---------------------------------------------------------------------------

class _HabitCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final HabitLogStatus? status; // today's log, null = not logged
  final bool isWeekly;
  final int daysDone;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _HabitCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.isWeekly,
    required this.daysDone,
    required this.busy,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: HabitStyles.cardDecoration(radius: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: HabitColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: HabitColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _trailing(),
              ],
            ),
            const SizedBox(height: 10),
            if (isWeekly)
              _SegmentBar(total: 7, filled: daysDone.clamp(0, 7))
            else
              _statusText(),
          ],
        ),
      ),
    );
  }

  Widget _trailing() {
    if (busy) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: Padding(
          padding: EdgeInsets.all(2),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: HabitColors.primary,
          ),
        ),
      );
    }
    final IconData icon;
    final Color color;
    switch (status) {
      case HabitLogStatus.completed:
        icon = Icons.check_circle_rounded;
        color = HabitColors.primary;
      case HabitLogStatus.skipped:
        icon = Icons.remove_circle_outline_rounded;
        color = HabitColors.amber;
      case null:
        icon = Icons.check_circle_outline_rounded;
        color = HabitColors.textMuted;
    }
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Icon(icon, size: 24, color: color),
      ),
    );
  }

  Widget _statusText() {
    final String text;
    final Color color;
    final FontWeight weight;
    switch (status) {
      case HabitLogStatus.completed:
        text = 'Completed today';
        color = HabitColors.primary;
        weight = FontWeight.w600;
      case HabitLogStatus.skipped:
        text = 'Skipped today';
        color = HabitColors.amber;
        weight = FontWeight.w600;
      case null:
        text = 'Not completed';
        color = HabitColors.textMuted;
        weight = FontWeight.w400;
    }
    return Text(
      text,
      style: TextStyle(fontSize: 12.5, fontWeight: weight, color: color),
    );
  }
}

class _SegmentBar extends StatelessWidget {
  final int total;
  final int filled;

  const _SegmentBar({required this.total, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i < filled ? HabitColors.primary : HabitColors.track,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}