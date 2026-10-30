import 'package:flutter/material.dart';

<<<<<<< HEAD
class AddTaskScreen extends StatelessWidget {
  const AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Add Task Screen'),
=======
import '../task_models.dart';
import '../tasks_db_helper.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key, this.task});

  final Task? task;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _db = TasksDbHelper();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _deadline;
  bool _isRecurring = false;
  bool _saving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _priority = task.priority;
      _deadline = task.deadline;
      _isRecurring = task.isRecurring;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _deadline ?? DateTime.now(),
    );
    if (date == null || !mounted) return;
    setState(() => _deadline = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final task = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _priority,
      deadline: _deadline,
      isCompleted: widget.task?.isCompleted ?? false,
      isRecurring: _isRecurring,
    );
    try {
      final saved =
          _isEditing ? await _db.updateTask(task) : await _db.createTask(task);
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save task: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit task' : 'Add task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a title'
                  : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            DropdownButtonFormField<TaskPriority>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: TaskPriority.values
                  .map((priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(priority.value),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _priority = value ?? TaskPriority.medium),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_deadline == null
                  ? 'No deadline'
                  : 'Deadline: ${_deadline!.toLocal().toString().split(' ').first}'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickDeadline,
                tooltip: 'Choose deadline',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recurring task'),
              value: _isRecurring,
              onChanged: (value) => setState(() => _isRecurring = value),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : Text(_isEditing ? 'Save changes' : 'Create task'),
            ),
          ],
        ),
>>>>>>> origin/feature/tasks
      ),
    );
  }
}
