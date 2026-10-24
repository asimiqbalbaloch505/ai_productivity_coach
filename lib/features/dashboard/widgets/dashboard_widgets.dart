import 'package:flutter/material.dart';

import '../dashboard_models.dart';
import '../dashboard_theme.dart';

BoxDecoration _card([double r = DashDims.cardRadius]) => BoxDecoration(
      color: DashColors.surface,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: DashColors.border),
    );

/// Top bar: "daywise" logo, bell with unread dot, initials avatar.
class DashHeader extends StatelessWidget {
  final String initials;
  final bool hasUnread;
  final VoidCallback onBell;
  final VoidCallback onAvatar;
  const DashHeader({
    super.key,
    required this.initials,
    required this.hasUnread,
    required this.onBell,
    required this.onAvatar,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Text('daywise', style: DashText.logo),
          const Spacer(),
          GestureDetector(
            onTap: onBell,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      size: 26, color: DashColors.textDark),
                  if (hasUnread)
                    Positioned(
                      right: 1,
                      top: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                            color: DashColors.primary, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onAvatar,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: DashColors.avatarBg,
              child: Text(initials,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: DashColors.textMuted)),
            ),
          ),
        ],
      );
}

class DateRow extends StatelessWidget {
  final String label;
  final VoidCallback onCalendar;
  const DateRow({super.key, required this.label, required this.onCalendar});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, color: DashColors.textMuted)),
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onCalendar,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DashColors.border),
              ),
              child: const Icon(Icons.calendar_today_outlined,
                  size: 17, color: DashColors.textDark),
            ),
          ),
        ],
      );
}

class InsightCard extends StatelessWidget {
  final String text;
  final VoidCallback onViewPlan;
  const InsightCard({super.key, required this.text, required this.onViewPlan});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: DashColors.lavender,
            borderRadius: BorderRadius.circular(DashDims.bigCardRadius)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 20, color: DashColors.lavenderText),
                SizedBox(width: 10),
                Text('Your day, simplified',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: DashColors.lavenderText)),
              ],
            ),
            const SizedBox(height: 14),
            Text(text, style: DashText.body),
            const SizedBox(height: 16),
            GreenButton(label: 'View my plan', trailing: Icons.arrow_forward, onTap: onViewPlan),
          ],
        ),
      );
}

class GreenButton extends StatelessWidget {
  final String label;
  final IconData? trailing;
  final VoidCallback onTap;
  final bool compact;
  const GreenButton(
      {super.key, required this.label, required this.onTap, this.trailing, this.compact = false});

  @override
  Widget build(BuildContext context) => Material(
        color: DashColors.primary,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 14, vertical: compact ? 11 : 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  Icon(trailing, size: 18, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(title, style: DashText.section)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: DashColors.primary)),
            ),
        ],
      );
}

class GlanceCard extends StatelessWidget {
  final String value;
  final String label;
  final String? highlight;
  const GlanceCard({super.key, required this.value, required this.label, this.highlight});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(14),
          decoration: _card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: DashColors.textDark)),
              const SizedBox(height: 6),
              Text(label, style: DashText.small),
              if (highlight != null) ...[
                const SizedBox(height: 6),
                Text(highlight!,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: DashColors.primary)),
              ],
            ],
          ),
        ),
      );
}

class NextUpCard extends StatelessWidget {
  final List<DashTask> tasks;
  final void Function(DashTask task) onToggle;
  final VoidCallback onTapTask;
  const NextUpCard(
      {super.key, required this.tasks, required this.onToggle, required this.onTapTask});

  @override
  Widget build(BuildContext context) => Container(
        decoration: _card(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < tasks.length; i++) ...[
              if (i > 0) const Divider(height: 1, thickness: 1, color: DashColors.divider),
              _TaskRow(task: tasks[i], onToggle: () => onToggle(tasks[i]), onTap: onTapTask),
            ],
          ],
        ),
      );
}

class _TaskRow extends StatelessWidget {
  final DashTask task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  const _TaskRow({required this.task, required this.onToggle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted;
    final dot = done
        ? DashColors.dotDone
        : task.isOverdue
            ? DashColors.dotOverdue
            : DashColors.dotPending;
    final strike = done ? TextDecoration.lineThrough : null;
    final muted = done ? DashColors.textMuted : DashColors.textDark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 4, top: 2, bottom: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: done ? DashColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: done ? DashColors.primary : DashColors.checkBorder, width: 1.5),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DashText.rowTitle.copyWith(decoration: strike, color: muted)),
                  const SizedBox(height: 2),
                  Text(task.statusLabel,
                      style: DashText.small.copyWith(
                          decoration: strike,
                          color: task.isOverdue ? DashColors.dotOverdue : DashColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoachPromptCard extends StatelessWidget {
  final VoidCallback onAsk;
  const CoachPromptCard({super.key, required this.onAsk});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: _card(),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need help prioritizing?',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: DashColors.textDark)),
                  SizedBox(height: 2),
                  Text('Let Coach build your next step', style: DashText.small),
                ],
              ),
            ),
            GreenButton(label: 'Ask Coach', onTap: onAsk, compact: true),
          ],
        ),
      );
}

class HabitsTodayCard extends StatelessWidget {
  final List<DashHabit> habits;
  const HabitsTodayCard({super.key, required this.habits});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final h in habits)
            Container(
              margin: const EdgeInsets.only(bottom: DashDims.gap + 2),
              padding: const EdgeInsets.all(16),
              decoration: _card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(h.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DashText.rowTitle)),
                      if (h.doneToday) ...[
                        const Icon(Icons.check_circle, size: 16, color: DashColors.primary),
                        const SizedBox(width: 6),
                      ],
                      Text('${h.shownDone} / ${h.target}', style: DashText.small),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: h.progress,
                      minHeight: 6,
                      backgroundColor: DashColors.progressTrack,
                      valueColor: const AlwaysStoppedAnimation(DashColors.primary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}

class DashEmptyCard extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  const DashEmptyCard(
      {super.key, required this.message, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _card(),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center, style: DashText.small),
            const SizedBox(height: 12),
            GreenButton(label: actionLabel, onTap: onAction, compact: true),
          ],
        ),
      );
}

/// Bottom navigation from the design (Today / Tasks / Habits / Focus / Coach).
/// If the app shell already provides this bar, pass showBottomNav: false.
class DashboardBottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const DashboardBottomNav({super.key, required this.current, required this.onTap});

  static const _items = [
    (Icons.calendar_today_outlined, 'Today'),
    (Icons.check_box_outlined, 'Tasks'),
    (Icons.repeat_rounded, 'Habits'),
    (Icons.filter_center_focus_rounded, 'Focus'),
    (Icons.auto_awesome_outlined, 'Coach'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: DashColors.background,
          border: Border(top: BorderSide(color: DashColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_items.length, (i) {
                final active = i == current;
                final color = active ? DashColors.primary : DashColors.textMuted;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 78,
                        height: 52,
                        decoration: BoxDecoration(
                          color: active ? DashColors.navPill : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_items[i].$1, size: 22, color: color),
                            const SizedBox(height: 3),
                            Text(_items[i].$2,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                    color: color)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      );
}

class DashboardErrorView extends StatelessWidget {
  final String message;
  final bool isOffline;
  final VoidCallback onRetry;
  const DashboardErrorView(
      {super.key, required this.message, required this.isOffline, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                  size: 48, color: DashColors.textMuted),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: DashColors.textDark)),
              const SizedBox(height: 16),
              GreenButton(label: 'Try again', onTap: onRetry, compact: true),
            ],
          ),
        ),
      );
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  Widget _box(double h, {double r = DashDims.cardRadius}) => Container(
        height: h,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: DashColors.progressTrack, borderRadius: BorderRadius.circular(r)),
      );

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DashDims.pagePad),
        children: [
          _box(36),
          _box(70),
          _box(170, r: DashDims.bigCardRadius),
          _box(96),
          _box(200),
        ],
      );
}
