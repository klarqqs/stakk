import 'package:flutter/material.dart';
import '../api/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  User? _user;
  User? get user => _user;

  Future<bool> isAuthenticated() => _api.hasToken();

  Future<void> login(String phoneNumber, String password) async {
    final res = await _api.login(
      phoneNumber: phoneNumber,
      password: password,
    );
    await _api.saveToken(res.token);
    _user = res.user;
    notifyListeners();
  }

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

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    notifyListeners();
  }

  Future<WalletBalance> getBalance() => _api.getBalance();

  Future<TransactionsResponse> getTransactions() =>
      _api.getTransactions();
}
