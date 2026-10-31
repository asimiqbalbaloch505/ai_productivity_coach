import 'package:flutter/material.dart';

import '../task_models.dart';
import 'add_task_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddTaskScreen(task: task)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(
            task.description?.isNotEmpty == true
                ? task.description!
                : 'No description',
          ),
          const SizedBox(height: 24),
          Text('Priority: ${task.priority.value}'),
          if (task.deadline != null)
            Text(
              'Deadline: '
              '${task.deadline!.toLocal().toString().split(' ').first}',
            ),
          Text(task.isRecurring ? 'Recurring' : 'Not recurring'),
          Text(task.isCompleted ? 'Completed' : 'Incomplete'),
        ],
      ),
    );
  }
}
