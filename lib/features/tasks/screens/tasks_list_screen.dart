import 'package:flutter/material.dart';
import '../task_models.dart';
import '../tasks_db_helper.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';

enum _TaskFilter { all, today, upcoming, completed }

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  final _db = TasksDbHelper();
  final _searchController = TextEditingController();
  List<Task> _tasks = [];
  _TaskFilter _filter = _TaskFilter.all;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await _db.fetchTasks();
      if (mounted) setState(() => _tasks = tasks);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Task> get _visibleTasks {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((task) {
      final matchesQuery =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          (task.description?.toLowerCase().contains(query) ?? false);
      final deadline = task.deadline;
      final matchesFilter = switch (_filter) {
        _TaskFilter.all => true,
        _TaskFilter.completed => task.isCompleted,
        _TaskFilter.today =>
          deadline != null &&
              !deadline.isBefore(today) &&
              deadline.isBefore(today.add(const Duration(days: 1))),
        _TaskFilter.upcoming =>
          deadline != null && !deadline.isBefore(today) && !task.isCompleted,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _addTask() async {
    final task = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
    if (task != null) _loadTasks();
  }

  Future<void> _editTask(Task task) async {
    final updated = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => AddTaskScreen(task: task)),
    );
    if (updated != null) _loadTasks();
  }

  Future<void> _toggleCompleted(Task task, bool value) async {
    try {
      await _db.updateTask(task.copyWith(isCompleted: value));
      await _loadTasks();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update task: $error')),
        );
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || task.id == null) return;
    try {
      await _db.deleteTask(task.id!);
      await _loadTasks();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete task: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _visibleTasks;
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search tasks',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _TaskFilter.values.map((filter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(filter.name),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('Unable to load tasks: $_error'))
                : tasks.isEmpty
                ? const Center(child: Text('No tasks found'))
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return ListTile(
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (value) =>
                                _toggleCompleted(task, value ?? false),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text(task.priority.value),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetailScreen(task: task),
                            ),
                          ),
                          onLongPress: () => _editTask(task),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteTask(task),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
>>>>>>> origin/feature/tasks
      ),
    );
  }
}
