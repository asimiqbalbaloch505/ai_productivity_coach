import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../tasks/task_models.dart';
import '../../tasks/tasks_db_helper.dart';
import '../focus_analytics_db_helper.dart';
import '../focus_analytics_models.dart';
import 'focus_analytics_screen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  int _selectedTabIndex = 0; // 0: Focus, 1: Short break, 2: Long break
  static const List<int> _modeMinutes = [25, 5, 15];
  final _db = FocusAnalyticsDbHelper();
  final _tasksDb = TasksDbHelper();
  Timer? _timer;
  late int _remainingSeconds = _modeMinutes[_selectedTabIndex] * 60;
  bool _isRunning = false;
  bool _savingSession = false;
  bool _sessionRecorded = false;
  bool _tasksLoading = true;
  bool _summaryLoading = true;
  String? _taskError;
  String? _summaryError;
  List<Task> _tasks = [];
  Task? _selectedTask;
  FocusSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadSummary();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _tasksDb.fetchTasks();
      if (!mounted) return;
      Task? activeTask;
      for (final task in tasks) {
        if (!task.isCompleted) {
          activeTask = task;
          break;
        }
      }
      setState(() {
        _tasks = tasks;
        _selectedTask = activeTask;
        _taskError = null;
      });
    } catch (error) {
      if (mounted) setState(() => _taskError = error.toString());
    } finally {
      if (mounted) setState(() => _tasksLoading = false);
    }
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await _db.fetchSummary();
      if (mounted) {
        setState(() {
          _summary = summary;
          _summaryError = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _summaryError = error.toString());
    } finally {
      if (mounted) setState(() => _summaryLoading = false);
    }
  }

  FocusSessionType get _sessionType => switch (_selectedTabIndex) {
    1 => FocusSessionType.shortBreak,
    2 => FocusSessionType.longBreak,
    _ => FocusSessionType.focus,
  };

  int get _elapsedSeconds =>
      _modeMinutes[_selectedTabIndex] * 60 - _remainingSeconds;

  void _startOrPause() {
    if (_savingSession) return;
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }
    if (_remainingSeconds == 0) {
      setState(() => _remainingSeconds = _modeMinutes[_selectedTabIndex] * 60);
      _sessionRecorded = false;
    }
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        _finishSession();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _endSession() async {
    if (_savingSession) return;
    _timer?.cancel();
    if (mounted) setState(() => _isRunning = false);
    final saved = await _finishSession();
    if (saved && mounted) {
      setState(() => _remainingSeconds = _modeMinutes[_selectedTabIndex] * 60);
      _sessionRecorded = false;
    }
  }

  Future<bool> _finishSession() async {
    final elapsedSeconds = _elapsedSeconds;
    if (elapsedSeconds <= 0 || _sessionRecorded) return true;
    if (_savingSession) return false;
    setState(() => _savingSession = true);
    try {
      await _db.saveSession(
        durationMinutes: ((elapsedSeconds + 30) ~/ 60)
            .clamp(1, _modeMinutes[_selectedTabIndex])
            .toInt(),
        type: _sessionType,
        completedAt: DateTime.now(),
        taskId: _selectedTask?.id,
      );
      _sessionRecorded = true;
      await _loadSummary();
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save focus session: $error')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _savingSession = false);
    }
  }

  Future<void> _selectMode(int index) async {
    if (index == _selectedTabIndex || _isRunning || _savingSession) return;
    if (_elapsedSeconds > 0 && !await _finishSession()) return;
    if (!mounted) return;
    setState(() {
      _selectedTabIndex = index;
      _remainingSeconds = _modeMinutes[index] * 60;
    });
    _sessionRecorded = false;
  }

  Future<void> _pickTask() async {
    if (_tasksLoading) return;
    final selected = await showModalBottomSheet<Object?>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('No task'),
              trailing: _selectedTask == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, 'no-task'),
            ),
            ..._tasks.map(
              (task) => ListTile(
                title: Text(task.title),
                subtitle: Text(task.isCompleted ? 'Completed' : 'Active'),
                trailing: task.id == _selectedTask?.id
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, task),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    if (selected == 'no-task') {
      setState(() => _selectedTask = null);
    } else if (selected is Task) {
      setState(() => _selectedTask = selected);
    }
  }

  // Color Palette
  static const Color backgroundColor = Color(0xFFFAF7F0);
  static const Color primaryGold = Color(0xFFC68A00);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardColor = Colors.white;

  @override
  Widget build(BuildContext meContext) {
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Top Bar (App Title & Profile/Notifs)
                    _buildHeader(),
                    const SizedBox(height: 20),

                    // 2. Section Title & History Icon
                    _buildTitleRow(),
                    const SizedBox(height: 20),

                    // 3. Segmented Tab Selector
                    _buildSegmentedTab(),
                    const SizedBox(height: 35),

                    // 4. Circular Timer Display
                    _buildTimerDisplay(),
                    const SizedBox(height: 35),

                    // 5. Working On Card
                    _buildWorkingOnCard(),
                    const SizedBox(height: 24),

                    // 6. Action Button & End Session
                    _buildActionButtons(),
                    const SizedBox(height: 28),

                    // 7. Today/Weekly Stats Card
                    _buildStatsCard(),
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
        Row(
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              ),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_outlined,
                    size: 26,
                    color: textDark,
                  ),
                  Positioned(
                    top: 0,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
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
        ),
      ],
    );
  }

  // --- Title & History Row ---
  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Focus',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FocusAnalyticsScreen(),
              ),
            );
          },
          icon: const Icon(Icons.history, color: textDark, size: 26),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  // --- Segmented Control ---
  Widget _buildSegmentedTab() {
    final tabs = ['Focus', 'Short break', 'Long break'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFECE4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: _isRunning || _savingSession
                  ? null
                  : () => _selectMode(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? cardColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? textDark : textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- Circular Timer ---
  Widget _buildTimerDisplay() {
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(230, 230),
            painter: TimerRingPainter(
              progress:
                  1 -
                  _remainingSeconds / (_modeMinutes[_selectedTabIndex] * 60),
              ringColor: const Color(0xFFEFECE4),
              arcColor: primaryGold,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:'
                '${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _selectedTabIndex == 0 ? 'Focus session' : 'Break time',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Working On Task Card ---
  Widget _buildWorkingOnCard() {
    return InkWell(
      onTap: _pickTask,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFECE4), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Working on',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tasksLoading
                        ? 'Loading tasks...'
                        : _taskError != null
                        ? 'Tasks unavailable'
                        : _selectedTask?.title ?? 'Choose a task',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.edit_outlined, color: textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // --- Action Buttons ---
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _savingSession ? null : _startOrPause,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Icon(
              _isRunning ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _savingSession ? null : _endSession,
          child: const Text(
            'End session',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
        ),
      ],
    );
  }

  // --- Stats Summary Card ---
  Widget _buildStatsCard() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEFECE4), width: 1.2),
          ),
          child: Row(
            children: [
              _buildStatColumn(
                _summaryLoading
                    ? '...'
                    : _summaryError != null
                    ? '—'
                    : '${_summary?.todayMinutes ?? 0} min',
                'Today',
              ),
              _buildDivider(),
              _buildStatColumn(
                _summaryLoading
                    ? '...'
                    : _summaryError != null
                    ? '—'
                    : '${_summary?.weekSessions ?? 0} sessions',
                'This week',
              ),
              _buildDivider(),
              _buildStatColumn(
                _summaryLoading
                    ? '...'
                    : _summaryError != null
                    ? '—'
                    : '${_summary?.averageFocusPercent ?? 0}%',
                'Avg focus',
              ),
            ],
          ),
        ),
        if (_summaryError != null) ...[
          const SizedBox(height: 8),
          Text(
            'Unable to load session metrics: $_summaryError',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: textMuted),
          ),
        ],
      ],
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          value == '...'
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 28, width: 1, color: const Color(0xFFE2E8F0));
  }
}

// --- Custom Painter for Timer Arc ---
class TimerRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color arcColor;

  TimerRingPainter({
    required this.progress,
    required this.ringColor,
    required this.arcColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background Full Ring
    final bgPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Active Golden Arc
    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start angle from top-right arc region (~ -70 degrees)
    const startAngle = -pi * 0.4;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
