import 'package:flutter/material.dart';
import '../notif_helper.dart';
import 'daywise_widgets.dart';
import 'notifications_setting_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, this.demoMode = false});
  final bool demoMode;
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationHelper helper;
  List<AppNotification> notifications = [];
  bool loading = true;
  bool unreadOnly = false;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    helper = NotificationHelper(demoMode: widget.demoMode);
    refresh();
  }

  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try {
      final result = await helper.getNotifications();
      if (mounted) setState(() => notifications = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void feedback(Object e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }

  Future<void> markRead(AppNotification n) async {
    if (busy || n.isRead) return;
    setState(() => busy = true);
    try {
      await helper.markAsRead(n.id);
      if (mounted) setState(() => notifications = notifications.map((x) => x.id == n.id ? x.copyWith(isRead: true) : x).toList());
    } catch (e) { feedback(e); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> markAll() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await helper.markAllAsRead();
      if (mounted) setState(() => notifications = notifications.map((x) => x.copyWith(isRead: true)).toList());
    } catch (e) { feedback(e); }
    finally { if (mounted) setState(() => busy = false); }
  }

  String timeFor(DateTime? d) {
    if (d == null) return '';
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$hour:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  bool isToday(DateTime? d) {
    if (d == null) return false;
    final n = DateTime.now();
    return n.year == d.year && n.month == d.month && n.day == d.day;
  }

  @override
  Widget build(BuildContext context) {
    final shown = notifications.where((x) => !unreadOnly || !x.isRead).toList();
    final today = shown.where((x) => isToday(x.createdAt)).toList();
    final previous = shown.where((x) => !isToday(x.createdAt)).toList();
    return DaywiseFrame(child: Column(children: [
      const DaywiseTopBar(),
      Padding(padding: const EdgeInsets.fromLTRB(16, 5, 16, 16), child: Row(children: [
        const Expanded(child: Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -.5, color: DaywiseStyle.ink))),
        TextButton(onPressed: loading || busy || !notifications.any((x) => !x.isRead) ? null : markAll,
          style: TextButton.styleFrom(foregroundColor: DaywiseStyle.green, padding: EdgeInsets.zero),
          child: const Text('Mark all read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
      ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(
        height: 31, decoration: BoxDecoration(color: DaywiseStyle.sand, borderRadius: BorderRadius.circular(13)),
        child: Row(children: [for (final filter in [false, true]) Expanded(child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => setState(() => unreadOnly = filter),
          child: Container(alignment: Alignment.center, decoration: BoxDecoration(
            color: unreadOnly == filter ? const Color(0xFFEDE3D3) : Colors.transparent,
            borderRadius: BorderRadius.circular(13)),
            child: Text(filter ? 'Unread' : 'All', style: const TextStyle(fontSize: 12, color: DaywiseStyle.ink))),
        ))]),
      )),
      const SizedBox(height: 16),
      Expanded(child: loading ? const Center(child: CircularProgressIndicator(color: DaywiseStyle.green))
        : error != null ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Unable to load notifications\n$error', textAlign: TextAlign.center),
            TextButton(onPressed: refresh, child: const Text('Retry')),
          ])))
        : RefreshIndicator(onRefresh: refresh, child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
          if (today.isNotEmpty) ...[
            const _SectionTitle('Today'),
            DaywisePanel(child: Column(children: [for (var i = 0; i < today.length; i++) ...[
              if (i != 0) const Divider(height: 1, thickness: 1, color: DaywiseStyle.edge),
              _NotificationTile(item: today[i], time: timeFor(today[i].createdAt), onTap: () => markRead(today[i])),
            ]])),
            const SizedBox(height: 9),
          ],
          if (previous.isNotEmpty) ...[
            const _SectionTitle('Yesterday'),
            DaywisePanel(child: Column(children: [for (var i = 0; i < previous.length; i++) ...[
              if (i != 0) const Divider(height: 1, thickness: 1, color: DaywiseStyle.edge),
              _NotificationTile(item: previous[i], time: 'Yesterday', onTap: () => markRead(previous[i])),
            ]])),
            const SizedBox(height: 19),
          ],
          if (shown.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text(unreadOnly ? 'You have no unread notifications' : 'No notifications yet', style: const TextStyle(color: DaywiseStyle.muted)))),
          DaywisePanel(child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationsSettingScreen(demoMode: widget.demoMode))),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18), child: Row(children: [
              Expanded(child: Text('Notification settings', style: TextStyle(fontSize: 13, color: DaywiseStyle.ink))),
              Icon(Icons.chevron_right, size: 17, color: DaywiseStyle.muted),
            ])))),
        ]))),
    ]));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(0, 0, 0, 9), child: Text(title, style: const TextStyle(fontSize: 11, color: DaywiseStyle.muted, fontWeight: FontWeight.w600)));
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.time, required this.onTap});
  final AppNotification item;
  final String time;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final overdue = item.title.toLowerCase().contains('overdue') || item.type.toLowerCase().contains('overdue');
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.fromLTRB(14, 14, 12, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        if (!item.isRead) ...[const CircleAvatar(radius: 3, backgroundColor: DaywiseStyle.green), const SizedBox(width: 7)],
        Expanded(child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: DaywiseStyle.ink))),
        const SizedBox(width: 7),
        Text(time, style: const TextStyle(fontSize: 10, color: DaywiseStyle.muted)),
      ]),
      const SizedBox(height: 5),
      Text(item.message, style: const TextStyle(fontSize: 11.5, color: DaywiseStyle.muted, height: 1.35)),
      if (overdue) ...[const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFFE8BF), borderRadius: BorderRadius.circular(7)), child: const Text('Overdue', style: TextStyle(color: Color(0xFFC47A00), fontSize: 10)))],
    ])));
  }
}
