import 'package:supabase_flutter/supabase_flutter.dart';

import 'task_models.dart';

class TasksDbHelper {
  TasksDbHelper({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required to manage tasks.');
    }
    return user.id;
  }

  Future<List<Task>> fetchTasks() async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('user_id', _userId)
        .order('deadline', ascending: true);
    return (rows as List)
        .map((row) => Task.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<Task> createTask(Task task) async {
    final row = await _client
        .from('tasks')
        .insert(task.toInsertMap(_userId))
        .select()
        .single();
    return Task.fromMap(Map<String, dynamic>.from(row));
  }

  Future<Task> updateTask(Task task) async {
    final id = task.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Cannot update a task without an id.');
    }
    final row = await _client
        .from('tasks')
        .update(task.toUpdateMap())
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .single();
    return Task.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> deleteTask(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('Cannot delete a task without an id.');
    }
    await _client.from('tasks').delete().eq('id', id).eq('user_id', _userId);
  }
}