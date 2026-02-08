import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/api/auth_service.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class CheckEmailScreen extends StatefulWidget {
  const CheckEmailScreen({super.key});

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final email = args is String ? args : null;
    if (email != null && _emailController.text != email) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkEmail() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !_isValidEmail(email)) {
      setState(() => _error = 'Please enter a valid email');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final exists = await context.read<AuthProvider>().checkEmail(email);
      if (!mounted) return;
      if (exists) {
        Navigator.of(context).pushReplacementNamed('/auth/login', arguments: email);
      } else {
        Navigator.of(context).pushReplacementNamed('/auth/signup', arguments: email);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e, st) {
      debugPrint('Check email error: $e\n$st');
      setState(() => _error = _formatError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isValidEmail(String s) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s);

  String _formatError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Cannot reach server. Check your connection and that the backend is running.';
    }
    if (msg.contains('Connection timed out') || msg.contains('TimeoutException')) {
      return 'Connection timed out. The server may be slow or unreachable.';
    }
    if (msg.contains('FormatException') || msg.contains('json')) {
      return 'Invalid server response. The backend may have returned an error.';
    }
    return msg.length > 80 ? 'Network or server error. Try again.' : msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your email',
                style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                "We'll check if you have an account and guide you to sign in or sign up.",
                style: AppTheme.body(fontSize: 15, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                ),
                onChanged: (_) => setState(() => _error = null),
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
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _checkEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
