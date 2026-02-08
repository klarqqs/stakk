import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../features/bills/domain/models/bill_models.dart';
import 'auth_service.dart';

class ApiClient {
  final _storage = const FlutterSecureStorage();
  final _authService = AuthService();

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
    var res = await fn();
    if (_isAuthError(res.statusCode)) {
      final newAccess = await _tryRefresh();
      if (newAccess != null) {
        res = await fn();
      }
    }
    return res;
  }

  Future<WalletBalance> getBalance() async {
    final res = await _requestWithRefresh(() async => http.get(
          Uri.parse('${Env.apiBaseUrl}/wallet/balance'),
          headers: await _headers(withAuth: true),
        ));

    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      throw ApiException('Session expired');
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
      throw ApiException('Session expired');
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
      throw ApiException('Session expired');
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to fetch virtual account');
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
      throw ApiException('Session expired');
    }
    if (res.statusCode != 200) {
      throw ApiException('Failed to fetch banks');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['banks'] as List<dynamic>? ?? [];
    return list.map((e) => Bank.fromJson(e as Map<String, dynamic>)).toList();
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
      throw ApiException('Session expired');
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
      throw ApiException('Session expired');
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
      throw ApiException('Session expired');
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
      throw ApiException('Session expired');
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
      throw ApiException('Session expired');
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
      throw ApiException('Session expired');
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
      throw ApiException('Session expired');
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
    required String type,
  }) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/bills/pay'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({
            'customer': customer,
            'amount': amount,
            'type': type,
          }),
        ));
    if (_isAuthError(res.statusCode)) {
      await _clearTokens();
      throw ApiException('Session expired');
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
      throw ApiException('Session expired');
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
      throw ApiException('Session expired');
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw ApiException(body?['error']?.toString() ?? 'Failed to save BVN');
    }
  }

  Future<void> saveToken(String token) => _setToken(token);

  Future<void> logout() => _clearTokens();

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

  User({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.stellarAddress,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        phoneNumber: json['phone_number'] as String,
        email: json['email'] as String?,
        stellarAddress: json['stellar_address'] as String?,
      );
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
