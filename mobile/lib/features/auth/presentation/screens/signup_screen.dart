import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/api/auth_service.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  final String? email;

  const SignupScreen({super.key, this.email});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late final TextEditingController _emailController;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
      final args = ModalRoute.of(context)?.settings.arguments;
      final email = args is String ? args : widget.email;
      if (email != null && _emailController.text != email) {
        _emailController.text = email;
        if (mounted) setState(() {});
      }
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill all required fields');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      await context.read<AuthProvider>().registerEmail(
            email: email,
            password: password,
            firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        '/auth/verify-email',
        arguments: {'email': email, 'isSignup': true},
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e, st) {
      debugPrint('Signup error: $e\n$st');
      setState(() => _error = e.toString().contains('Connection') || e.toString().contains('Socket')
          ? 'Cannot reach server. Check your connection.'
          : 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final email = _emailController.text.trim();
            Navigator.of(context).pushReplacementNamed(
              '/auth/check-email',
              arguments: email.isNotEmpty ? email : null,
            );
          },
        ),
      ),
      body: SafeArea(bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create account',
                style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign up with your email and password',
                style: AppTheme.body(fontSize: 15, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _firstNameController,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                  labelText: 'First name',
                  hintText: 'John',
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                  labelText: 'Last name',
                  hintText: 'Doe',
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                readOnly: true,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableInteractiveSelection: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/auth/check-email'),
                    tooltip: 'Use different email',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                enableInteractiveSelection: false,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 8),
              Text(
                'At least 8 characters',
                style: AppTheme.body(fontSize: 12, color: const Color(0xFF9CA3AF)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    _error!,
                    style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Create Account',
                  onPressed: _loading ? null : _signup,
                  isLoading: _loading,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/auth/check-email'),
                child: Text(
                  'Use a different email',
                  style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
