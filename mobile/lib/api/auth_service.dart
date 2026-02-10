import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../core/utils/error_message_formatter.dart';

/// Auth service for email OTP, Google, and Apple sign-in.
/// Uses access + refresh tokens from new auth endpoints.
class AuthService {
  static const String _base = '${Env.apiBaseUrl}/auth';

  /// Request OTP to email
  Future<RequestOtpResponse> requestOtp({
    required String email,
    String purpose = 'login',
  }) async {
    final res = await http.post(
      Uri.parse('$_base/email/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'purpose': purpose}),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 429) {
      throw AuthException(body['error']?.toString() ?? 'Too many requests');
    }
    if (res.statusCode != 200) {
      throw AuthException(body['error']?.toString() ?? 'Failed to send OTP');
    }
    return RequestOtpResponse.fromJson(body);
  }

  /// Verify OTP and sign in
  Future<AuthTokenResponse> verifyOtp({
    required String email,
    required String code,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/email/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw AuthException(body['error']?.toString() ?? 'Invalid or expired OTP');
    }
    return AuthTokenResponse.fromJson(body);
  }

  /// Sign in with Google ID token
  Future<AuthTokenResponse> signInWithGoogle({
    required String idToken,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    final user = <String, dynamic>{};
    if (email != null) user['email'] = email;
    if (firstName != null || lastName != null) {
      user['name'] = {
        'firstName': firstName ?? '',
        'lastName': lastName ?? '',
      };
    }

    final res = await http.post(
      Uri.parse('$_base/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        if (user.isNotEmpty) 'user': user,
      }),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw AuthException(
          body['error']?.toString() ?? 'Google sign-in failed');
    }
    return AuthTokenResponse.fromJson(body);
  }

  /// Sign in with Apple
  Future<AuthTokenResponse> signInWithApple({
    required String identityToken,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    final user = <String, dynamic>{};
    if (email != null) user['email'] = email;
    if (firstName != null || lastName != null) {
      user['name'] = {
        'firstName': firstName ?? '',
        'lastName': lastName ?? '',
      };
    }

    final res = await http.post(
      Uri.parse('$_base/apple'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identityToken': identityToken,
        if (user.isNotEmpty) 'user': user,
      }),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw AuthException(body['error']?.toString() ?? 'Apple sign-in failed');
    }
    return AuthTokenResponse.fromJson(body);
  }

  /// Refresh access token
  Future<AuthTokenResponse> refresh(String refreshToken) async {
    final res = await http.post(
      Uri.parse('$_base/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw AuthException(
          body['error']?.toString() ?? 'Token refresh failed');
    }
    return AuthTokenResponse.fromJson(body);
  }

  /// Check if email exists (routes to Login or Sign Up)
  Future<CheckEmailResponse> checkEmail(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/check-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));

      Map<String, dynamic>? body;
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>?;
      } catch (_) {
        throw AuthException('Invalid server response (${res.statusCode})');
      }

      if (res.statusCode != 200) {
        throw AuthException(body?['error']?.toString() ?? 'Failed to check email');
      }
      return CheckEmailResponse.fromJson(body ?? {});
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(ErrorMessageFormatter.format(e));
    }
  }

  /// Register with email (creates user, sends OTP)
  Future<void> registerEmail({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/register-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        }),
      ).timeout(const Duration(seconds: 30));

      Map<String, dynamic>? body;
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>?;
      } catch (_) {
        throw AuthException('Invalid server response (${res.statusCode})');
      }

      if (res.statusCode != 200) {
        throw AuthException(body?['error']?.toString() ?? 'Registration failed');
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(ErrorMessageFormatter.format(e));
    }
  }

  /// Verify email OTP after signup
  Future<AuthTokenResponse> verifyEmailSignup({
    required String email,
    required String code,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw AuthException(body['error']?.toString() ?? 'Verification failed');
    }
    return AuthTokenResponse.fromJson(body);
  }

  /// Resend verification OTP
  Future<void> resendVerifyOtp(String email) async {
    final res = await http.post(
      Uri.parse('$_base/resend-verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw AuthException(body['error']?.toString() ?? 'Failed to resend code');
    }
  }

  /// Login with email + password
  Future<AuthTokenResponse> loginEmail({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/login-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw AuthException(body['error']?.toString() ?? 'Invalid credentials');
    }
    return AuthTokenResponse.fromJson(body);
  }

  /// Update profile (phone)
  Future<void> updateProfile(String phoneNumber) async {
    final token = await _getAccessToken();
    if (token == null) throw AuthException('Not authenticated');
    final res = await http.patch(
      Uri.parse('$_base/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'phoneNumber': phoneNumber}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw AuthException(body['error']?.toString() ?? 'Failed to update profile');
    }
  }

  /// Request password reset OTP
  Future<void> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$_base/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw AuthException(body['error']?.toString() ?? 'Failed to send code');
    }
  }

  /// Reset password with OTP
  Future<AuthTokenResponse> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code, 'password': password}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw AuthException(body['error']?.toString() ?? 'Password reset failed');
    }
    return AuthTokenResponse.fromJson(body);
  }

  Future<String?> _getAccessToken() async {
    const storage = FlutterSecureStorage();
    return storage.read(key: 'accessToken');
  }

  /// Logout (revoke refresh token)
  Future<void> logout({
    required String accessToken,
    String? refreshToken,
  }) async {
    await http.post(
      Uri.parse('$_base/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'refreshToken': refreshToken ?? ''}),
    );
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class CheckEmailResponse {
  final bool exists;

  CheckEmailResponse({required this.exists});

  factory CheckEmailResponse.fromJson(Map<String, dynamic> json) =>
      CheckEmailResponse(exists: json['exists'] as bool? ?? false);
}

class RequestOtpResponse {
  final bool success;
  final String message;
  final int expiresIn;

  RequestOtpResponse({
    required this.success,
    required this.message,
    required this.expiresIn,
  });

  factory RequestOtpResponse.fromJson(Map<String, dynamic> json) =>
      RequestOtpResponse(
        success: json['success'] as bool? ?? true,
        message: json['message'] as String? ?? '',
        expiresIn: json['expiresIn'] as int? ?? 300,
      );
}

class AuthTokenResponse {
  final bool success;
  final bool isNewUser;
  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  AuthTokenResponse({
    required this.success,
    required this.isNewUser,
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) =>
      AuthTokenResponse(
        success: json['success'] as bool? ?? true,
        isNewUser: json['isNewUser'] as bool? ?? false,
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class AuthUser {
  final int id;
  final String phoneNumber;
  final String? email;
  final String? stellarAddress;
  final String? createdAt;
  final String? firstName;
  final String? lastName;

  AuthUser({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.stellarAddress,
    this.createdAt,
    this.firstName,
    this.lastName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        phoneNumber: json['phone_number'] as String,
        email: json['email'] as String?,
        stellarAddress: json['stellar_address'] as String?,
        createdAt: json['created_at'] as String?,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
      );
}
