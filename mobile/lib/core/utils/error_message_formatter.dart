/// Utility for formatting error messages into user-friendly text.
/// 
/// This ensures all error messages shown to users are:
/// - Non-technical and easy to understand
/// - Actionable (tell users what they can do)
/// - Consistent across the app
class ErrorMessageFormatter {
  /// Convert any error into a user-friendly message
  static String format(dynamic error) {
    if (error == null) {
      return 'Something went wrong. Please try again.';
    }

    final errorString = error.toString().toLowerCase();
    final originalMessage = error.toString();

    // Network connectivity errors
    if (errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('no address associated with hostname')) {
      return 'No internet connection. Please check your network settings and try again.';
    }

    // Connection timeout errors
    if (errorString.contains('timeout') ||
        errorString.contains('timed out') ||
        errorString.contains('connection timed out')) {
      return 'The request took too long. Please check your internet connection and try again.';
    }

    // Connection refused/reset errors
    if (errorString.contains('connection refused') ||
        errorString.contains('connection reset') ||
        errorString.contains('connection closed')) {
      return 'Unable to connect to our servers. Please try again in a moment.';
    }

    // HTTP errors
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'You don\'t have permission to perform this action.';
    }

    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'The requested resource was not found.';
    }

    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504') ||
        errorString.contains('internal server error') ||
        errorString.contains('bad gateway') ||
        errorString.contains('service unavailable')) {
      return 'Our servers are experiencing issues. Please try again later.';
    }

    // Format/parsing errors
    if (errorString.contains('formatexception') ||
        errorString.contains('invalid json') ||
        errorString.contains('type') && errorString.contains('is not a subtype')) {
      return 'We received an unexpected response. Please try again.';
    }

    // SSL/Certificate errors
    if (errorString.contains('certificate') ||
        errorString.contains('ssl') ||
        errorString.contains('handshake')) {
      return 'There was a security issue connecting to our servers. Please try again.';
    }

    // If it's already a user-friendly message (short and doesn't contain technical terms)
    if (originalMessage.length < 100 &&
        !originalMessage.toLowerCase().contains('exception') &&
        !originalMessage.toLowerCase().contains('error:') &&
        !originalMessage.toLowerCase().contains('failed:')) {
      return originalMessage;
    }

    // Default fallback
    return 'Something went wrong. Please try again.';
  }

  /// Format API exception messages to be user-friendly
  static String formatApiException(String message) {
    final lowerMessage = message.toLowerCase();

    // Check if already user-friendly
    if (message.length < 80 &&
        !lowerMessage.contains('exception') &&
        !lowerMessage.contains('error:') &&
        !lowerMessage.contains('failed:') &&
        !lowerMessage.contains('backend') &&
        !lowerMessage.contains('server') &&
        !lowerMessage.contains('connection')) {
      return message;
    }

    // Format common API error patterns
    if (lowerMessage.contains('email already exists') ||
        lowerMessage.contains('user already registered')) {
      return 'This email is already registered. Please sign in instead.';
    }

    if (lowerMessage.contains('invalid email') ||
        lowerMessage.contains('email format')) {
      return 'Please enter a valid email address.';
    }

    if (lowerMessage.contains('invalid password') ||
        lowerMessage.contains('password too short')) {
      return 'Password does not meet requirements. Please try again.';
    }

    if (lowerMessage.contains('invalid otp') ||
        lowerMessage.contains('otp expired') ||
        lowerMessage.contains('wrong otp')) {
      return 'The verification code is incorrect or has expired. Please try again.';
    }

    if (lowerMessage.contains('insufficient funds') ||
        lowerMessage.contains('balance too low')) {
      return 'Insufficient funds. Please add money to your wallet.';
    }

    if (lowerMessage.contains('session expired') ||
        lowerMessage.contains('token expired')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (lowerMessage.contains('too many requests') ||
        lowerMessage.contains('rate limit') ||
        lowerMessage.contains('429')) {
      return 'Too many requests. Please try again in a moment.';
    }

    // Use the general formatter for technical errors
    return format(message);
  }
}
