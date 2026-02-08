import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/providers/auth_provider.dart';
import 'package:stakk_savings/api/auth_service.dart';

class EmailOtpScreen extends StatefulWidget {
  const EmailOtpScreen({super.key});

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final _emailController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  String _email = '';
  String _step = 'email'; // 'email' | 'otp'
  bool _loading = false;
  String? _error;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _otpFocusNodes) {
      n.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestOtp() async {
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
      // Try login first; if user doesn't exist (404), try signup
      try {
        await context.read<AuthProvider>().requestEmailOtp(email, purpose: 'login');
      } on AuthException catch (e) {
        if (e.message.contains('No account') || e.message.contains('not found')) {
          await context.read<AuthProvider>().requestEmailOtp(email, purpose: 'signup');
        } else {
          rethrow;
        }
      }
      setState(() {
        _email = email;
        _step = 'otp';
        _loading = false;
        _resendCountdown = 60;
      });
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent to your email')),
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to send code');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
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

  Future<void> _verifyOtp() async {
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
      await context.read<AuthProvider>().signInWithEmailOtp(_email, code);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        for (final c in _otpControllers) {
          c.clear();
        }
        _otpFocusNodes[0].requestFocus();
      });
    } catch (_) {
      setState(() => _error = 'Verification failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() => _loading = true);
    try {
      try {
        await context.read<AuthProvider>().requestEmailOtp(_email, purpose: 'login');
      } on AuthException catch (e) {
        if (e.message.contains('No account') || e.message.contains('not found')) {
          await context.read<AuthProvider>().requestEmailOtp(_email, purpose: 'signup');
        } else {
          rethrow;
        }
      }
      setState(() {
        _resendCountdown = 60;
        for (final c in _otpControllers) {
          c.clear();
        }
        _otpFocusNodes[0].requestFocus();
      });
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New code sent')),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isValidEmail(String s) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 'otp') {
              setState(() => _step = 'email');
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _step == 'email' ? 'Sign in with Email' : 'Enter Code',
                style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _step == 'email'
                    ? 'Enter your email to receive a verification code'
                    : 'We sent a 6-digit code to $_email',
                style: AppTheme.body(fontSize: 15, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 32),
              if (_step == 'email') ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _requestOtp,
                    child: _loading ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ) : const Text('Continue'),
                  ),
                ),
              ] else ...[
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
                        decoration: const InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < 5) {
                            _otpFocusNodes[i + 1].requestFocus();
                          }
                          if (i == 5 && v.isNotEmpty) {
                            final code = _otpControllers.map((c) => c.text).join();
                            if (code.length == 6) _verifyOtp();
                          }
                        },
                        onTap: () => _otpControllers[i].selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _otpControllers[i].text.length,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verifyOtp,
                    child: _loading ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ) : const Text('Verify'),
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
                        onPressed: _loading ? null : _resendOtp,
                        child: const Text('Resend'),
                      ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 20),
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
            ],
          ),
        ),
      ),
    );
  }
}
