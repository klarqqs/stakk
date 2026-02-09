import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/utils/haptic_helper.dart';

/// Modern snackbar utility that displays messages at the top of the screen.
/// Uses Flushbar for better animations and positioning above bottom sheets.
class TopSnackbar {
  TopSnackbar._();

  /// Show a snackbar at the top of the screen.
  /// 
  /// [context] - BuildContext to show the snackbar
  /// [message] - Message text to display
  /// [isError] - If true, shows error styling (red), otherwise success (green)
  /// [duration] - How long to show the snackbar (default: 3 seconds)
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Haptic feedback based on message type
    if (isError) {
      HapticHelper.error();
    } else {
      HapticHelper.success();
    }

    // Check if screen is wide (iPad/tablet)
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 600;

    // Use app's semantic colors
    final primaryColor = isError ? AppColors.error : AppColors.success;
    final backgroundColor = isError ? AppColors.errorBackground : AppColors.successBackground;
    final borderColor = isError ? AppColors.errorBorder : AppColors.successBorder;
    final textColor = isError ? const Color(0xFF991B1B) : const Color(0xFF065F46);

    // Calculate horizontal margin for centering on wide screens
    final horizontalMargin = isWide ? (screenWidth - 500) / 2 : 16.0;

    Flushbar(
      messageText: Row(
        children: [
          // Enhanced icon with animation
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: primaryColor,
              size: 20,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: const Duration(milliseconds: 150)),
          const SizedBox(width: 12),
          // Enhanced text with better typography
          Expanded(
            child: Text(
              message,
              style: AppTheme.body(
                context: context,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            )
                .animate()
                .slideX(
                  begin: -0.2,
                  end: 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(duration: const Duration(milliseconds: 200)),
          ),
        ],
      ),
      margin: EdgeInsets.fromLTRB(horizontalMargin, 16, horizontalMargin, 0),
      borderRadius: BorderRadius.circular(12),
      backgroundColor: backgroundColor,
      borderColor: borderColor.withOpacity(0.5),
      borderWidth: 1.2,
      duration: duration,
      flushbarPosition: FlushbarPosition.TOP,
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      showProgressIndicator: false,
      isDismissible: true,
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
    ).show(context);
  }

  /// Show a success snackbar (green)
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message: message, isError: false, duration: duration);
  }

  /// Show an error snackbar (red)
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message: message, isError: true, duration: duration);
  }
}

/// Legacy function for backward compatibility.
/// Shows a snackbar at the top of the screen.
/// 
/// [content] can be a String or Widget. If String, it's treated as a success message.
/// For error messages, use [TopSnackbar.error()] instead.
@Deprecated('Use TopSnackbar.show() or TopSnackbar.success() instead')
void showTopSnackBar(
  BuildContext context,
  dynamic content, {
  Duration duration = const Duration(seconds: 3),
}) {
  if (content is String) {
    TopSnackbar.show(
      context,
      message: content,
      isError: false,
      duration: duration,
    );
  } else {
    // For Widget content, fallback to old implementation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content is Widget ? content : Text(content.toString()),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 120,
          left: 20,
          right: 20,
        ),
        duration: duration,
      ),
    );
  }
}
