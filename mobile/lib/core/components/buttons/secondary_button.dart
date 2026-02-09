import 'package:flutter/material.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import '../../theme/tokens/app_colors.dart';
import '../../theme/tokens/app_radius.dart';

/// Secondary action with soft border. 2026 fintech feel.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.primaryDark : AppColors.primary;
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.6), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 12),
                  Text(label),
                ],
              )
            : Text(label,  style: AppTheme.body(
                    context: context,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),),
      ),
    );
  }
}
