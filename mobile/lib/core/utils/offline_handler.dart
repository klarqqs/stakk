import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'error_message_formatter.dart';

/// Handles offline/online state and provides utilities for connectivity checks.
class OfflineHandler {
  static final OfflineHandler _instance = OfflineHandler._internal();
  factory OfflineHandler() => _instance;
  OfflineHandler._internal();

  bool _isOnline = true;
  final Connectivity _connectivity = Connectivity();

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isOnline = _hasConnection(result);

      // Listen for connectivity changes
      _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline = _hasConnection(results);

        if (wasOnline != _isOnline) {
          debugPrint('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize connectivity monitoring: $e');
    }
  }

  /// Check if device has internet connection
  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  /// Get current online status
  bool get isOnline => _isOnline;

  /// Check connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = _hasConnection(result);
      return _isOnline;
    } catch (e) {
      debugPrint('Failed to check connectivity: $e');
      return false;
    }
  }

  /// Get a user-friendly error message for network errors
  /// 
  /// Deprecated: Use ErrorMessageFormatter.format() instead for consistent error messages.
  @Deprecated('Use ErrorMessageFormatter.format() instead')
  static String getNetworkErrorMessage(dynamic error) {
    return ErrorMessageFormatter.format(error);
  }
}
