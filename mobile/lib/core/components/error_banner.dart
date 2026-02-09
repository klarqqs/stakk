import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens/app_colors.dart';
import '../theme/tokens/app_radius.dart';
import 'buttons/primary_button.dart';

/// Theme-aware error banner with optional retry action.
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.error.withValues(alpha: 0.12) : AppColors.errorBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTheme.body(fontSize: 14, color: AppColors.error),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Retry',
                onPressed: onRetry,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
