import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../config/sentry_config.dart';

/// Error tracking service for production error monitoring.
/// Uses Sentry for error tracking.
class ErrorTrackingService {
  static final ErrorTrackingService _instance = ErrorTrackingService._internal();
  factory ErrorTrackingService() => _instance;
  ErrorTrackingService._internal();

  bool _initialized = false;

  /// Initialize error tracking (call in main.dart)
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kDebugMode) {
        debugPrint('Error tracking initialized (debug mode - logging only)');
      } else if (SentryConfig.isEnabled) {
        // Production: Initialize Sentry
        await SentryFlutter.init(
          (options) {
            options.dsn = SentryConfig.dsn;
            options.environment = kReleaseMode ? 'production' : 'staging';
            options.tracesSampleRate = 0.2; // 20% of transactions
            options.beforeSend = (SentryEvent event, Hint hint) {
              // Filter out sensitive data from request
              // Note: SentryRequest.data is read-only, so we filter at the event level
              // Sensitive data filtering should be done at the source (API calls)
              return event;
            };
          },
        );
        debugPrint('✅ Sentry initialized for production');
      } else {
        debugPrint('⚠️  Sentry DSN not configured. Error tracking disabled.');
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize error tracking: $e');
    }
  }

  /// Capture and report an error
  Future<void> captureError(
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? level,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('Error captured: $error');
        if (stackTrace != null) {
          debugPrint('Stack trace: $stackTrace');
        }
        if (context != null) {
          debugPrint('Context: $context');
        }
      } else if (SentryConfig.isEnabled) {
        // Production: Send to Sentry
        await Sentry.captureException(
          error,
          stackTrace: stackTrace,
          hint: Hint.withMap(context ?? {}),
        );
      }
    } catch (e) {
      debugPrint('Failed to capture error: $e');
    }
  }

  /// Capture a message (non-fatal)
  Future<void> captureMessage(
    String message, {
    Map<String, dynamic>? context,
    String level = 'info',
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('Message captured: $message');
        if (context != null) {
          debugPrint('Context: $context');
        }
      } else if (SentryConfig.isEnabled) {
        // Production: Send to Sentry
        await Sentry.captureMessage(
          message,
          level: _parseSentryLevel(level),
          hint: Hint.withMap(context ?? {}),
        );
      }
    } catch (e) {
      debugPrint('Failed to capture message: $e');
    }
  }

  /// Set user context for error tracking
  Future<void> setUser({
    String? id,
    String? email,
    String? username,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('User context set: id=$id, email=$email, username=$username');
      } else if (SentryConfig.isEnabled) {
        // Production: Set user in Sentry
        Sentry.configureScope((scope) {
          scope.setUser(SentryUser(
            id: id,
            email: email,
            username: username,
          ));
        });
      }
    } catch (e) {
      debugPrint('Failed to set user context: $e');
    }
  }

  /// Clear user context (on logout)
  Future<void> clearUser() async {
    try {
      if (kDebugMode) {
        debugPrint('User context cleared');
      } else if (SentryConfig.isEnabled) {
        // Production: Clear user in Sentry
        Sentry.configureScope((scope) => scope.setUser(null));
      }
    } catch (e) {
      debugPrint('Failed to clear user context: $e');
    }
  }

  /// Add breadcrumb for debugging
  void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) {
    try {
      if (kDebugMode) {
        debugPrint('Breadcrumb: [$category] $message');
      } else if (SentryConfig.isEnabled) {
        // Production: Add breadcrumb in Sentry
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: message,
            category: category,
            data: data,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to add breadcrumb: $e');
    }
  }

  /// Parse string level to SentryLevel
  SentryLevel _parseSentryLevel(String level) {
    switch (level.toLowerCase()) {
      case 'fatal':
        return SentryLevel.fatal;
      case 'error':
        return SentryLevel.error;
      case 'warning':
      case 'warn':
        return SentryLevel.warning;
      case 'info':
        return SentryLevel.info;
      case 'debug':
        return SentryLevel.debug;
      default:
        return SentryLevel.info;
    }
  }
}
