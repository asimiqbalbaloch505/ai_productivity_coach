import 'package:flutter/material.dart';

import 'auth_gate.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Productivity Coach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          surface: const Color(0xFFFFFDF5),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFDF5),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
