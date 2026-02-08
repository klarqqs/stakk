import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
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

  Future<http.Response> _requestWithRefresh(
    Future<http.Response> Function() fn,
  ) async {
    var res = await fn();
    if (res.statusCode == 401) {
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

    if (res.statusCode == 401) {
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

    if (res.statusCode == 401) {
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

    if (res.statusCode == 401) {
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

  /// Submit BVN for permanent deposit account (required before getVirtualAccount)
  Future<void> submitBvn(String bvn) async {
    final res = await _requestWithRefresh(() async => http.post(
          Uri.parse('${Env.apiBaseUrl}/wallet/bvn'),
          headers: await _headers(withAuth: true),
          body: jsonEncode({'bvn': bvn.trim()}),
        ));

    if (res.statusCode == 401) {
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
