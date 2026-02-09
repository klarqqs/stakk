import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../config/env.dart';

/// Service for checking app version and forcing updates.
class AppVersionService {
  static final AppVersionService _instance = AppVersionService._internal();
  factory AppVersionService() => _instance;
  AppVersionService._internal();

  PackageInfo? _packageInfo;
  String? _currentVersion;
  String? _minimumVersion;
  bool _forceUpdate = false;

  /// Initialize and check app version
  Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = _packageInfo?.version;
      debugPrint('App version: $_currentVersion (build ${_packageInfo?.buildNumber})');
      
      // Check for updates (optional - can be disabled)
      if (kReleaseMode) {
        await _checkForUpdates();
      }
    } catch (e) {
      debugPrint('Failed to initialize app version service: $e');
    }
  }

  /// Get current app version
  String? get currentVersion => _currentVersion;

  /// Get build number
  String? get buildNumber => _packageInfo?.buildNumber;

  /// Check if force update is required
  bool get requiresForceUpdate => _forceUpdate;

  /// Get minimum required version
  String? get minimumVersion => _minimumVersion;

  /// Check for app updates from backend
  Future<void> _checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/api/app/version-check'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _minimumVersion = data['minimumVersion'] as String?;
        _forceUpdate = data['forceUpdate'] as bool? ?? false;

        if (_minimumVersion != null && _currentVersion != null) {
          _forceUpdate = _compareVersions(_currentVersion!, _minimumVersion!) < 0;
        }

        if (_forceUpdate) {
          debugPrint('⚠️ Force update required. Current: $_currentVersion, Minimum: $_minimumVersion');
        }
      }
    } catch (e) {
      // Silently fail - don't block app if version check fails
      debugPrint('Version check failed (non-critical): $e');
    }
  }

  /// Compare two version strings (e.g., "1.2.3")
  /// Returns: -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).toList();
    final parts2 = v2.split('.').map(int.tryParse).toList();

    final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final part1 = i < parts1.length ? (parts1[i] ?? 0) : 0;
      final part2 = i < parts2.length ? (parts2[i] ?? 0) : 0;

      if (part1 < part2) return -1;
      if (part1 > part2) return 1;
    }

    return 0;
  }

  /// Manually check for updates (call when needed)
  Future<void> checkForUpdates() async {
    await _checkForUpdates();
  }

  /// Get app store URLs
  Future<Map<String, String>> getAppStoreUrls() async {
    try {
      // Try to fetch from backend first
      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}/api/app/version-check'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final updateUrl = data['updateUrl'] as Map<String, dynamic>?;
        if (updateUrl != null) {
          final iosUrl = updateUrl['ios'] as String?;
          final androidUrl = updateUrl['android'] as String?;
          
          // Only use URLs if they're not null/empty
          return {
            if (iosUrl != null && iosUrl.isNotEmpty) 'ios': iosUrl,
            if (androidUrl != null && androidUrl.isNotEmpty) 'android': androidUrl,
          };
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch app store URLs: $e');
    }

    // Fallback to defaults (only if configured)
    final urls = <String, String>{};
    if (_defaultIosUrl.isNotEmpty) urls['ios'] = _defaultIosUrl;
    if (_defaultAndroidUrl.isNotEmpty) urls['android'] = _defaultAndroidUrl;
    return urls;
  }

  // Default URLs - update these AFTER apps are published to stores
  static const String _defaultIosUrl = ''; // Update after App Store approval
  static const String _defaultAndroidUrl = ''; // Update after Play Store approval
}
