import 'package:flutter/foundation.dart';

/// Environment configuration
class Env {
  /// Debug: localhost:3001 (backend default). Android emulator: use http://10.0.2.2:3001/api
  static const String apiBaseUrl = kDebugMode
      ? 'http://localhost:3001/api'
      : 'https://stakk-production.up.railway.app/api';
}
