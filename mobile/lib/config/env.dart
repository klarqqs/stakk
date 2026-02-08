import 'package:flutter/foundation.dart';

/// Environment configuration
class Env {
  static const String apiBaseUrl = kDebugMode
      ? 'http://localhost:3000/api' // Android emulator: http://10.0.2.2:3000/api
      : 'https://stakk-production.up.railway.app/api';
}
