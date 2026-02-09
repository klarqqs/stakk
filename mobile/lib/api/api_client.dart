import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../features/bills/domain/models/bill_models.dart';
import '../core/utils/offline_handler.dart';
import '../core/utils/error_message_formatter.dart';
import '../services/error_tracking_service.dart';
import 'auth_service.dart';

class ApiClient {
  final _storage = const FlutterSecureStorage();
  final _authService = AuthService();

  /// Set at app startup to auto-logout and navigate to login when session expires.
  static void Function()? onSessionExpired;

  Never _handleSessionExpired() {
    onSessionExpired?.call();
    throw ApiException('Session expired');
  }

  Future<String?> _getAccessToken() async {
    final access = await _storage.read(key: 'accessToken');
    if (access != null) return access;
    return _storage.read(key: 'token');
  }

  Future<String?> _getRefreshToken() => _storage.read(key: 'refreshToken');

  Future<void> _setToken(String token) =>
      _storage.write(key: 'token', value: token);

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }

  Future<String?> _tryRefresh() async {
    final ref = await _getRefreshToken();
    if (ref == null) return null;
    try {
      final res = await _authService.refresh(ref);
      await saveTokens(res.accessToken, res.refreshToken);
      return res.accessToken;
    } catch (_) {
      await _clearTokens();
      return null;
    }
  }

  Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await _getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// 401 = no token, 403 = invalid/expired token (backend auth middleware)
  bool _isAuthError(int? code) => code == 401 || code == 403;

  Future<http.Response> _requestWithRefresh(
    Future<http.Response> Function() fn,
  ) async {
    // Check connectivity before making request
    final isOnline = await OfflineHandler().checkConnectivity();
    if (!isOnline) {
      throw ApiException(ErrorMessageFormatter.format('No internet connection'));
    }

    try {
      var res = await fn();
      if (_isAuthError(res.statusCode)) {
        final newAccess = await _tryRefresh();
        if (newAccess != null) {
          res = await fn();
        }
      }
      return res;
    } catch (e) {
      // Track network errors
      ErrorTrackingService().captureError(
        e,
        context: {'endpoint': 'api_request'},
      );
      
      // Provide user-friendly error message
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(ErrorMessageFormatter.format(e));
    }
  }

  Future<WalletBalance> getBalance() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/wallet/balance'),
          headers: await _headers(withAuth: true),
        ));

    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      throw ApiException('Failed to fetch balance');
    }
    return WalletBalance.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<TransactionsResponse> getTransactions() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/wallet/transactions'),
          headers: await _headers(withAuth: true),
        ));

    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      throw ApiException('Failed to fetch transactions');
    }
    return TransactionsResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<VirtualAccount> getVirtualAccount() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/wallet/virtual-account'),
          headers: await _headers(withAuth: true),
        ));

    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      final errorMsg = body?['error']?.toString();
      throw ApiException(errorMsg != null 
          ? ErrorMessageFormatter.formatApiException(errorMsg)
          : 'Unable to fetch virtual account. Please try again.');
    }
    return VirtualAccount.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  /// Get list of Nigerian banks for withdrawals
  Future<List<Bank>> getBanks() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/withdrawal/banks'),
          headers: await _headers(withAuth: true),
        ));

    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      throw ApiException('Failed to fetch banks');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['banks'] as List<dynamic>? ?? [];
    return list.map((e) => Bank.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Resolve bank account to fetch account holder name (validate before withdrawal)
  Future<String> resolveBankAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/withdrawal/resolve-account'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({
            'accountNumber': accountNumber,
            'bankCode': bankCode,
          }),
        ));

    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Account resolution failed');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['accountName'] as String? ?? 'Unknown';
  }

  /// Withdraw USDC to NGN bank account
  Future<WithdrawToBankResult> withdrawToBank({
    required String accountNumber,
    required String bankCode,
    required double amountNGN,
  }) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/withdrawal/bank'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({
            'accountNumber': accountNumber,
            'bankCode': bankCode,
            'amountNGN': amountNGN,
          }),
        ));

    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Withdrawal failed');
    }
    return WithdrawToBankResult.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  /// Withdraw USDC to another Stellar wallet
  Future<WithdrawToUSDCResult> withdrawToUSDC({
    required String stellarAddress,
    required double amountUSDC,
  }) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/withdrawal/usdc'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({
            'stellarAddress': stellarAddress,
            'amountUSDC': amountUSDC,
          }),
        ));

    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Withdrawal failed');
    }
    return WithdrawToUSDCResult.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  /// Get top-level bill categories (Airtime, Data, Electricity, TV Cable, etc.)
  Future<List<BillCategoryModel>> getBillTopCategories() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/bills/categories/top'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to fetch categories');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['categories'] as List<dynamic>? ?? [];
    return list.map((e) => BillCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get providers for a category (e.g. MTN, Glo for Airtime)
  Future<List<BillProviderModel>> getBillProviders(String categoryCode) async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/bills/categories/${Uri.encodeComponent(categoryCode)}/providers'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to fetch providers');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['providers'] as List<dynamic>? ?? [];
    return list.map((e) => BillProviderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get products for a provider (e.g. data bundles, DSTV plans)
  Future<List<BillProductModel>> getBillProducts(String billerCode) async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/bills/providers/${Uri.encodeComponent(billerCode)}/products'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to fetch products');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['products'] as List<dynamic>? ?? [];
    return list.map((e) => BillProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get bill payment categories (legacy flat list)
  Future<List<BillCategory>> getBillCategories() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/bills/categories'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to fetch bill categories');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['categories'] as List<dynamic>? ?? [];
    return list.map((e) => BillCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Validate bill customer (meter, smartcard, phone) before payment
  Future<BillValidation> validateBill({
    required String itemCode,
    required String code,
    required String customer,
  }) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/bills/validate'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({
            'item_code': itemCode,
            'code': code,
            'customer': customer,
          }),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Validation failed');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return BillValidation.fromJson(body['validation'] as Map<String, dynamic>);
  }

  /// Pay bill (airtime, data, DSTV, electricity)
  Future<BillPaymentResult> payBill({
    required String customer,
    required double amount,
    required String billerCode,
    required String itemCode,
  }) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/bills/pay'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({
            'customer': customer,
            'amount': amount,
            'biller_code': billerCode,
            'item_code': itemCode,
          }),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Bill payment failed');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return BillPaymentResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Get bill payment status by reference
  Future<Map<String, dynamic>> getBillStatus(String reference) async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/bills/status/${Uri.encodeComponent(reference)}'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to fetch status');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['status'] as Map<String, dynamic>? ?? {};
  }

  /// Submit BVN for permanent deposit account (required before getVirtualAccount)
  Future<void> submitBvn(String bvn) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/wallet/bvn'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({'bvn': bvn.trim()}),
        ));

    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to save BVN');
    }
  }

  /// Blend USDC Yield - get current APY
  Future<BlendApyResponse> getBlendApy() async {
    final res = await http.get(
      Uri.parse('${Env.apiBaseUrl}/blend/apy'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to fetch APY');
    }
    return BlendApyResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  /// Blend - get user earnings
  Future<BlendEarningsResponse> getBlendEarnings() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/blend/earnings'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to fetch earnings');
    }
    return BlendEarningsResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  /// Blend - enable earning (deposit USDC to Blend)
  Future<BlendEnableResult> blendEnable(double amount) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/blend/enable'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({'amount': amount}),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to enable earning');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return BlendEnableResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Blend - disable earning (withdraw USDC from Blend)
  /// P2P - search user by phone or email
  Future<P2pSearchResult> p2pSearch(String query) async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/p2p/search?query=${Uri.encodeComponent(query)}'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode == 404) {
      throw ApiException('User not found');
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Search failed');
    }
    return P2pSearchResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// P2P - send money to user
  Future<P2pSendResult> p2pSend({required String receiver, required double amount, String? note}) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/p2p/send'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({'receiver': receiver, 'amount': amount, if (note != null) 'note': note}),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Transfer failed');
    }
    return P2pSendResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// P2P - get transfer history
  Future<List<P2pTransfer>> p2pGetHistory() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/p2p/history'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to fetch history');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['transfers'] as List<dynamic>? ?? [];
    return list.map((e) => P2pTransfer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BlendDisableResult> blendDisable(double amount) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/blend/disable'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({'amount': amount}),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to disable earning');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return BlendDisableResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> saveToken(String token) => _setToken(token);

  Future<void> logout() => _clearTokens();

  // Goals
  Future<List<SavingsGoal>> goalsGetAll() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/goals'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) throw ApiException('Failed to fetch goals');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['goals'] as List<dynamic>? ?? [];
    return list.map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GoalDetail> goalsGetOne(int id) async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/goals/$id'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) throw ApiException('Failed to fetch goal');
    return GoalDetail.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<SavingsGoal> goalsCreate(Map<String, dynamic> data) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/goals'),
          headers: await _headers(withAuth: true),
          body: jsonEncode(data),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to create goal');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return SavingsGoal.fromJson(body['goal'] as Map<String, dynamic>);
  }

  Future<SavingsGoal> goalsContribute(int id, double amount) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/goals/$id/contribute'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({'amount': amount}),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to contribute');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return SavingsGoal.fromJson(body['goal'] as Map<String, dynamic>);
  }

  Future<SavingsGoal> goalsWithdraw(int id, double amount) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/goals/$id/withdraw'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({'amount': amount}),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to withdraw');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return SavingsGoal.fromJson(body['goal'] as Map<String, dynamic>);
  }

  Future<void> goalsDelete(int id) async {
    final res = await _requestWithRefresh(() async => http.delete(
          Uri.parse('${Env.apiBaseUrl}/goals/$id'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to delete');
    }
  }

  // Locked savings
  Future<List<LockedSaving>> lockedGetAll() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/locked'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) throw ApiException('Failed to fetch locked savings');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['locks'] as List<dynamic>? ?? [];
    return list.map((e) => LockedSaving.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> lockedGetRates() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/locked/rates'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) throw ApiException('Failed to fetch rates');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['rates'] as List<dynamic>? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<LockedSaving> lockedCreate(double amount, int duration, {bool autoRenew = false}) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/locked'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({'amount': amount, 'duration': duration, 'autoRenew': autoRenew}),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to lock funds');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return LockedSaving.fromJson(body['lock'] as Map<String, dynamic>);
  }

  Future<LockedSaving> lockedWithdraw(int id) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/locked/$id/withdraw'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to withdraw');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return LockedSaving.fromJson(body['lock'] as Map<String, dynamic>);
  }

  // Referrals
  Future<String> referralsGetCode() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/referrals/code'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) throw ApiException('Failed to get code');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['code'] as String? ?? '';
  }

  Future<ReferralStats> referralsGetMine() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/referrals/mine'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) throw ApiException('Failed to fetch referrals');
    return ReferralStats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> referralsGetLeaderboard() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/referrals/leaderboard'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) throw ApiException('Failed to fetch leaderboard');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['leaderboard'] as List<dynamic>? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // Notifications (no auth for public transparency)
  Future<NotificationsResponse> notificationsGet({bool unreadOnly = false}) async {
    final uri = Uri.parse('${Env.apiBaseUrl}/notifications').replace(
      queryParameters: unreadOnly ? {'unreadOnly': 'true'} : null,
    );
    final res = await _requestWithRefresh(() async => http.get(uri, headers: await _headers(withAuth: true)));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) throw ApiException('Failed to fetch notifications');
    return NotificationsResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<int> notificationsGetUnreadCount() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/notifications/unread-count'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
    if (res.statusCode != 200) return 0;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['count'] as int? ?? 0;
  }

  Future<void> notificationsMarkRead(int id) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/notifications/$id/read'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
  }

  Future<void> notificationsMarkAllRead() async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/notifications/read-all'),
          headers: await _headers(withAuth: true),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
  }

  // Device token registration for FCM
  Future<void> notificationsRegisterDevice({
    required String token,
    required String platform,
  }) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/notifications/register-device'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({
            'token': token,
            'platform': platform,
          }),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
  }

  Future<void> notificationsDeleteDevice({required String token}) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/notifications/delete-device'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({'token': token}),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      _handleSessionExpired();
    }
  }

  // Transparency (public)
  Future<TransparencyStats> transparencyGetStats() async {
    final res = await http.get(Uri.parse('${Env.apiBaseUrl}/transparency/stats'));
    if (res.statusCode != 200) throw ApiException('Failed to fetch stats');
    return TransparencyStats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<bool> hasToken() async => (await _getAccessToken()) != null;

  Future<String?> getAccessToken() => _getAccessToken();
  Future<String?> getRefreshToken() => _getRefreshToken();
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class User {
  final int id;
  final String phoneNumber;
  final String? email;
  final String? stellarAddress;
  final String? firstName;
  final String? lastName;

  User({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.stellarAddress,
    this.firstName,
    this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        phoneNumber: json['phone_number'] as String,
        email: json['email'] as String?,
        stellarAddress: json['stellar_address'] as String?,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone_number': phoneNumber,
        'email': email,
        'stellar_address': stellarAddress,
        'first_name': firstName,
        'last_name': lastName,
      };
}

class WalletBalance {
  final double usdc;
  final String? stellarAddress;

  WalletBalance({required this.usdc, this.stellarAddress});

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    final db = json['database_balance'] as Map<String, dynamic>?;
    final usdc = (db?['usdc'] ?? 0.0);
    return WalletBalance(
      usdc: (usdc is int) ? usdc.toDouble() : (usdc as num).toDouble(),
      stellarAddress: json['stellar_address'] as String?,
    );
  }
}

class TransactionsResponse {
  final List<Transaction> transactions;

  TransactionsResponse({required this.transactions});

  factory TransactionsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['transactions'] as List<dynamic>? ?? [];
    return TransactionsResponse(
      transactions: list
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Transaction {
  final int id;
  final String? type;
  final num? amountNaira;
  final num? amountUsdc;
  final String? status;
  final String? createdAt;

  Transaction({
    required this.id,
    this.type,
    this.amountNaira,
    this.amountUsdc,
    this.status,
    this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as int,
        type: json['type'] as String?,
        amountNaira: json['amount_naira'] as num?,
        amountUsdc: json['amount_usdc'] as num?,
        status: json['status'] as String?,
        createdAt: json['created_at'] as String?,
      );

  double get displayAmount => (amountUsdc ?? amountNaira ?? 0).toDouble();
}

class VirtualAccount {
  final String accountNumber;
  final String accountName;
  final String bankName;

  VirtualAccount({
    required this.accountNumber,
    required this.accountName,
    required this.bankName,
  });

  factory VirtualAccount.fromJson(Map<String, dynamic> json) => VirtualAccount(
        accountNumber: json['account_number'] as String? ?? '',
        accountName: json['account_name'] as String? ?? '',
        bankName: json['bank_name'] as String? ?? '',
      );
}

class Bank {
  final int id;
  final String code;
  final String name;

  Bank({required this.id, required this.code, required this.name});

  factory Bank.fromJson(Map<String, dynamic> json) => Bank(
        id: json['id'] as int? ?? 0,
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

class WithdrawToBankResult {
  final String message;
  final String accountName;
  final double amountNGN;
  final double usdcDeducted;
  final String reference;

  WithdrawToBankResult({
    required this.message,
    required this.accountName,
    required this.amountNGN,
    required this.usdcDeducted,
    required this.reference,
  });

  factory WithdrawToBankResult.fromJson(Map<String, dynamic> json) =>
      WithdrawToBankResult(
        message: json['message'] as String? ?? '',
        accountName: json['accountName'] as String? ?? '',
        amountNGN: (json['amountNGN'] as num?)?.toDouble() ?? 0,
        usdcDeducted: (json['usdcDeducted'] as num?)?.toDouble() ?? 0,
        reference: json['reference'] as String? ?? '',
      );
}

class WithdrawToUSDCResult {
  final String message;
  final double amount;
  final String recipient;

  WithdrawToUSDCResult({
    required this.message,
    required this.amount,
    required this.recipient,
  });

  factory WithdrawToUSDCResult.fromJson(Map<String, dynamic> json) =>
      WithdrawToUSDCResult(
        message: json['message'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        recipient: json['recipient'] as String? ?? '',
      );
}

class BillCategory {
  final int id;
  final String billerCode;
  final String name;
  final String billerName;
  final String itemCode;
  final String shortName;
  final String labelName;
  final bool isAirtime;

  BillCategory({
    required this.id,
    required this.billerCode,
    required this.name,
    required this.billerName,
    required this.itemCode,
    required this.shortName,
    required this.labelName,
    required this.isAirtime,
  });

  factory BillCategory.fromJson(Map<String, dynamic> json) => BillCategory(
        id: json['id'] as int? ?? 0,
        billerCode: json['biller_code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        billerName: json['biller_name'] as String? ?? '',
        itemCode: json['item_code'] as String? ?? '',
        shortName: json['short_name'] as String? ?? '',
        labelName: json['label_name'] as String? ?? '',
        isAirtime: json['is_airtime'] as bool? ?? false,
      );
}

class BillValidation {
  final String? name;
  final String? responseMessage;

  BillValidation({this.name, this.responseMessage});

  factory BillValidation.fromJson(Map<String, dynamic> json) => BillValidation(
        name: json['name'] as String?,
        responseMessage: json['response_message'] as String?,
      );
}

class BillPaymentResult {
  final bool success;
  final String reference;
  final double amount;
  final double usdcSpent;

  BillPaymentResult({
    required this.success,
    required this.reference,
    required this.amount,
    required this.usdcSpent,
  });

  factory BillPaymentResult.fromJson(Map<String, dynamic> json) =>
      BillPaymentResult(
        success: json['success'] as bool? ?? false,
        reference: json['reference'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        usdcSpent: (json['usdc_spent'] as num?)?.toDouble() ?? 0,
      );
}

class BlendApyResponse {
  final String apy;
  final double raw;

  BlendApyResponse({required this.apy, required this.raw});

  factory BlendApyResponse.fromJson(Map<String, dynamic> json) =>
      BlendApyResponse(
        apy: json['apy'] as String? ?? '5.5%',
        raw: (json['raw'] as num?)?.toDouble() ?? 5.5,
      );
}

class BlendEarningsResponse {
  final double supplied;
  final double earned;
  final double currentAPY;
  final double totalValue;
  final bool isEarning;

  BlendEarningsResponse({
    required this.supplied,
    required this.earned,
    required this.currentAPY,
    required this.totalValue,
    required this.isEarning,
  });

  factory BlendEarningsResponse.fromJson(Map<String, dynamic> json) =>
      BlendEarningsResponse(
        supplied: (json['supplied'] as num?)?.toDouble() ?? 0,
        earned: (json['earned'] as num?)?.toDouble() ?? 0,
        currentAPY: (json['currentAPY'] as num?)?.toDouble() ?? 5.5,
        totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0,
        isEarning: json['isEarning'] as bool? ?? false,
      );
}

class BlendEnableResult {
  final bool success;
  final double amount;
  final double apy;

  BlendEnableResult({required this.success, required this.amount, required this.apy});

  factory BlendEnableResult.fromJson(Map<String, dynamic> json) =>
      BlendEnableResult(
        success: json['success'] as bool? ?? true,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        apy: (json['apy'] as num?)?.toDouble() ?? 5.5,
      );
}

class BlendDisableResult {
  final bool success;
  final double withdrawn;

  BlendDisableResult({required this.success, required this.withdrawn});

  factory BlendDisableResult.fromJson(Map<String, dynamic> json) =>
      BlendDisableResult(
        success: json['success'] as bool? ?? true,
        withdrawn: (json['withdrawn'] as num?)?.toDouble() ?? 0,
      );
}

class P2pSearchResult {
  final P2pUser user;

  P2pSearchResult({required this.user});

  factory P2pSearchResult.fromJson(Map<String, dynamic> json) =>
      P2pSearchResult(user: P2pUser.fromJson(json['user'] as Map<String, dynamic>));
}

class P2pUser {
  final int id;
  final String phoneNumber;
  final String? email;
  final String displayName;

  P2pUser({required this.id, required this.phoneNumber, this.email, required this.displayName});

  factory P2pUser.fromJson(Map<String, dynamic> json) => P2pUser(
        id: json['id'] as int,
        phoneNumber: json['phone_number'] as String? ?? '',
        email: json['email'] as String?,
        displayName: json['displayName'] as String? ?? json['email'] ?? json['phone_number'] ?? '',
      );
}

class P2pSendResult {
  final bool success;
  final String message;
  final int transferId;

  P2pSendResult({required this.success, required this.message, required this.transferId});

  factory P2pSendResult.fromJson(Map<String, dynamic> json) => P2pSendResult(
        success: json['success'] as bool? ?? true,
        message: json['message'] as String? ?? '',
        transferId: json['transferId'] as int? ?? 0,
      );
}

class SavingsGoal {
  final int id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? deadline;
  final String status;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.status,
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        name: json['name'] as String? ?? '',
        targetAmount: _parseDouble(json['target_amount']),
        currentAmount: _parseDouble(json['current_amount']),
        deadline: json['deadline']?.toString(),
        status: json['status'] as String? ?? 'active',
      );

  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

class GoalDetail {
  final SavingsGoal goal;
  final List<GoalContribution> contributions;

  GoalDetail({required this.goal, required this.contributions});

  factory GoalDetail.fromJson(Map<String, dynamic> json) {
    final goal = SavingsGoal.fromJson(json['goal'] as Map<String, dynamic>);
    final list = json['contributions'] as List<dynamic>? ?? [];
    final contributions = list.map((e) => GoalContribution.fromJson(e as Map<String, dynamic>)).toList();
    return GoalDetail(goal: goal, contributions: contributions);
  }
}

class GoalContribution {
  final int id;
  final double amountUsdc;
  final String source;
  final String createdAt;

  GoalContribution({required this.id, required this.amountUsdc, required this.source, required this.createdAt});

  factory GoalContribution.fromJson(Map<String, dynamic> json) => GoalContribution(
        id: json['id'] as int,
        amountUsdc: (json['amount_usdc'] as num?)?.toDouble() ?? 0,
        source: json['source'] as String? ?? 'manual',
        createdAt: json['created_at']?.toString() ?? '',
      );
}

class LockedSaving {
  final int id;
  final double amountUsdc;
  final int lockDuration;
  final double apyRate;
  final String startDate;
  final String maturityDate;
  final String status;
  final double interestEarned;

  LockedSaving({
    required this.id,
    required this.amountUsdc,
    required this.lockDuration,
    required this.apyRate,
    required this.startDate,
    required this.maturityDate,
    required this.status,
    required this.interestEarned,
  });

  bool get isMatured {
    try {
      return DateTime.parse(maturityDate).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  factory LockedSaving.fromJson(Map<String, dynamic> json) => LockedSaving(
        id: json['id'] as int,
        amountUsdc: (json['amount_usdc'] as num?)?.toDouble() ?? 0,
        lockDuration: json['lock_duration'] as int? ?? 0,
        apyRate: (json['apy_rate'] as num?)?.toDouble() ?? 0,
        startDate: json['start_date']?.toString() ?? '',
        maturityDate: json['maturity_date']?.toString() ?? '',
        status: json['status'] as String? ?? 'active',
        interestEarned: (json['interest_earned'] as num?)?.toDouble() ?? 0,
      );
}

class ReferralStats {
  final String code;
  final int totalReferred;
  final int pendingRewards;
  final double paidRewards;

  ReferralStats({
    required this.code,
    required this.totalReferred,
    required this.pendingRewards,
    required this.paidRewards,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) => ReferralStats(
        code: json['code'] as String? ?? '',
        totalReferred: json['totalReferred'] as int? ?? 0,
        pendingRewards: json['pendingRewards'] as int? ?? 0,
        paidRewards: (json['paidRewards'] as num?)?.toDouble() ?? 0,
      );
}

class NotificationsResponse {
  final List<AppNotification> notifications;
  final int unreadCount;

  NotificationsResponse({required this.notifications, required this.unreadCount});

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['notifications'] as List<dynamic>? ?? [];
    return NotificationsResponse(
      notifications: list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList(),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}

class AppNotification {
  final int id;
  final String type;
  final String? title;
  final String? message;
  final bool read;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.type,
    this.title,
    this.message,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as int,
        type: json['type'] as String? ?? '',
        title: json['title'] as String?,
        message: json['message'] as String?,
        read: json['read'] as bool? ?? false,
        createdAt: json['created_at']?.toString() ?? '',
      );
}

class TransparencyStats {
  final double treasuryUsdc;
  final double totalUserBalances;
  final int reservesRatio;
  final int totalTransactions;
  final double totalSavedNaira;
  final String treasuryAddress;

  TransparencyStats({
    required this.treasuryUsdc,
    required this.totalUserBalances,
    required this.reservesRatio,
    required this.totalTransactions,
    required this.totalSavedNaira,
    required this.treasuryAddress,
  });

  factory TransparencyStats.fromJson(Map<String, dynamic> json) => TransparencyStats(
        treasuryUsdc: (json['treasuryUsdc'] as num?)?.toDouble() ?? 0,
        totalUserBalances: (json['totalUserBalances'] as num?)?.toDouble() ?? 0,
        reservesRatio: json['reservesRatio'] as int? ?? 100,
        totalTransactions: json['totalTransactions'] as int? ?? 0,
        totalSavedNaira: (json['totalSavedNaira'] as num?)?.toDouble() ?? 0,
        treasuryAddress: json['treasuryAddress'] as String? ?? '',
      );
}

class P2pTransfer {
  final int id;
  final double amountUsdc;
  final double feeUsdc;
  final String status;
  final String? note;
  final String createdAt;
  final String direction;
  final String? otherPhone;
  final String? otherEmail;

  P2pTransfer({
    required this.id,
    required this.amountUsdc,
    required this.feeUsdc,
    required this.status,
    this.note,
    required this.createdAt,
    required this.direction,
    this.otherPhone,
    this.otherEmail,
  });

  String get otherDisplay => otherEmail ?? otherPhone ?? 'Unknown';

  factory P2pTransfer.fromJson(Map<String, dynamic> json) {
    final other = json['other_user'] as Map<String, dynamic>?;
    return P2pTransfer(
      id: json['id'] as int,
      amountUsdc: (json['amount_usdc'] as num?)?.toDouble() ?? 0,
      feeUsdc: (json['fee_usdc'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      note: json['note'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      direction: json['direction'] as String? ?? 'sent',
      otherPhone: other?['phone_number'] as String?,
      otherEmail: other?['email'] as String?,
    );
  }
}
