import 'package:flutter/material.dart';
import 'screens/notification_screen.dart';

/// Local UI-only demo. Does not connect to Supabase or change production data.
void main() {
  runApp(MaterialApp(
    title: 'Notifications • Design Preview',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      scaffoldBackgroundColor: const Color(0xFFFFFDF5),
    ),
    home: const NotificationScreen(demoMode: true),
  ));
}
