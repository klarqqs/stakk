import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stakk_savings/core/constants/storage_keys.dart';
import 'package:stakk_savings/features/bills/domain/models/bill_models.dart';
import '../api/api_client.dart';
import '../api/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/analytics_service.dart';
import '../services/error_tracking_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();

  User? _user;
  User? get user => _user;

  Future<bool> isAuthenticated() => _api.hasToken();

  /// Load user when authenticated (used on app start).
  /// Tries storage first; if missing, fetches via refresh (handles upgrades).
  Future<void> loadUserIfAuthenticated() async {
    if (_user != null) return;
    if (!await isAuthenticated()) return;
    try {
      final json = await _storage.read(key: StorageKeys.userProfile);
      if (json != null && json.isNotEmpty) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        _setUser(User.fromJson(map));
        return;
      }
      final ref = await _api.getRefreshToken();
      if (ref == null) return;
      final res = await _authService.refresh(ref);
      await _api.saveTokens(res.accessToken, res.refreshToken);
      _setUser(_authUserToUser(res.user));
    } catch (_) {}
  }

  void _setUser(User user) {
    // Only update if user actually changed
    if (_user?.id == user.id && _user?.email == user.email) {
      return; // Skip unnecessary updates
    }
    
    _user = user;
    _storage.write(
      key: StorageKeys.userProfile,
      value: jsonEncode(user.toJson()),
    );
    
    // Set user context for error tracking and analytics
    ErrorTrackingService().setUser(
      id: user.id.toString(),
      email: user.email,
      username: '${user.firstName} ${user.lastName}'.trim(),
    );
    
    AnalyticsService().setUserProperty(
      userId: user.id.toString(),
      email: user.email,
      name: '${user.firstName} ${user.lastName}'.trim(),
    );
    
    // Initialize FCM after user is set
    _initializeFCM();
    
    // Notify listeners after all async operations are set up
    notifyListeners();
  }

  Future<void> _initializeFCM() async {
    try {
      await FCMService().initialize();
    } catch (e) {
      debugPrint('Failed to initialize FCM: $e');
      ErrorTrackingService().captureError(e, context: {'service': 'FCM'});
    }
  }

  void _clearUserStorage() => _storage.delete(key: StorageKeys.userProfile);

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
    try {
      AnalyticsService().addBreadcrumb(
        message: 'Email registration initiated',
        category: 'auth',
        data: {'email': email},
      );
      await _authService.registerEmail(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      AnalyticsService().logSignUp(method: 'email');
    } catch (e) {
      ErrorTrackingService().captureError(e, context: {'method': 'email_signup'});
      AnalyticsService().logError(error: e.toString(), screen: 'signup');
      rethrow;
    }
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
    try {
      AnalyticsService().addBreadcrumb(
        message: 'Email login initiated',
        category: 'auth',
      );
      final res = await _authService.loginEmail(email: email, password: password);
      AnalyticsService().logLogin(method: 'email');
      return res;
    } catch (e) {
      ErrorTrackingService().captureError(e, context: {'method': 'email_login'});
      AnalyticsService().logError(error: e.toString(), screen: 'login');
      rethrow;
    }
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
    _setUser(_authUserToUser(res.user));
  }

  /// Email OTP: verify and sign in
  Future<void> signInWithEmailOtp(String email, String code) async {
    final res = await _authService.verifyOtp(email: email, code: code);
    await _api.saveTokens(res.accessToken, res.refreshToken);
    _setUser(_authUserToUser(res.user));
  }

  /// Google Sign-In
  Future<void> signInWithGoogle(String idToken) async {
    try {
      AnalyticsService().addBreadcrumb(
        message: 'Google sign-in initiated',
        category: 'auth',
      );
      final res = await _authService.signInWithGoogle(idToken);
      await _api.saveTokens(res.accessToken, res.refreshToken);
      _setUser(_authUserToUser(res.user));
      AnalyticsService().logLogin(method: 'google');
    } catch (e) {
      ErrorTrackingService().captureError(e, context: {'method': 'google_signin'});
      AnalyticsService().logError(error: e.toString(), screen: 'login');
      rethrow;
    }
  }

  /// Apple Sign-In
  Future<void> signInWithApple({
    required String identityToken,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      AnalyticsService().addBreadcrumb(
        message: 'Apple sign-in initiated',
        category: 'auth',
      );
      final res = await _authService.signInWithApple(
        identityToken: identityToken,
        email: email,
        firstName: firstName,
        lastName: lastName,
      );
      await _api.saveTokens(res.accessToken, res.refreshToken);
      _setUser(_authUserToUser(res.user));
      AnalyticsService().logLogin(method: 'apple');
    } catch (e) {
      ErrorTrackingService().captureError(e, context: {'method': 'apple_signin'});
      AnalyticsService().logError(error: e.toString(), screen: 'login');
      rethrow;
    }
  }

  User _authUserToUser(AuthUser a) => User(
        id: a.id,
        phoneNumber: a.phoneNumber,
        email: a.email,
        stellarAddress: a.stellarAddress,
        firstName: a.firstName,
        lastName: a.lastName,
      );

  /// Call when API returns session expired – clears state and navigates to login
  Future<void> handleSessionExpired(BuildContext context) async {
    try {
      ErrorTrackingService().captureMessage(
        'Session expired - handling logout',
        context: {'screen': 'auth_provider'},
      );
      await logout();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
      }
    } catch (e) {
      ErrorTrackingService().captureError(
        e,
        context: {'action': 'handleSessionExpired'},
      );
      // Still navigate to login even if logout fails
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
      }
    }
  }

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
    // Clear FCM token
    try {
      await FCMService().deleteToken();
    } catch (_) {}
    
    // Clear analytics and error tracking user context
    AnalyticsService().setUserProperty();
    ErrorTrackingService().clearUser();
    
    await _api.logout();
    _clearUserStorage();
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

  Future<List<Bank>> getBanks() => _api.getBanks();

  Future<String> resolveBankAccount({
    required String accountNumber,
    required String bankCode,
  }) =>
      _api.resolveBankAccount(accountNumber: accountNumber, bankCode: bankCode);

  Future<WithdrawToBankResult> withdrawToBank({
    required String accountNumber,
    required String bankCode,
    required double amountNGN,
  }) =>
      _api.withdrawToBank(
        accountNumber: accountNumber,
        bankCode: bankCode,
        amountNGN: amountNGN,
      );

  Future<WithdrawToUSDCResult> withdrawToUSDC({
    required String stellarAddress,
    required double amountUSDC,
  }) =>
      _api.withdrawToUSDC(
        stellarAddress: stellarAddress,
        amountUSDC: amountUSDC,
      );

  Future<List<BillCategory>> getBillCategories() => _api.getBillCategories();
  Future<List<BillCategoryModel>> getBillTopCategories() => _api.getBillTopCategories();
  Future<List<BillProviderModel>> getBillProviders(String categoryCode) => _api.getBillProviders(categoryCode);
  Future<List<BillProductModel>> getBillProducts(String billerCode) => _api.getBillProducts(billerCode);

  Future<BillValidation> validateBill({
    required String itemCode,
    required String code,
    required String customer,
  }) =>
      _api.validateBill(itemCode: itemCode, code: code, customer: customer);

  Future<BillPaymentResult> payBill({
    required String customer,
    required double amount,
    required String billerCode,
    required String itemCode,
  }) =>
      _api.payBill(customer: customer, amount: amount, billerCode: billerCode, itemCode: itemCode);

  Future<Map<String, dynamic>> getBillStatus(String reference) =>
      _api.getBillStatus(reference);

  Future<BlendApyResponse> getBlendApy() => _api.getBlendApy();
  Future<BlendEarningsResponse> getBlendEarnings() => _api.getBlendEarnings();
  Future<BlendEnableResult> blendEnable(double amount) => _api.blendEnable(amount);
  Future<BlendDisableResult> blendDisable(double amount) => _api.blendDisable(amount);

  Future<P2pSearchResult> p2pSearch(String query) => _api.p2pSearch(query);
  Future<P2pSendResult> p2pSend({required String receiver, required double amount, String? note}) =>
      _api.p2pSend(receiver: receiver, amount: amount, note: note);
  Future<List<P2pTransfer>> p2pGetHistory() => _api.p2pGetHistory();

  Future<List<SavingsGoal>> goalsGetAll() => _api.goalsGetAll();
  Future<GoalDetail> goalsGetOne(int id) => _api.goalsGetOne(id);
  Future<SavingsGoal> goalsCreate(Map<String, dynamic> data) => _api.goalsCreate(data);
  Future<SavingsGoal> goalsContribute(int id, double amount) => _api.goalsContribute(id, amount);
  Future<SavingsGoal> goalsWithdraw(int id, double amount) => _api.goalsWithdraw(id, amount);
  Future<void> goalsDelete(int id) => _api.goalsDelete(id);

  Future<List<LockedSaving>> lockedGetAll() => _api.lockedGetAll();
  Future<List<Map<String, dynamic>>> lockedGetRates() => _api.lockedGetRates();
  Future<LockedSaving> lockedCreate(double amount, int duration, {bool autoRenew = false}) =>
      _api.lockedCreate(amount, duration, autoRenew: autoRenew);
  Future<LockedSaving> lockedWithdraw(int id) => _api.lockedWithdraw(id);

  Future<String> referralsGetCode() => _api.referralsGetCode();
  Future<ReferralStats> referralsGetMine() => _api.referralsGetMine();
  Future<List<Map<String, dynamic>>> referralsGetLeaderboard() => _api.referralsGetLeaderboard();

  Future<NotificationsResponse> notificationsGet({bool unreadOnly = false}) =>
      _api.notificationsGet(unreadOnly: unreadOnly);
  Future<int> notificationsGetUnreadCount() => _api.notificationsGetUnreadCount();
  Future<void> notificationsMarkRead(int id) => _api.notificationsMarkRead(id);
  Future<void> notificationsMarkAllRead() => _api.notificationsMarkAllRead();

  Future<TransparencyStats> transparencyGetStats() => _api.transparencyGetStats();
}
