class ProfileModel {
  final String id;
  final String? fullName;
  final String? email;
  final int dailyGoalMinutes;
  final DateTime? createdAt;

  ProfileModel({
    required this.id,
    this.fullName,
    this.email,
    required this.dailyGoalMinutes,
    this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      dailyGoalMinutes: json['daily_goal_minutes'] as int? ?? 120,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'daily_goal_minutes': dailyGoalMinutes,
    };
  }
}