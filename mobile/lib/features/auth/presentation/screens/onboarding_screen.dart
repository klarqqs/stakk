import 'package:flutter/material.dart';

import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.gradientStartDark, AppColors.gradientEndDark]
                : [AppColors.gradientStartLight, AppColors.gradientEndLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: const [
                    _OnboardingPage(
                      title: 'Save in USDC',
                      subtitle: 'Protect your savings from naira devaluation. Hold stable, spend smart.',
                      asset: Icons.savings_outlined,
                    ),
                    _OnboardingPage(
                      title: 'Secured by Stellar',
                      subtitle: 'Your funds are backed by blockchain security. Fast, transparent, reliable.',
                      asset: Icons.security_outlined,
                    ),
                    _OnboardingPage(
                      title: 'Fund via NGN',
                      subtitle: 'Deposit easily with your bank. Virtual account ready in seconds.',
                      asset: Icons.account_balance_wallet_outlined,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                child: Column(
                  children: [
                    _PageIndicators(page: _page, total: 3),
                    const SizedBox(height: 28),
                    if (_page < 2)
                      PrimaryButton(
                        label: 'Next',
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          );
                        },
                      )
                    else
                      PrimaryButton(
                        label: 'Continue with Email',
                        onPressed: () =>
                            Navigator.of(context).pushReplacementNamed('/auth/check-email'),
                      ),
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

class _PageIndicators extends StatelessWidget {
  final int page;
  final int total;

  const _PageIndicators({required this.page, required this.total});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = isDark ? AppColors.primaryDark : AppColors.primary;
    final inactive = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = page == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? active : inactive.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        );
      }),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData asset;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(asset, size: 72, color: primary),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: AppTheme.headline(context: context, fontSize: 26),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: AppTheme.body(context: context, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
