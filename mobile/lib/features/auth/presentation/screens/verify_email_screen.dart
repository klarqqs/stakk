import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/api/auth_service.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  String _email = '';
  bool _loading = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _email = (args['email'] as String?) ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in _otpControllers) c.dispose();
    for (final n in _otpFocusNodes) n.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_resendCountdown <= 1) {
          _countdownTimer?.cancel();
          _resendCountdown = 0;
        } else {
          _resendCountdown--;
        }
      });
    });
  }

  Future<void> _verify() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) {
      setState(() => _error = 'Please enter the 6-digit code');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final res = await context.read<AuthProvider>().verifyEmailSignup(
            email: _email,
            code: code,
          );
      if (!mounted) return;
      await context.read<AuthProvider>().saveTokensFromAuthResponse(res);
      if (!mounted) return;
      final needsProfile = res.user.phoneNumber.startsWith('email:');
      if (needsProfile) {
        Navigator.of(context).pushReplacementNamed('/auth/complete-profile');
      } else {
        Navigator.of(context).pushReplacementNamed('/auth/create-passcode', arguments: false);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Verification failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0) return;

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().resendVerifyOtp(_email);
      if (!mounted) return;
      setState(() {
        _resendCountdown = 60;
        for (final c in _otpControllers) c.clear();
        _otpFocusNodes[0].requestFocus();
      });
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New code sent')),
        );
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verify your email',
                style: AppTheme.header(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to $_email',
                style: AppTheme.body(fontSize: 15, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 48,
                    child: TextField(
                      controller: _otpControllers[i],
                      focusNode: _otpFocusNodes[i],
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      enableInteractiveSelection: false,
                      decoration: const InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 5) _otpFocusNodes[i + 1].requestFocus();
                        if (i == 5 && v.isNotEmpty) {
                          final code = _otpControllers.map((c) => c.text).join();
                          if (code.length == 6) _verify();
                        }
                      },
                    ),
                  );
                }),
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
                  onPressed: _loading ? null : _verify,
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
                      : const Text('Verify'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                  ),
                  if (_resendCountdown > 0)
                    Text(
                      'Resend in ${_resendCountdown}s',
                      style: AppTheme.body(fontSize: 14, color: const Color(0xFF9CA3AF)),
                    )
                  else
                    TextButton(
                      onPressed: _loading ? null : _resend,
                      child: const Text('Resend'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
