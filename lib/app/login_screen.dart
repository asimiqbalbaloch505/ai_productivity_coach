import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _message = null;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty || (_isSignUp && name.isEmpty)) {
      setState(() {
        _isError = true;
        _message = _isSignUp
            ? 'Enter your name, email, and password.'
            : 'Enter your email and password.';
      });
      return;
    }
    if (_isSignUp && password.length < 6) {
      setState(() {
        _isError = true;
        _message = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      if (_isSignUp) {
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': name},
        );
        if (!mounted) return;
        setState(() {
          _isError = false;
          _message = response.session == null
              ? 'Account created. Check your email to confirm it, then sign in.'
              : 'Account created. You are now signed in.';
          _isSignUp = false;
        });
      } else {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (!mounted) return;
        if (response.session == null) {
          setState(() {
            _isError = true;
            _message = 'Sign-in needs confirmation. Check your email, then try again.';
          });
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _message = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isError = true;
          _message = 'Could not complete the request. Try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = _isSignUp ? 'Create account' : 'Sign in';
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'AI Productivity Coach',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp ? 'Create an account to get started' : 'Sign in to see your day',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_isSignUp) ...[
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        helperText: 'Use at least 6 characters',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _message!,
                        style: TextStyle(color: _isError ? Colors.red : Colors.green[800]),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(action),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _switchMode,
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account',
                      ),
                    ),
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
