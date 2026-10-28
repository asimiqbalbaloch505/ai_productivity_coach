import 'package:flutter/material.dart';
import '../profile_models.dart';
import '../profile_db_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileDBHelper _dbHelper = ProfileDBHelper();
  
  bool _isLoading = true;
  String _fullName = 'Alex Morgan'; 
  String _email = 'alex@example.com';
  int _dailyGoalMinutes = 60;
  int _dailyTasks = 6;

  final Color bgColor = const Color(0xFFFFF7EF); 
  final Color primaryGreen = const Color(0xFF006C45); 
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await _dbHelper.getUserProfile();
      if (profile != null) {
        setState(() {
          _fullName = profile.fullName ?? 'Alex Morgan';
          _email = profile.email ?? 'No email provided';
          _dailyGoalMinutes = profile.dailyGoalMinutes;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String getInitials(String name) {
    List<String> names = name.split(" ");
    String initials = "";
    int numWords = names.length > 2 ? 2 : names.length;
    for (int i = 0; i < numWords; i++) {
      if (names[i].isNotEmpty) initials += names[i][0].toUpperCase();
    }
    return initials.isEmpty ? "AM" : initials;
  }

  void _showEditProfileForm() {
    final TextEditingController nameController = TextEditingController(text: _fullName);
    final TextEditingController goalController = TextEditingController(text: _dailyGoalMinutes.toString());
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 30,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryGreen)),
                  const SizedBox(height: 24),
                  
                  const Text('Full name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryGreen)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Focus time (Minutes)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: goalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryGreen)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        setModalState(() => isSaving = true);
                        try {
                          int newGoal = int.tryParse(goalController.text) ?? 60;
                          await _dbHelper.updateProfile(
                            fullName: nameController.text,
                            dailyGoalMinutes: newGoal,
                          );
                          setState(() {
                            _fullName = nameController.text;
                            _dailyGoalMinutes = newGoal;
                          });
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          debugPrint('Error updating profile: $e');
                        } finally {
                          setModalState(() => isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryGreen))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.arrow_back, color: Colors.black54),
                        Text(
                          'daywise',
                          style: TextStyle(color: primaryGreen, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        ),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.orange.shade100,
                          child: Text(getInitials(_fullName), style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                        Icon(Icons.settings_outlined, color: Colors.grey.shade700),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.orange.shade100,
                            child: Text(getInitials(_fullName), style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),
                          Text(_fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_email, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _showEditProfileForm,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            ),
                            child: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text('Your goals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _buildListTile('Daily tasks', '$_dailyTasks tasks'),
                          Divider(height: 1, color: Colors.grey.shade200),
                          _buildListTile('Focus time', '$_dailyGoalMinutes min'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text('Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _buildListTile('Notifications', ''),
                          Divider(height: 1, color: Colors.grey.shade200),
                          _buildListTile('Appearance', 'System'),
                          Divider(height: 1, color: Colors.grey.shade200),
                          _buildListTile('AI coach tone', 'Encouraging'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: bgColor,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey.shade500,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.check_box_outlined), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.loop), label: 'Habits'),
          BottomNavigationBarItem(icon: Icon(Icons.gps_fixed), label: 'Focus'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Coach'),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, String trailingText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Row(
            children: [
              if (trailingText.isNotEmpty) Text(trailingText, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
              if (trailingText.isNotEmpty) const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ],
      ),
    );
  }
}
