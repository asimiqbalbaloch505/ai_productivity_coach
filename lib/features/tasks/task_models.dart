class Task {
  const Task({
    this.id,
    required this.title,
    this.description,
    required this.priority,
    this.deadline,
    this.isCompleted = false,
    this.isRecurring = false,
    this.createdAt,
  });

  final String? id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? deadline;
  final bool isCompleted;
  final bool isRecurring;
  final DateTime? createdAt;

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toString(),
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      priority: TaskPriority.fromValue(map['priority']?.toString()),
      deadline: _parseDate(map['deadline']),
      isCompleted: map['is_completed'] as bool? ?? false,
      isRecurring: map['is_recurring'] as bool? ?? false,
      createdAt: _parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'priority': priority.value,
      'deadline': deadline?.toUtc().toIso8601String(),
      'is_completed': isCompleted,
      'is_recurring': isRecurring,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'priority': priority.value,
      'deadline': deadline?.toUtc().toIso8601String(),
      'is_completed': isCompleted,
      'is_recurring': isRecurring,
    };
  }

  Task copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? deadline,
    bool? isCompleted,
    bool? isRecurring,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }
}

enum TaskPriority {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH');

  const TaskPriority(this.value);

  final String value;

  factory TaskPriority.fromValue(String? value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.value == value?.toUpperCase(),
      orElse: () => TaskPriority.medium,
    );
  }
}