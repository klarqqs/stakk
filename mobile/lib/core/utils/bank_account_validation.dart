import 'dart:async';

import 'package:flutter/foundation.dart';

/// Status of bank account validation.
enum BankAccountValidationStatus {
  idle,
  validating,
  success,
  error,
}

/// Result of bank account validation. Reusable for any bank-related form.
@immutable
class BankAccountValidationState {
  final BankAccountValidationStatus status;
  final String? accountName;
  final String? errorMessage;

  const BankAccountValidationState({
    required this.status,
    this.accountName,
    this.errorMessage,
  });

  bool get isValid => status == BankAccountValidationStatus.success;
  bool get isIdle => status == BankAccountValidationStatus.idle;
  bool get isValidating => status == BankAccountValidationStatus.validating;

  static const idle = BankAccountValidationState(status: BankAccountValidationStatus.idle);
}

/// Reusable controller for bank account validation with debouncing.
/// Call [scheduleValidation] when account number or bank changes.
class BankAccountValidationController extends ChangeNotifier {
  BankAccountValidationController({
    required this.resolveAccount,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  /// API call to resolve account. Inject from AuthProvider or API client.
  final Future<String> Function(String accountNumber, String bankCode) resolveAccount;

  final Duration debounceDuration;

  Timer? _debounceTimer;
  String? _lastValidatedAccount;
  String? _lastValidatedBankCode;

  BankAccountValidationState _state = BankAccountValidationState.idle;
  BankAccountValidationState get state => _state;

  /// Call when account number or bank changes. Debounces and auto-validates when
  /// account is 10 digits and bank is selected.
  void scheduleValidation(String accountNumber, String bankCode) {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    final account = accountNumber.trim();
    final code = bankCode.trim();

    if (account.length != 10 || code.isEmpty) {
      _state = BankAccountValidationState.idle;
      notifyListeners();
      return;
    }

    // Clear cached result when user edits so we don't show stale account name
    if (account != _lastValidatedAccount || code != _lastValidatedBankCode) {
      _state = BankAccountValidationState.idle;
      notifyListeners();
    }

    _debounceTimer = Timer(debounceDuration, () {
      _debounceTimer = null;
      _validate(account, code);
    });
    notifyListeners();
  }

  Future<void> _validate(String accountNumber, String bankCode) async {
    if (_lastValidatedAccount == accountNumber && _lastValidatedBankCode == bankCode && _state.isValid) {
      return;
    }

    _state = const BankAccountValidationState(status: BankAccountValidationStatus.validating);
    notifyListeners();

    try {
      final accountName = await resolveAccount(accountNumber, bankCode);
      _lastValidatedAccount = accountNumber;
      _lastValidatedBankCode = bankCode;
      _state = BankAccountValidationState(
        status: BankAccountValidationStatus.success,
        accountName: accountName,
      );
    } catch (e) {
      _lastValidatedAccount = null;
      _lastValidatedBankCode = null;
      _state = BankAccountValidationState(
        status: BankAccountValidationStatus.error,
        errorMessage: _friendlyErrorMessage(e),
      );
    }
    notifyListeners();
  }

  String _friendlyErrorMessage(dynamic e) {
    final msg = e.toString();
    if (msg.contains('invalid') || msg.contains('Invalid') || msg.contains('not found') || msg.contains('Account resolution failed')) {
      return 'Account number not found. Please check and try again.';
    }
    if (msg.contains('network') || msg.contains('Connection') || msg.contains('timeout')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (msg.contains('Session expired')) {
      return 'Session expired. Please sign in again.';
    }
    if ((msg.contains('bank') || msg.contains('Bank')) && (msg.contains('supported') || msg.contains('test') || msg.contains('sandbox'))) {
      return 'This bank is not supported in test mode. Try Access Bank.';
    }
    // Show the actual backend/Flutterwave error so user can debug (e.g. sandbox bank limits)
    return msg.isNotEmpty ? msg : 'Could not verify account. Please try again.';
  }

  /// Reset validation when user edits. Call before scheduleValidation to clear
  /// cached result when account/bank changes.
  void resetIfChanged(String accountNumber, String bankCode) {
    if (accountNumber.trim() != _lastValidatedAccount || bankCode.trim() != _lastValidatedBankCode) {
      _lastValidatedAccount = null;
      _lastValidatedBankCode = null;
      _state = BankAccountValidationState.idle;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
