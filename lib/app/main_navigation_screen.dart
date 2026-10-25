import 'package:flutter/material.dart';

import '../features/ai_coach/screens/ai_coach_screen.dart';
import '../features/dashboard/dashboard_models.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/focus_analytics/screens/focus_screen.dart';
import '../features/habits/screens/habits_screen.dart';
import '../features/tasks/screens/tasks_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    DashboardScreen(onNavigate: _onDashboardNavigate),
    const TasksListScreen(),
    const HabitsScreen(),
    const FocusScreen(),
    const AiCoachScreen(),
  ];

  void _onDashboardNavigate(DashboardDestination destination) {
    switch (destination) {
      case DashboardDestination.tasks:
        setState(() => _selectedIndex = 1);
      case DashboardDestination.habits:
        setState(() => _selectedIndex = 2);
      case DashboardDestination.focus:
        setState(() => _selectedIndex = 3);
      case DashboardDestination.aiCoach:
        setState(() => _selectedIndex = 4);
      case DashboardDestination.analytics:
      case DashboardDestination.profile:
      case DashboardDestination.notifications:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEFEBE0))),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: const Color(0xFFFFFBEA),
            indicatorColor: const Color(0xFFE2EDD8),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? const Color(0xFF1B5E20) : const Color(0xFF4A5568),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected ? const Color(0xFF1B5E20) : const Color(0xFF4A5568),
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: 'Today',
              ),
              NavigationDestination(
                icon: Icon(Icons.check_box_outlined),
                selectedIcon: Icon(Icons.check_box),
                label: 'Tasks',
              ),
              NavigationDestination(
                icon: Icon(Icons.sync),
                selectedIcon: Icon(Icons.sync),
                label: 'Habits',
              ),
              NavigationDestination(
                icon: Icon(Icons.center_focus_weak),
                selectedIcon: Icon(Icons.center_focus_strong),
                label: 'Focus',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Coach',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
