import 'package:flutter/material.dart';
import '../../theme/tokens/app_colors.dart';
import '../../theme/tokens/app_radius.dart';

/// Button-style action. Triggers [onComplete] when pressed.
/// Replaces the previous slide-to-send interaction with a normal button.
class SlideToAction extends StatelessWidget {
  final String label;
  final VoidCallback onComplete;
  final bool disabled;
  final bool isLoading;

  const SlideToAction({
    super.key,
    required this.label,
    required this.onComplete,
    this.disabled = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: (disabled || isLoading) ? null : onComplete,
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
