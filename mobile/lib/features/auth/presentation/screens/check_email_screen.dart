import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:stakk_savings/core/constants/storage_keys.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/core/utils/snackbar_utils.dart';
import 'package:stakk_savings/core/utils/error_message_formatter.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/auth_service.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class CheckEmailScreen extends StatefulWidget {
  const CheckEmailScreen({super.key});

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final email = args is String ? args : null;
    if (email != null && _emailController.text != email) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkEmail() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !_isValidEmail(email)) {
      setState(() => _error = 'Please enter a valid email');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final exists = await context.read<AuthProvider>().checkEmail(email);
      if (!mounted) return;
      if (exists) {
        Navigator.of(context).pushReplacementNamed('/auth/login', arguments: email);
      } else {
        Navigator.of(context).pushReplacementNamed('/auth/signup', arguments: email);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e, st) {
      debugPrint('Check email error: $e\n$st');
      setState(() => _error = _formatError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isValidEmail(String s) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s);

  String _formatError(Object e) {
    return ErrorMessageFormatter.format(e);
  }

  bool get _isLoading => _isGoogleLoading || _isAppleLoading || _loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.of(context).pushReplacementNamed('/'),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Opacity(
                  opacity: _isLoading ? 0.6 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Enter your email',
                        style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "We'll check if you have an account and guide you to sign in or sign up.",
                        style: AppTheme.body(fontSize: 15, color: const Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                        ),
                        onChanged: (_) => setState(() => _error = null),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Text(
                            _error!,
                            style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: 'Continue',
                          onPressed: _loading ? null : _checkEmail,
                          isLoading: _loading,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: AppTheme.caption(context: context, fontSize: 13),
                            ),
                          ),
                          Expanded(child: Divider(color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _GoogleSignInButton(
                        onPressed: _handleGoogleSignIn,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                        isLoading: _isGoogleLoading,
                      ),
                      const SizedBox(height: 12),
                      _AppleSignInButton(
                        onPressed: _handleAppleSignIn,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                        isLoading: _isAppleLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading || _isAppleLoading) return;
    
    setState(() => _isGoogleLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();
      if (account == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        if (mounted) {
          setState(() => _isGoogleLoading = false);
          TopSnackbar.error(context, 'Failed to get Google token');
        }
        return;
      }

      if (!mounted) return;
      await context.read<AuthProvider>().signInWithGoogle(idToken);
      if (!mounted) return;
      await _handlePostSignIn();
    } catch (e) {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
        TopSnackbar.error(context, ErrorMessageFormatter.format(e));
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isAppleLoading) return;
    
    setState(() => _isAppleLoading = true);
    try {
      // Check if Sign in with Apple is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        if (mounted) {
          setState(() => _isAppleLoading = false);
          TopSnackbar.error(
            context,
            'Sign in with Apple is not available. Please sign in to iCloud on your device.',
          );
        }
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (!mounted) return;
      
      if (credential.identityToken == null) {
        if (mounted) {
          setState(() => _isAppleLoading = false);
          TopSnackbar.error(context, 'Failed to get Apple identity token');
        }
        return;
      }

      await context.read<AuthProvider>().signInWithApple(
            identityToken: credential.identityToken!,
            email: credential.email,
            firstName: credential.givenName,
            lastName: credential.familyName,
          );
      if (!mounted) return;
      await _handlePostSignIn();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (!mounted) return;
      
      // User canceled, don't show error
      if (e.code == AuthorizationErrorCode.canceled) {
        if (mounted) setState(() => _isAppleLoading = false);
        return;
      }

      String errorMessage = 'Apple sign-in failed';
      switch (e.code) {
        case AuthorizationErrorCode.failed:
          errorMessage = 'Apple sign-in failed. Please try again.';
          break;
        case AuthorizationErrorCode.invalidResponse:
          errorMessage = 'Invalid response from Apple. Please try again.';
          break;
        case AuthorizationErrorCode.notHandled:
          errorMessage = 'Apple sign-in not configured. Please contact support.';
          break;
        case AuthorizationErrorCode.unknown:
          errorMessage = 'Apple sign-in error. Please ensure:\n'
              '• You are signed in to iCloud\n'
              '• Sign in with Apple is enabled in Settings\n'
              '• You are using a physical device (not simulator)';
          break;
        default:
          errorMessage = 'Apple sign-in error: ${e.code}';
      }
      
      if (mounted) {
        setState(() => _isAppleLoading = false);
        TopSnackbar.error(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAppleLoading = false);
        TopSnackbar.error(context, ErrorMessageFormatter.format(e));
      }
    }
  }

  Future<void> _handlePostSignIn() async {
    if (!mounted) return;
    try {
      const storage = FlutterSecureStorage();
      final passcode = await storage.read(key: StorageKeys.passcode);
      if (!mounted) return;
      if (passcode != null && passcode.isNotEmpty) {
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (r) => false);
      } else {
        Navigator.of(context).pushReplacementNamed('/auth/create-passcode', arguments: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
          _isAppleLoading = false;
        });
        TopSnackbar.error(context, ErrorMessageFormatter.format(e));
      }
    }
  }
}

/// Google Sign-In button compliant with Google branding guidelines.
/// Uses official Google logo and follows design requirements.
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDark;
  final bool isLoading;

  const _GoogleSignInButton({
    required this.onPressed,
    required this.isDark,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          side: const BorderSide(
            color: Color(0xFFDADCE0),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF1F1F1F),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if image not found
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: Icon(Icons.g_mobiledata, size: 20),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: AppTheme.body(
                      context: context,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1F1F1F),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Apple Sign-In button compliant with Apple Human Interface Guidelines.
/// Uses black background with white text (standard style).
class _AppleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDark;
  final bool isLoading;

  const _AppleSignInButton({
    required this.onPressed,
    required this.isDark,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/apple_logo.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if SVG not found
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: Icon(Icons.apple, size: 20, color: Colors.white),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Apple',
                    style: AppTheme.body(
                      context: context,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
