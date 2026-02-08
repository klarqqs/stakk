/// API endpoint paths (base URL from config)
class ApiEndpoints {
  ApiEndpoints._();

  static const String auth = '/auth';
  static const String wallet = '/wallet';
  static const String checkEmail = '$auth/check-email';
  static const String registerEmail = '$auth/register-email';
  static const String verifyEmail = '$auth/verify-email';
  static const String loginEmail = '$auth/login-email';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';
  static const String profile = '$auth/profile';
  static const String balance = '$wallet/balance';
  static const String transactions = '$wallet/transactions';
  static const String virtualAccount = '$wallet/virtual-account';
}
