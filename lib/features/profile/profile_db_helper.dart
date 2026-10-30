import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_models.dart';

class ProfileDBHelper {
  final _supabase = Supabase.instance.client;

  Future<ProfileModel?> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        return ProfileModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required int dailyGoalMinutes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _supabase.from('profiles').upsert({
        'id': user.id,
        'full_name': fullName,
        'daily_goal_minutes': dailyGoalMinutes,
      });
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }
}