import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import 'main_navigation_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Session? _session = Supabase.instance.client.auth.currentSession;
  late final StreamSubscription<AuthState> _authSubscription =
      Supabase.instance.client.auth.onAuthStateChange.listen((state) {
    if (mounted) setState(() => _session = state.session);
  });

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _session == null ? const LoginScreen() : const MainNavigationScreen();
  }
}
