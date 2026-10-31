import 'package:flutter/material.dart';

import '../../profile/screens/profile_screen.dart';
import '../focus_analytics_db_helper.dart';
import '../focus_analytics_models.dart';

class FocusAnalyticsScreen extends StatefulWidget {
  const FocusAnalyticsScreen({super.key});

  @override
  State<FocusAnalyticsScreen> createState() => _FocusAnalyticsScreenState();
}

class _FocusAnalyticsScreenState extends State<FocusAnalyticsScreen> {
  final _db = FocusAnalyticsDbHelper();
  late DateTime _weekStart = _startOfSelectedWeek(DateTime.now());
  FocusAnalyticsData? _data;
  bool _loading = true;
  String? _error;

  // Color Palette matching design
  static const Color backgroundColor = Color(0xFFFAF7F0);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFEFECE4);

  // Greens
  static const Color greenPrimary = Color(0xFF3B8266);
  static const Color greenHighlight = Color(0xFF026C39);
  static const Color greenBadgeBg = Color(0xFFE2F3E8);
  static const Color greenBadgeText = Color(0xFF15803D);
  static const Color greenTrack = Color(0xFFD8ECE0);

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _db.fetchAnalytics(_weekStart);
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeWeek(int offset) async {
    if (_loading) return;
    final nextWeek = _weekStart.add(Duration(days: offset * 7));
    if (nextWeek.isAfter(_startOfSelectedWeek(DateTime.now()))) return;
    setState(() => _weekStart = nextWeek);
    await _loadAnalytics();
  }

  static DateTime _startOfSelectedWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(
      Duration(days: (day.weekday - DateTime.wednesday + 7) % 7),
    );
  }

  String get _weekLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final end = _weekStart.add(const Duration(days: 6));
    if (_weekStart.month == end.month) {
      return '${months[_weekStart.month - 1]} ${_weekStart.day}–${end.day}';
    }
    return '${months[_weekStart.month - 1]} ${_weekStart.day}–'
        '${months[end.month - 1]} ${end.day}';
  }

  static String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '${remainder}m';
    if (remainder == 0) return '${hours}h';
    return '${hours}h ${remainder}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top App Bar
                    _buildHeader(),
                    const SizedBox(height: 20),

                    // 2. Navigation & Title Row
                    _buildTitleRow(context),
                    const SizedBox(height: 20),

                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _buildErrorState()
                    else ...[
                      _buildWeekInReviewCard(),
                      const SizedBox(height: 24),
                      _buildProductivityTrendSection(),
                      const SizedBox(height: 24),
                      _buildHabitConsistencySection(),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Top App Bar ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'daywise',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textDark,
            letterSpacing: -0.5,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE2E8F0),
            child: Text(
              'AM',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMuted.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Title Row (Back Arrow, Title, Date Selector) ---
  Widget _buildTitleRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.chevron_left, color: textDark, size: 28),
            ),
            const SizedBox(width: 8),
            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: _loading ? null : () => _changeWeek(-1),
              icon: const Icon(Icons.chevron_left, color: textDark),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderLight, width: 1.2),
              ),
              child: Text(
                _weekLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed:
                  !_loading &&
                      _weekStart.isBefore(_startOfSelectedWeek(DateTime.now()))
                  ? () => _changeWeek(1)
                  : null,
              icon: const Icon(Icons.chevron_right, color: textDark),
            ),
          ],
        ),
      ],
    );
  }

  // --- Your Week in Review Card ---
  Widget _buildWeekInReviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your week in review',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: greenBadgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Weekly summary',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: greenBadgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildReviewStat(
                '${_data!.taskCompletionPercent}%',
                'Task completion',
              ),
              _buildReviewStat(
                _formatDuration(_data!.focusedMinutes),
                'Focused time',
              ),
              _buildReviewStat(
                '${_data!.habitConsistencyPercent}%',
                'Habit\nconsistency',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // --- Productivity Trend Section & Bar Chart ---
  Widget _buildProductivityTrendSection() {
    const days = ['Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue'];
    final values = _data!.dailyFocusMinutes;
    final peak = values.fold<int>(
      0,
      (best, value) => value > best ? value : best,
    );
    final peakIndex = values.indexOf(peak);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productivity trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderLight, width: 1.2),
          ),
          child: SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (index) {
                final minutes = values[index];
                final height = peak == 0
                    ? 0.06
                    : (minutes / peak).clamp(0.06, 1.0).toDouble();
                return _buildBar(
                  days[index],
                  height,
                  peak > 0 && index == peakIndex,
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(String day, double heightFactor, bool isHighlighted) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 110 * heightFactor,
          decoration: BoxDecoration(
            color: isHighlighted ? greenHighlight : greenPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          day,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  // --- Habit Consistency Section ---
  Widget _buildHabitConsistencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Habit consistency',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const SizedBox(height: 16),
        if (_data!.habits.isEmpty)
          const Text(
            'No habits to report for this week.',
            style: TextStyle(color: textMuted),
          )
        else
          ..._data!.habits.indexed.expand((entry) {
            final (index, habit) = entry;
            return [
              if (index > 0) const SizedBox(height: 16),
              _buildHabitProgressRow(
                habit.title,
                habit.completionRate,
                '${(habit.completionRate * 100).round()}%',
              ),
            ];
          }),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Text(
              'Unable to load analytics: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: textMuted),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadAnalytics,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitProgressRow(String title, double percentage, String label) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 10,
            backgroundColor: greenTrack,
            valueColor: AlwaysStoppedAnimation<Color>(greenHighlight),
          ),
        ),
      ],
    );
  }
}
