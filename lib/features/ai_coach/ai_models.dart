
class CoachMessage {
  const CoachMessage({
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  final String text;
  final bool isUser;
  final DateTime createdAt;
}

class CoachContext {
  const CoachContext({
    required this.tasks,
    required this.habits,
    required this.habitLogs,
    required this.focusSessions,
  });

  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> habits;
  final List<Map<String, dynamic>> habitLogs;
  final List<Map<String, dynamic>> focusSessions;

  Map<String, dynamic> toJson() {
    return {
      'tasks': tasks,
      'habits': habits,
      'habit_logs': habitLogs,
      'focus_sessions': focusSessions,
      'generated_at': DateTime.now().toIso8601String(),
    };
  }
}
