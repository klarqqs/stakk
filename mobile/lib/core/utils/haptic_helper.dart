import 'package:flutter/services.dart';

/// Haptic feedback helper for consistent haptic responses throughout the app.
class HapticHelper {
  HapticHelper._();

  /// Light impact for general interactions
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact for more significant actions
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact for important actions
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Success feedback (light impact)
  static void success() {
    HapticFeedback.lightImpact();
  }

  /// Error feedback (medium impact for emphasis)
  static void error() {
    HapticFeedback.mediumImpact();
  }

  /// Selection feedback
  static void selection() {
    HapticFeedback.selectionClick();
  }
}
