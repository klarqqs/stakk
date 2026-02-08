import 'package:flutter/material.dart';

import 'package:stakk_savings/core/theme/app_theme.dart';
// import 'dart:io';
// import 'package:provider/provider.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// import 'package:stakk_savings/providers/auth_provider.dart';
// import 'package:stakk_savings/api/auth_service.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
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
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  if (_page < 2)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Next'),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // _GoogleSignInButton(),
                        // if (Platform.isIOS) ...[
                        //   const SizedBox(height: 16),
                        //   _AppleSignInButton(),
                        // ],
                        // const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pushReplacementNamed('/auth/check-email'),
                            icon: const Icon(Icons.email_outlined, size: 20),
                            label: const Text('Continue with Email'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Continue with Google and Apple - commented out for now
// class _GoogleSignInButton extends StatefulWidget { ... }
// class _AppleSignInButton extends StatefulWidget { ... }

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(asset, size: 80, color: const Color(0xFF4F46E5)),
          const SizedBox(height: 32),
          Text(
            title,
            style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: AppTheme.body(fontSize: 16, color: const Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
