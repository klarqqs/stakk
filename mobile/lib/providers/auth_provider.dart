import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stakk_savings/core/constants/storage_keys.dart';
import 'package:stakk_savings/features/bills/domain/models/bill_models.dart';
import '../api/api_client.dart';
import '../api/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final AuthService _authService = AuthService();

  User? _user;
  User? get user => _user;

  Future<bool> isAuthenticated() => _api.hasToken();

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

  /// Call when API returns session expired – clears state and navigates to login
  Future<void> handleSessionExpired(BuildContext context) async {
    await logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
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

  Future<List<Bank>> getBanks() => _api.getBanks();

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
}
