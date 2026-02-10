import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/api/auth_service.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.length < 10) {
      setState(() => _error = 'Please enter a valid phone number');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      await context.read<AuthProvider>().updateProfile(
            phone.startsWith('0') ? phone : '0$phone',
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/auth/create-passcode', arguments: true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to update profile');
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
      body: SafeArea(bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Almost there',
                style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your phone number for NGN deposits and withdrawals',
                style: AppTheme.body(fontSize: 15, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '08012345678',
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
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
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
