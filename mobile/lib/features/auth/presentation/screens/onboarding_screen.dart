import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    try {
      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();
      if (account == null) return;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        if (mounted) TopSnackbar.error(context, 'Failed to get Google token');
        return;
      }

      if (!mounted) return;
      await context.read<AuthProvider>().signInWithGoogle(idToken);
      await _handlePostSignIn();
    } catch (e) {
      if (mounted) {
        TopSnackbar.error(context, 'Google sign-in failed: ${e.toString()}');
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      // Check if Sign in with Apple is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        if (mounted) {
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
      await _handlePostSignIn();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'Apple sign-in failed';
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          // User canceled, don't show error
          return;
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
      
      TopSnackbar.error(context, errorMessage);
    } catch (e) {
      if (mounted) {
        TopSnackbar.error(
          context,
          'Apple sign-in failed: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _handlePostSignIn() async {
    if (!mounted) return;
    const storage = FlutterSecureStorage();
    final passcode = await storage.read(key: StorageKeys.passcode);
    if (passcode != null && passcode.isNotEmpty) {
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (r) => false);
    } else {
      Navigator.of(context).pushReplacementNamed('/auth/create-passcode', arguments: true);
    }
  }

  void _handleEmailSignIn() {
    Navigator.of(context).pushReplacementNamed('/auth/check-email');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
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
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _totalSteps,
                  physics: const BouncingScrollPhysics(),
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
                    OnboardingPageIndicators(page: _page, total: _totalSteps)
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 200.ms),
                    const SizedBox(height: 40),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      blur: 16,
                      child: Column(
                        children: [
                          _GoogleSignInButton(
                            onPressed: _handleGoogleSignIn,
                            isDark: isDark,
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 400.ms)
                              .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 400.ms, curve: Curves.easeOutCubic),
                          const SizedBox(height: 14),
                          _AppleSignInButton(
                            onPressed: _handleAppleSignIn,
                            isDark: isDark,
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 500.ms)
                              .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 500.ms, curve: Curves.easeOutCubic),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? AppColors.borderDark.withValues(alpha: 0.5)
                                      : AppColors.borderLight.withValues(alpha: 0.5),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'or',
                                  style: AppTheme.caption(
                                    context: context,
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiaryLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? AppColors.borderDark.withValues(alpha: 0.5)
                                      : AppColors.borderLight.withValues(alpha: 0.5),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          )
                              .animate()
                              .fadeIn(duration: 300.ms, delay: 600.ms),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              label: 'Continue with Email',
                              onPressed: _handleEmailSignIn,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 700.ms)
                              .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 700.ms, curve: Curves.easeOutCubic),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 300.ms)
                        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0), duration: 600.ms, delay: 300.ms, curve: Curves.easeOutCubic),
                  ],
                ),
              ),
            ],
          ),
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

  const _GoogleSignInButton({
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
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
        child: Row(
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

  const _AppleSignInButton({
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: Row(
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
