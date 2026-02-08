import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stakk_savings/core/constants/storage_keys.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';

class ReenterPasscodeScreen extends StatefulWidget {
  const ReenterPasscodeScreen({super.key});

  @override
  State<ReenterPasscodeScreen> createState() => _ReenterPasscodeScreenState();
}

class _ReenterPasscodeScreenState extends State<ReenterPasscodeScreen> {
  String _passcode = '';
  String? _error;
  final _storage = const FlutterSecureStorage();

  void _onDigit(String digit) {
    if (_passcode.length >= 4) return;
    setState(() {
      _passcode += digit;
      _error = null;
    });
    if (_passcode.length == 4) {
      _verify();
    }
  }

  void _onBackspace() {
    if (_passcode.isEmpty) return;
    setState(() {
      _passcode = _passcode.substring(0, _passcode.length - 1);
      _error = null;
    });
  }

  Future<void> _verify() async {
    final temp = await _storage.read(key: StorageKeys.tempPasscode);
    if (temp == null || temp.isEmpty) {
      setState(() => _error = 'Session expired. Please start over.');
      return;
    }
    if (_passcode == temp) {
      await _storage.write(key: StorageKeys.passcode, value: _passcode);
      await _storage.delete(key: StorageKeys.tempPasscode);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (r) => false);
    } else {
      setState(() {
        _error = 'Passcode mismatch. Try again.';
        _passcode = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'Re-enter passcode',
                style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Confirm your 4-digit passcode',
                style: AppTheme.body(context: context, fontSize: 15),
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
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _passcode.length
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFE5E7EB),
                    ),
                  );
                }),
              ),
              const Spacer(),
              _PasscodePad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasscodePad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  const _PasscodePad({
    required this.onDigit,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(label: '1', onPressed: () => onDigit('1')),
            _PadButton(label: '2', onPressed: () => onDigit('2')),
            _PadButton(label: '3', onPressed: () => onDigit('3')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(label: '4', onPressed: () => onDigit('4')),
            _PadButton(label: '5', onPressed: () => onDigit('5')),
            _PadButton(label: '6', onPressed: () => onDigit('6')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(label: '7', onPressed: () => onDigit('7')),
            _PadButton(label: '8', onPressed: () => onDigit('8')),
            _PadButton(label: '9', onPressed: () => onDigit('9')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72),
            _PadButton(label: '0', onPressed: () => onDigit('0')),
            _PadButton(
              icon: Icons.backspace_outlined,
              onPressed: onBackspace,
            ),
          ],
        ),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onPressed;

  const _PadButton({this.label, this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, size: 28, color: const Color(0xFF374151))
                : Text(
                    label!,
                    style: AppTheme.header(context: context, fontSize: 28, fontWeight: FontWeight.w500),
                  ),
          ),
        ),
      ),
    );
  }
}
