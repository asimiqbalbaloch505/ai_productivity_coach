// lib/features/habits/screens/add_habit_screen.dart
// "Build a habit" (daywise Screen 14). Creates a habit, or edits an existing
// one when [habit] is passed. Pops with `true` when something was saved so
// the Habits list can refresh.

import 'package:flutter/material.dart';

import '../habit_models.dart';
import '../habit_styles.dart';
import '../habits_db_helper.dart';

const List<int> _dailyGoals = [7, 14, 21, 30, 60, 90];
const List<int> _weeklyGoals = [4, 8, 12, 26, 52];
const List<String> _cues = [
  'After dinner',
  'After brushing teeth',
  'Before bed',
];

int _defaultGoal(HabitFrequency f) => f == HabitFrequency.daily ? 30 : 8;

class AddHabitScreen extends StatefulWidget {
  final Habit? habit;

  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _titleController = TextEditingController();
  final _db = HabitsDBHelper();

  HabitFrequency _frequency = HabitFrequency.daily;
  int _hour = 20;
  int _minute = 0;
  int _goal = 30;
  String? _cue;

  bool _saving = false;
  String? _titleError;

  bool get _isEdit => widget.habit != null;

  String get _timeLabel => formatTime12(_hour, _minute);

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    if (habit != null) {
      _titleController.text = habit.title;
      _frequency = habit.frequency;
      _hour = habit.reminderHour;
      _minute = habit.reminderMinute;
      _goal = habit.goalDays ?? _defaultGoal(habit.frequency);
      _cue = habit.cue;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------- pickers

  Future<T?> _showOptions<T>({
    required String title,
    required List<(String, T)> options,
    required T selected,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: HabitColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: HabitColors.textDark,
                    ),
                  ),
                ),
              ),
              for (final option in options)
                ListTile(
                  title: Text(
                    option.$1,
                    style: const TextStyle(color: HabitColors.textDark),
                  ),
                  trailing: option.$2 == selected
                      ? const Icon(Icons.check_rounded,
                      color: HabitColors.primary)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(option.$2),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFrequency() async {
    final picked = await _showOptions<HabitFrequency>(
      title: 'Frequency',
      selected: _frequency,
      options: const [
        ('Daily', HabitFrequency.daily),
        ('Weekly', HabitFrequency.weekly),
      ],
    );
    if (picked == null || picked == _frequency) return;
    setState(() {
      _frequency = picked;
      _goal = _defaultGoal(picked); // goal units change (days <-> weeks)
    });
  }

  Future<void> _pickReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked == null) return;
    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
    });
  }

  Future<void> _pickGoal() async {
    final goals =
    _frequency == HabitFrequency.daily ? _dailyGoals : _weeklyGoals;
    final unit = _frequency.unit;
    final picked = await _showOptions<int>(
      title: 'Goal',
      selected: _goal,
      options: [for (final g in goals) ('$g $unit streak', g)],
    );
    if (picked != null) setState(() => _goal = picked);
  }

  // -------------------------------------------------------------------- save

  Future<void> _save() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Please enter a habit name');
      return;
    }
    if (title.length < 2) {
      setState(() => _titleError = 'Name is too short');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final reminder = formatTime24(_hour, _minute);
      if (_isEdit) {
        await _db.updateHabit(
          id: widget.habit!.id,
          title: title,
          frequency: _frequency,
          reminderTime: reminder,
          goalDays: _goal,
          cue: _cue,
        );
      } else {
        await _db.addHabit(
          title: title,
          frequency: _frequency,
          reminderTime: reminder,
          goalDays: _goal,
          cue: _cue,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save habit: $e'),
          backgroundColor: HabitColors.danger,
        ),
      );
    }
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final summary = _frequency == HabitFrequency.daily
        ? "You'll check in every day at $_timeLabel"
        : "You'll check in every week at $_timeLabel";

    return Scaffold(
      backgroundColor: HabitColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: back arrow + centred "daywise" wordmark
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: HabitColors.textMuted, size: 22),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'daywise',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: HabitColors.primary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  HabitStyles.screenPadding,
                  16,
                  HabitStyles.screenPadding,
                  16,
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _isEdit ? 'Edit habit' : 'Build a habit',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: HabitColors.textDark,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _saving ? null : _save,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: HabitColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'What habit do you want to build?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: HabitColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: HabitStyles.cardDecoration(radius: 14),
                    child: TextField(
                      controller: _titleController,
                      maxLength: 60,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      cursorColor: HabitColors.primary,
                      style: const TextStyle(
                        fontSize: 16,
                        color: HabitColors.textDark,
                      ),
                      onChanged: (_) {
                        if (_titleError != null) {
                          setState(() => _titleError = null);
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Read for 20 minutes',
                        hintStyle: TextStyle(color: HabitColors.textMuted),
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  if (_titleError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _titleError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: HabitColors.danger,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    decoration: HabitStyles.cardDecoration(radius: 14),
                    child: Column(
                      children: [
                        _SettingRow(
                          label: 'Frequency',
                          value: _frequency.label,
                          onTap: _pickFrequency,
                        ),
                        const _RowDivider(),
                        _SettingRow(
                          label: 'Reminder',
                          value: _timeLabel,
                          onTap: _pickReminder,
                        ),
                        const _RowDivider(),
                        _SettingRow(
                          label: 'Goal',
                          value: '$_goal ${_frequency.unit} streak',
                          onTap: _pickGoal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Choose a cue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: HabitColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final cue in _cues)
                        _CueChip(
                          label: cue,
                          selected: _cue == cue,
                          onTap: () =>
                              setState(() => _cue = _cue == cue ? null : cue),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom summary card + primary button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HabitStyles.screenPadding,
                0,
                HabitStyles.screenPadding,
                16,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: HabitStyles.cardDecoration(radius: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: HabitColors.primary, size: 20),
                    const SizedBox(height: 12),
                    Text(
                      summary,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: HabitColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HabitColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: HabitColors.primary,
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          _isEdit ? 'Save changes' : 'Create habit',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: HabitColors.textDark,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: HabitColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: HabitColors.cardBorder);
  }
}

class _CueChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CueChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? HabitColors.momentumCard : HabitColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? HabitColors.primary : HabitColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? HabitColors.primary : HabitColors.textDark,
          ),
        ),
      ),
    );
  }
}