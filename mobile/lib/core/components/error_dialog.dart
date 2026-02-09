import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens/app_colors.dart';
import '../theme/tokens/app_radius.dart';
import 'buttons/primary_button.dart';

/// Theme-aware error dialog with optional retry action.
/// Similar style to logout dialog - overlays the screen.
class ErrorDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? title;

  const ErrorDialog({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
  });

  /// Show error dialog
  static Future<void> show(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
    String? title,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ErrorDialog(
        message: message,
        onRetry: onRetry,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title ?? 'Error',
              style: AppTheme.header(
                context: context,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: AppTheme.body(context: context, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            onRetry != null ? 'Cancel' : 'OK',
            style: AppTheme.body(
              context: context,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (onRetry != null)
          PrimaryButton(
            label: 'Retry',
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
          ),
      ],
    );
  }
}
