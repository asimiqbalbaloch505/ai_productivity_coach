import 'package:flutter/material.dart';
import '../notif_helper.dart';
import 'daywise_widgets.dart';

class NotificationsSettingScreen extends StatefulWidget {
  const NotificationsSettingScreen({super.key, this.demoMode = false});
  final bool demoMode;
  @override
  State<NotificationsSettingScreen> createState() => _NotificationsSettingScreenState();
}

class _NotificationsSettingScreenState extends State<NotificationsSettingScreen> {
  late final NotificationHelper helper;
  NotificationPreferences preferences = const NotificationPreferences();
  bool master = true;
  bool overdue = false;
  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    helper = NotificationHelper(demoMode: widget.demoMode);
    load();
  }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final result = await helper.getPreferences();
      if (mounted) setState(() => preferences = result);
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> update(NotificationPreferences next) async {
    if (saving) return;
    final before = preferences;
    setState(() { preferences = next; saving = true; });
    try { await helper.savePreferences(next); }
    catch (e) {
      if (mounted) {
        setState(() => preferences = before);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to save: $e')));
      }
    } finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) => DaywiseFrame(child: Column(children: [
    const DaywiseTopBar(),
    Padding(padding: const EdgeInsets.fromLTRB(16, 5, 16, 18), child: Row(children: [
      const Expanded(child: Text('Notification settings', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -.6, color: DaywiseStyle.ink))),
      TextButton(onPressed: () => Navigator.maybePop(context), style: TextButton.styleFrom(foregroundColor: DaywiseStyle.green, padding: EdgeInsets.zero), child: const Text('Done', style: TextStyle(fontSize: 12))),
    ])),
    Expanded(child: loading ? const Center(child: CircularProgressIndicator(color: DaywiseStyle.green))
      : error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Could not load settings:\n$error', textAlign: TextAlign.center), TextButton(onPressed: load, child: const Text('Retry'))]))
      : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 20), children: [
        DaywisePanel(child: _ToggleRow(title: 'Notifications', subtitle: 'Stay gently on track', value: master, onChanged: (v) => setState(() => master = v))),
        const SizedBox(height: 28),
        const _Heading('Planning'),
        DaywisePanel(child: Column(children: [
          _ToggleRow(title: 'Daily planning reminder', subtitle: '8:30 AM', value: preferences.dailyPlanning && master, onChanged: !master || saving ? null : (v) => update(preferences.copyWith(dailyPlanning: v))),
          const Divider(height: 1, color: DaywiseStyle.edge),
          _ToggleRow(title: 'Weekly review', subtitle: 'Sunday, 6:00 PM', value: preferences.weeklySummary && master, onChanged: !master || saving ? null : (v) => update(preferences.copyWith(weeklySummary: v))),
        ])),
        const SizedBox(height: 28),
        const _Heading('Tasks & habits'),
        DaywisePanel(child: Column(children: [
          _ToggleRow(title: 'Task deadlines', value: preferences.taskReminders && master, onChanged: !master || saving ? null : (v) => update(preferences.copyWith(taskReminders: v))),
          const Divider(height: 1, color: DaywiseStyle.edge),
          _ToggleRow(title: 'Habit reminders', value: preferences.habitReminders && master, onChanged: !master || saving ? null : (v) => update(preferences.copyWith(habitReminders: v))),
          const Divider(height: 1, color: DaywiseStyle.edge),
          _ToggleRow(title: 'Overdue tasks', value: overdue && master, onChanged: !master ? null : (v) => setState(() => overdue = v)),
        ])),
        const SizedBox(height: 25),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: DaywiseStyle.sand, borderRadius: BorderRadius.circular(12), border: Border.all(color: DaywiseStyle.edge)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.notifications_none, size: 18, color: DaywiseStyle.muted), const SizedBox(width: 10), Expanded(child: Text(master ? 'Notifications are enabled for daywise' : 'Notifications are paused for daywise', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: DaywiseStyle.ink)))]),
            const SizedBox(height: 12),
            Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFF8F2E7), borderRadius: BorderRadius.circular(8)),
              child: const Text('Open phone settings', style: TextStyle(fontSize: 11.5, color: DaywiseStyle.ink)))),
          ])),
        const SizedBox(height: 12),
        const Text('Master and overdue toggles are preview-only until the database schema is extended. System notification settings require platform integration.', style: TextStyle(fontSize: 10, height: 1.4, color: DaywiseStyle.muted)),
      ])),
  ]));
}

class _Heading extends StatelessWidget {
  const _Heading(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(1, 0, 0, 11), child: Text(title, style: const TextStyle(color: DaywiseStyle.muted, fontWeight: FontWeight.w600, fontSize: 11.5)));
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.title, this.subtitle, required this.value, this.onChanged});
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(13, 11, 11, 11), child: Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 12.5, color: DaywiseStyle.ink, fontWeight: FontWeight.w500)),
      if (subtitle != null) ...[const SizedBox(height: 5), Text(subtitle!, style: const TextStyle(fontSize: 11, color: DaywiseStyle.muted))],
    ])),
    const SizedBox(width: 6),
    SizedBox(width: 39, height: 27, child: FittedBox(fit: BoxFit.contain, child: Switch.adaptive(
      activeTrackColor: DaywiseStyle.green, activeThumbColor: Colors.white,
      inactiveTrackColor: DaywiseStyle.sand, inactiveThumbColor: Colors.white,
      value: value, onChanged: onChanged,
    ))),
  ]));
}
