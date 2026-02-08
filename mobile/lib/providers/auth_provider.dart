import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stakk_savings/core/constants/storage_keys.dart';
import '../api/api_client.dart';
import '../api/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final AuthService _authService = AuthService();

  User? _user;
  User? get user => _user;

  Future<bool> isAuthenticated() => _api.hasToken();

  /// Legacy: phone + password login
  Future<void> login(String phoneNumber, String password) async {
    final res = await _api.login(
      phoneNumber: phoneNumber,
      password: password,
    );
    await _api.saveToken(res.token);
    _user = res.user;
    notifyListeners();
  }

  /// Legacy: phone + password registration
  Future<void> register(
    String phoneNumber,
    String email,
    String password,
  ) async {
    final res = await _api.register(
      phoneNumber: phoneNumber,
      email: email,
      password: password,
    );
    await _api.saveToken(res.token);
    _user = res.user;
    notifyListeners();
  }

  /// Check if email exists (routes to Login or Sign Up)
  Future<bool> checkEmail(String email) async {
    final res = await _authService.checkEmail(email);
    return res.exists;
  }

  /// Register with email (sends OTP)
  Future<void> registerEmail({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    await _authService.registerEmail(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }

  /// Verify email OTP after signup
  Future<AuthTokenResponse> verifyEmailSignup({
    required String email,
    required String code,
  }) async {
    return _authService.verifyEmailSignup(email: email, code: code);
  }

  /// Resend verification OTP
  Future<void> resendVerifyOtp(String email) async {
    await _authService.resendVerifyOtp(email);
  }

  /// Login with email + password
  Future<AuthTokenResponse> loginEmail({
    required String email,
    required String password,
  }) async {
    return _authService.loginEmail(email: email, password: password);
  }

  /// Update profile (phone)
  Future<void> updateProfile(String phoneNumber) async {
    await _authService.updateProfile(phoneNumber);
  }

  /// Forgot password (sends OTP)
  Future<void> forgotPassword(String email) async {
    await _authService.forgotPassword(email);
  }

  /// Reset password with OTP
  Future<AuthTokenResponse> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    return _authService.resetPassword(
      email: email,
      code: code,
      password: password,
    );
  }

  /// Email OTP: request code
  Future<void> requestEmailOtp(String email, {String purpose = 'login'}) async {
    await _authService.requestOtp(email: email, purpose: purpose);
  }

  /// Save tokens from AuthTokenResponse (used after login, verify, reset)
  Future<void> saveTokensFromAuthResponse(AuthTokenResponse res) async {
    await _api.saveTokens(res.accessToken, res.refreshToken);
    _user = _authUserToUser(res.user);
    notifyListeners();
  }

  /// Email OTP: verify and sign in
  Future<void> signInWithEmailOtp(String email, String code) async {
    final res = await _authService.verifyOtp(email: email, code: code);
    await _api.saveTokens(res.accessToken, res.refreshToken);
    _user = _authUserToUser(res.user);
    notifyListeners();
  }

  /// Google Sign-In
  Future<void> signInWithGoogle(String idToken) async {
    final res = await _authService.signInWithGoogle(idToken);
    await _api.saveTokens(res.accessToken, res.refreshToken);
    _user = _authUserToUser(res.user);
    notifyListeners();
  }

  /// Apple Sign-In
  Future<void> signInWithApple({
    required String identityToken,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    final res = await _authService.signInWithApple(
      identityToken: identityToken,
      email: email,
      firstName: firstName,
      lastName: lastName,
    );
    await _api.saveTokens(res.accessToken, res.refreshToken);
    _user = _authUserToUser(res.user);
    notifyListeners();
  }

  User _authUserToUser(AuthUser a) => User(
        id: a.id,
        phoneNumber: a.phoneNumber,
        email: a.email,
        stellarAddress: a.stellarAddress,
      );

  Future<void> logout() async {
    try {
      final accessToken = await _api.getAccessToken();
      if (accessToken != null) {
        await _authService.logout(
          accessToken: accessToken,
          refreshToken: await _api.getRefreshToken(),
        );
      }
    } catch (_) {}
    await _api.logout();
    await const FlutterSecureStorage().delete(key: StorageKeys.passcode);
    await const FlutterSecureStorage().delete(key: StorageKeys.tempPasscode);
    _user = null;
    notifyListeners();
  }

  Future<WalletBalance> getBalance() => _api.getBalance();

  Future<TransactionsResponse> getTransactions() =>
      _api.getTransactions();

  Future<VirtualAccount> getVirtualAccount() => _api.getVirtualAccount();

  Future<void> submitBvn(String bvn) => _api.submitBvn(bvn);
}
