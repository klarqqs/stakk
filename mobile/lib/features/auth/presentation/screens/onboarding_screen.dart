import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:stakk_savings/core/components/glass_card.dart';
import 'package:stakk_savings/core/constants/storage_keys.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/core/utils/snackbar_utils.dart';
import 'package:stakk_savings/core/utils/error_message_formatter.dart';
import 'package:stakk_savings/features/auth/presentation/screens/onboarding/onboarding_page_indicators.dart';
import 'package:stakk_savings/features/auth/presentation/screens/onboarding/onboarding_page_widget.dart';
import 'package:stakk_savings/features/auth/presentation/screens/onboarding/onboarding_steps.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

/// Onboarding flow. Uses [onboardingSteps] for content—add steps there to extend.
/// 2026 fintech: soft gradient, glass CTA, smooth transitions.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  late int _page;
  late int _totalSteps;
  Timer? _autoSwipeTimer;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  void initState() {
    super.initState();
    _totalSteps = onboardingSteps.length;
    _page = 0;
    _startAutoSwipe();
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSwipe() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_page < _totalSteps - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      } else {
        timer.cancel();
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() => _page = index);
    _startAutoSwipe(); // Restart timer when user manually swipes
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading || _isAppleLoading) return;

    _autoSwipeTimer?.cancel();
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
          TopSnackbar.error(
            context,
            'Unable to complete sign in. Please try again.',
          );
        }
        return;
      }

      // Extract name from Google account
      String? firstName;
      String? lastName;
      if (account.displayName != null && account.displayName!.isNotEmpty) {
        final nameParts = account.displayName!.trim().split(' ');
        if (nameParts.isNotEmpty) {
          firstName = nameParts.first;
          if (nameParts.length > 1) {
            lastName = nameParts.sublist(1).join(' ');
          }
        }
      }

      if (!mounted) return;
      await context.read<AuthProvider>().signInWithGoogle(
        idToken: idToken,
        email: account.email,
        firstName: firstName,
        lastName: lastName,
      );
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
    if (_isAppleLoading || _isGoogleLoading) return;

    _autoSwipeTimer?.cancel();
    setState(() => _isAppleLoading = true);
    try {
      // Check if Sign in with Apple is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        if (!mounted) return;
        setState(() => _isAppleLoading = false);
        TopSnackbar.error(
          context,
          'Sign in with Apple is not available. Please use email to continue.',
        );
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
          TopSnackbar.error(
            context,
            'Unable to complete sign in. Please try again.',
          );
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

      String errorMessage = 'Unable to sign in with Apple';
      switch (e.code) {
        case AuthorizationErrorCode.failed:
          errorMessage = 'Sign in with Apple failed. Please try again.';
          break;
        case AuthorizationErrorCode.invalidResponse:
          errorMessage = 'Unable to complete sign in. Please try again.';
          break;
        case AuthorizationErrorCode.notHandled:
          errorMessage =
              'Sign in with Apple is not available. Please use email or contact support.';
          break;
        case AuthorizationErrorCode.unknown:
          errorMessage =
              'Unable to sign in with Apple. Please try again or use email to continue.';
          break;
        default:
          errorMessage = 'Unable to sign in with Apple. Please try again.';
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
      // Note: Names might be null for Apple on subsequent sign-ins
      // Backend should decode from identity token, but if still null,
      // user can update in profile screen
      
      const storage = FlutterSecureStorage();
      final passcode = await storage.read(key: StorageKeys.passcode);
      if (!mounted) return;
      if (passcode != null && passcode.isNotEmpty) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/dashboard', (r) => false);
      } else {
        Navigator.of(
          context,
        ).pushReplacementNamed('/auth/create-passcode', arguments: true);
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

  void _handleEmailSignIn() {
    Navigator.of(context).pushReplacementNamed('/auth/check-email');
  }

  bool get _isLoading => _isGoogleLoading || _isAppleLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.gradientStartDark,
                          AppColors.gradientEndDark,
                          AppColors.gradientStartDark,
                        ]
                      : [
                          AppColors.gradientStartLight,
                          AppColors.gradientEndLight,
                          AppColors.gradientStartLight,
                        ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Opacity(
                  opacity: _isLoading ? 0.6 : 1.0,
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          itemCount: _totalSteps,
                          physics: _isLoading
                              ? const NeverScrollableScrollPhysics()
                              : const BouncingScrollPhysics(),
                          itemBuilder: (_, i) => OnboardingPageWidget(
                            step: onboardingSteps[i],
                            pageIndex: i,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                        child: Column(
                          children: [
                            OnboardingPageIndicators(
                              page: _page,
                              total: _totalSteps,
                            ),
                            const SizedBox(height: 40),
                            GlassCard(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 20,
                                  ),
                                  blur: 16,
                                  child: Column(
                                    children: [
                                      _GoogleSignInButton(
                                        onPressed: _handleGoogleSignIn,
                                        isDark: isDark,
                                        isLoading: _isGoogleLoading,
                                      ),
                                      const SizedBox(height: 14),
                                      _AppleSignInButton(
                                        onPressed: _handleAppleSignIn,
                                        isDark: isDark,
                                        isLoading: _isAppleLoading,
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: isDark
                                                  ? AppColors.borderDark
                                                        .withValues(alpha: 0.5)
                                                  : AppColors.borderLight
                                                        .withValues(alpha: 0.5),
                                              thickness: 1,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Text(
                                              'or',
                                              style: AppTheme.caption(
                                                context: context,
                                                fontSize: 14,
                                                color: isDark
                                                    ? AppColors.textTertiaryDark
                                                    : AppColors
                                                          .textTertiaryLight,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: isDark
                                                  ? AppColors.borderDark
                                                        .withValues(alpha: 0.5)
                                                  : AppColors.borderLight
                                                        .withValues(alpha: 0.5),
                                              thickness: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: PrimaryButton(
                                          label: 'Continue with Email',
                                          onPressed: _isLoading
                                              ? null
                                              : _handleEmailSignIn,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.1),
                // child: const Center(
                //   child: CircularProgressIndicator(),
                // ),
              ),
          ],
        ),
      ),
    );
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
          side: const BorderSide(color: Color(0xFFDADCE0), width: 1),
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
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
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
