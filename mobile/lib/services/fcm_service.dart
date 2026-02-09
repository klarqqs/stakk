import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';

/// Firebase Cloud Messaging service for push notifications.
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _currentToken;

  /// Initialize FCM and request permissions.
  Future<void> initialize() async {
    try {
      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('FCM: User granted permission');
        
        // Get FCM token
        await _getToken();
        
        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _currentToken = newToken;
          _registerToken(newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background message taps (when app is in background/terminated)
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);
      } else {
        debugPrint('FCM: User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('FCM initialization error: $e');
    }
  }

  /// Get current FCM token.
  Future<String?> getToken() async {
    if (_currentToken == null) {
      await _getToken();
    }
    return _currentToken;
  }

  Future<void> _getToken() async {
    try {
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        await _registerToken(_currentToken!);
      }
    } catch (e) {
      debugPrint('FCM: Failed to get token: $e');
    }
  }

  /// Register FCM token with backend.
  Future<void> _registerToken(String token) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await ApiClient().notificationsRegisterDevice(
        token: token,
        platform: platform,
      );
      debugPrint('FCM: Token registered successfully');
    } catch (e) {
      debugPrint('FCM: Failed to register token: $e');
    }
  }

  /// Handle foreground messages (when app is open).
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM: Foreground message received: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    
    // You can show a local notification or update UI here
    // For now, we'll rely on the app polling for notifications
  }

  /// Handle notification tap when app is opened from background/terminated state.
  void _handleMessageOpened(RemoteMessage message) {
    debugPrint('FCM: Notification opened: ${message.messageId}');
    debugPrint('Data: ${message.data}');
    
    // Handle deep linking based on notification data
    // Example: Navigate to specific screen based on notification type
    // This will be handled by the app's navigation system
  }

  /// Delete device token (call on logout).
  Future<void> deleteToken() async {
    try {
      if (_currentToken != null) {
        await ApiClient().notificationsDeleteDevice(token: _currentToken!);
        await _messaging.deleteToken();
        _currentToken = null;
        debugPrint('FCM: Token deleted successfully');
      }
    } catch (e) {
      debugPrint('FCM: Failed to delete token: $e');
    }
  }
}

/// Top-level function for handling background messages (must be top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM: Background message received: ${message.messageId}');
  // Handle background message processing here if needed
}
