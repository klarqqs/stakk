import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';

class ApiClient {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() => _storage.read(key: 'token');

  Future<void> _setToken(String token) =>
      _storage.write(key: 'token', value: token);

  Future<void> _clearToken() => _storage.delete(key: 'token');

  Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<AuthResponse> register({
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('${Env.apiBaseUrl}/auth/register'),
      headers: await _headers(),
      body: jsonEncode({
        'phone_number': phoneNumber,
        'email': email,
        'password': password,
      }),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      throw ApiException(body['error']?.toString() ?? 'Registration failed');
    }
    return AuthResponse.fromJson(body);
  }

  Future<AuthResponse> login({
    required String phoneNumber,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('${Env.apiBaseUrl}/auth/login'),
      headers: await _headers(),
      body: jsonEncode({
        'phone_number': phoneNumber,
        'password': password,
      }),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(body['error']?.toString() ?? 'Login failed');
    }
    return AuthResponse.fromJson(body);
  }

  Future<WalletBalance> getBalance() async {
    final res = await http.get(
      Uri.parse('${Env.apiBaseUrl}/wallet/balance'),
      headers: await _headers(withAuth: true),
    );

    if (res.statusCode == 401) {
      await _clearToken();
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
    final res = await http.get(
      Uri.parse('${Env.apiBaseUrl}/wallet/transactions'),
      headers: await _headers(withAuth: true),
    );

    if (res.statusCode == 401) {
      await _clearToken();
      throw ApiException('Session expired');
    }
    if (res.statusCode != 200) {
      throw ApiException('Failed to fetch transactions');
    }
    return TransactionsResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<void> saveToken(String token) => _setToken(token);

  Future<void> logout() => _clearToken();

  Future<bool> hasToken() async => (await _getToken()) != null;
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class AuthResponse {
  final String message;
  final User user;
  final String token;

  AuthResponse({
    required this.message,
    required this.user,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        message: json['message'] as String? ?? '',
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        token: json['token'] as String,
      );
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
