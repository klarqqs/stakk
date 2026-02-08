/// Form validation helpers
class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!_emailRegex.hasMatch(value.trim())) return 'Please enter a valid email';
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < minLength) return 'Password must be at least $minLength characters';
    return null;
  }

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your phone number';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Please enter a valid phone number';
    return null;
  }

  static bool isValidEmail(String s) => _emailRegex.hasMatch(s.trim());
}
