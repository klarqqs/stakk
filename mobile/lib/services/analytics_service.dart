import 'package:flutter/foundation.dart';

/// Analytics service for tracking user events and app usage.
/// Supports Firebase Analytics or custom analytics.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _initialized = false;
  bool _enabled = true;

  /// Initialize analytics (call in main.dart)
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kDebugMode) {
        debugPrint('Analytics initialized (debug mode - logging only)');
      } else {
        // Production: Initialize Firebase Analytics
        // Uncomment when ready:
        // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
        debugPrint('Analytics ready (configure Firebase Analytics for production)');
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize analytics: $e');
    }
  }

  /// Enable or disable analytics
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (kDebugMode) {
      debugPrint('Analytics ${enabled ? "enabled" : "disabled"}');
    }
  }

  /// Log a custom event
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!_enabled) return;

    try {
      if (kDebugMode) {
        debugPrint('Analytics Event: $name');
        if (parameters != null) {
          debugPrint('Parameters: $parameters');
        }
      } else {
        // Production: Log to Firebase Analytics
        // await FirebaseAnalytics.instance.logEvent(
        //   name: name,
        //   parameters: parameters,
        // );
      }
    } catch (e) {
      debugPrint('Failed to log event: $e');
    }
  }

  /// Set user properties
  Future<void> setUserProperty({
    String? userId,
    String? email,
    String? name,
  }) async {
    if (!_enabled) return;

    try {
      if (kDebugMode) {
        debugPrint('User properties set: userId=$userId, email=$email, name=$name');
      } else {
        // Production: Set user properties in Firebase Analytics
        // if (userId != null) {
        //   await FirebaseAnalytics.instance.setUserId(id: userId);
        // }
        // if (email != null) {
        //   await FirebaseAnalytics.instance.setUserProperty(name: 'email', value: email);
        // }
        // if (name != null) {
        //   await FirebaseAnalytics.instance.setUserProperty(name: 'name', value: name);
        // }
      }
    } catch (e) {
      debugPrint('Failed to set user properties: $e');
    }
  }

  /// Track screen view
  Future<void> logScreenView(String screenName) async {
    if (!_enabled) return;

    try {
      await logEvent('screen_view', parameters: {'screen_name': screenName});
    } catch (e) {
      debugPrint('Failed to log screen view: $e');
    }
  }

  /// Add breadcrumb for debugging (for analytics context)
  void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) {
    if (!_enabled) return;

    try {
      if (kDebugMode) {
        debugPrint('Analytics Breadcrumb: [$category] $message');
        if (data != null) {
          debugPrint('Data: $data');
        }
      } else {
        // Production: Log as event for analytics tracking
        logEvent('breadcrumb', parameters: {
          'message': message,
          if (category != null) 'category': category,
          ...?data,
        });
      }
    } catch (e) {
      debugPrint('Failed to add breadcrumb: $e');
    }
  }

  // Predefined event methods for common actions

  /// Track signup
  Future<void> logSignUp({String? method}) async {
    await logEvent('sign_up', parameters: {
      if (method != null) 'method': method,
    });
  }

  /// Track login
  Future<void> logLogin({String? method}) async {
    await logEvent('login', parameters: {
      if (method != null) 'method': method,
    });
  }

  /// Track wallet funding
  Future<void> logWalletFunded({required double amount, String? method}) async {
    await logEvent('wallet_funded', parameters: {
      'amount': amount,
      if (method != null) 'method': method,
    });
  }

  /// Track P2P transfer
  Future<void> logP2PTransfer({required double amount}) async {
    await logEvent('p2p_transfer', parameters: {
      'amount': amount,
    });
  }

  /// Track bill payment
  Future<void> logBillPayment({
    required String category,
    required double amount,
  }) async {
    await logEvent('bill_payment', parameters: {
      'category': category,
      'amount': amount,
    });
  }

  /// Track savings goal created
  Future<void> logGoalCreated({required double targetAmount}) async {
    await logEvent('goal_created', parameters: {
      'target_amount': targetAmount,
    });
  }

  /// Track savings goal achieved
  Future<void> logGoalAchieved({required double amount}) async {
    await logEvent('goal_achieved', parameters: {
      'amount': amount,
    });
  }

  /// Track withdrawal
  Future<void> logWithdrawal({required double amount, String? type}) async {
    await logEvent('withdrawal', parameters: {
      'amount': amount,
      if (type != null) 'type': type,
    });
  }

  /// Track error
  Future<void> logError({
    required String error,
    String? screen,
    Map<String, dynamic>? context,
  }) async {
    await logEvent('error_occurred', parameters: {
      'error': error,
      if (screen != null) 'screen': screen,
      ...?context,
    });
  }
}
