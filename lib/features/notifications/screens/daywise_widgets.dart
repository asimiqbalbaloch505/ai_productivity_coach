import 'package:flutter/material.dart';

class DaywiseStyle {
  static const background = Color(0xFFFDF7EB);
  static const paper = Color(0xFFFFFDF8);
  static const edge = Color(0xFFE8E1D4);
  static const ink = Color(0xFF172535);
  static const muted = Color(0xFF657185);
  static const green = Color(0xFF008049);
  static const sand = Color(0xFFF4EDDF);
}

class DaywiseFrame extends StatelessWidget {
  const DaywiseFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F2F4),
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Container(color: DaywiseStyle.background, child: SafeArea(
        child: Column(children: [Expanded(child: child), const DaywiseBottomBar()]),
      )),
    )),
  );
}

class DaywiseTopBar extends StatelessWidget {
  const DaywiseTopBar({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(17, 15, 15, 14),
    child: Row(children: [
      const Text('daywise', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: DaywiseStyle.ink, letterSpacing: -.4)),
      const Spacer(),
      Container(width: 27, height: 27, alignment: Alignment.center,
        decoration: const BoxDecoration(color: DaywiseStyle.sand, shape: BoxShape.circle),
        child: const Text('AM', style: TextStyle(fontSize: 10, color: DaywiseStyle.muted))),
    ]),
  );
}

class DaywiseBottomBar extends StatelessWidget {
  const DaywiseBottomBar({super.key});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: DaywiseStyle.edge))),
    padding: const EdgeInsets.only(top: 9, bottom: 5),
    child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _NavItem(Icons.calendar_today_outlined, 'Today'),
      _NavItem(Icons.check_box_outlined, 'Tasks'),
      _NavItem(Icons.repeat_rounded, 'Habits'),
      _NavItem(Icons.center_focus_weak_outlined, 'Focus'),
      _NavItem(Icons.auto_awesome_outlined, 'Coach'),
    ]),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem(this.icon, this.caption);
  final IconData icon;
  final String caption;
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 19, color: DaywiseStyle.muted),
    const SizedBox(height: 3),
    Text(caption, style: const TextStyle(fontSize: 10, color: DaywiseStyle.muted)),
  ]);
}

class DaywisePanel extends StatelessWidget {
  const DaywisePanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: DaywiseStyle.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: DaywiseStyle.edge)),
    child: child,
  );
}
