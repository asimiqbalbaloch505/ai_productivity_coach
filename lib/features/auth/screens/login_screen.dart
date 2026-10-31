import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth_db_helper.dart';
import '../auth_theme.dart';
import 'reset_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthDBHelper();

  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _auth.signIn(email: _email.text.trim(), password: _password.text);
    } on AuthException catch (e) {
      if (mounted) {
        _message(e.message);
      }
    } catch (_) {
      if (mounted) {
        _message('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _social(bool google) async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final started = google
          ? await _auth.signInWithGoogle()
          : await _auth.signInWithApple();

      if (!mounted) return;

      if (!started) {
        _message('Sign-in could not start. Check provider settings.');
      }

      // OAuth commonly opens a browser and returns to the app.
      // Configure an auth-state listener or callback to navigate
      // after Supabase confirms the user's session.
    } on AuthException catch (e) {
      if (mounted) {
        _message(e.message);
      }
    } catch (_) {
      if (mounted) {
        _message('Social sign-in is not configured yet.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 28),

                    Center(child: AuthTheme.logo()),

                    const SizedBox(height: 48),

                    Center(
                      child: AuthTheme.heading('Make today feel\nlighter.'),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'A thoughtful coach for your tasks, habits,\nand focus.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AuthTheme.muted,
                        fontSize: 11,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 18),

                    AuthTheme.label('Email address'),

                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'alex@example.com',
                      ),
                      validator: (value) {
                        if (value == null ||
                            !RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    AuthTheme.label('Password'),

                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      autofillHints: const [AutofillHints.password],
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Your password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hidePassword = !_hidePassword;
                            });
                          },
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 16,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password';
                        }

                        return null;
                      },
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: AuthTheme.link('Forgot password?', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResetPasswordScreen(),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 10),

                    AuthTheme.primaryButton(
                      text: _loading ? 'Please wait...' : 'Log in',
                      onPressed: _loading ? null : _login,
                    ),

                    const SizedBox(height: 6),

                    AuthTheme.outlineButton(
                      text: 'Create account',
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Expanded(child: Divider(color: AuthTheme.border)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'or continue with',
                            style: TextStyle(
                              color: AuthTheme.muted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AuthTheme.border)),
                      ],
                    ),

                    const SizedBox(height: 15),

                    AuthTheme.outlineButton(
                      text: 'Continue with Apple',
                      onPressed: _loading ? null : () => _social(false),
                    ),

                    const SizedBox(height: 7),

                    AuthTheme.outlineButton(
                      text: 'Continue with Google',
                      onPressed: _loading ? null : () => _social(true),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'By continuing, you agree to our Terms and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, color: AuthTheme.muted),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
