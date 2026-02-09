/// Sentry configuration for STAKK mobile app.
/// 
/// Set SENTRY_DSN via --dart-define when building:
/// flutter build apk --dart-define=SENTRY_DSN=your_dsn_here
/// 
/// Or use the default DSN below for production builds.
class SentryConfig {
  /// Sentry DSN for error tracking.
  /// Uses environment variable or falls back to default DSN.
  static const String dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: 'https://2225e6ac042734539c8b3f688eb9c3a6@o4510855989297152.ingest.de.sentry.io/4510856011907152',
  );

  /// Whether Sentry is enabled.
  static bool get isEnabled => dsn.isNotEmpty;
}
