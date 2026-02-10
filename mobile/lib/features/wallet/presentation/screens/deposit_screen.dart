import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io' show Platform;
import 'package:stakk_savings/features/wallet/presentation/screens/wallet_address_screen.dart';
import 'package:stakk_savings/features/wallet/presentation/screens/usdc_wallet_screen.dart';

class DepositScreen extends StatelessWidget {
  const DepositScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WalletColors.background,
      appBar: AppBar(
        title: const Text(
          'Deposit USDC',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: WalletColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.chevronLeft,
            size: 20,
            color: WalletColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose deposit method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: WalletColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),

              // Option 1: NGN Virtual Account (Flutterwave)
              _DepositOption(
                icon: FontAwesomeIcons.buildingColumns,
                title: 'Deposit via Bank Transfer (NGN)',
                subtitle: 'NGN Virtual Account with Flutterwave',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Navigate to Flutterwave virtual account deposit
                  // TODO: Implement Flutterwave deposit screen
                },
              ),

              const SizedBox(height: 12),

              // Option 2: Apple Pay / Google Pay
              _DepositOption(
                icon: Platform.isIOS
                    ? FontAwesomeIcons.apple
                    : FontAwesomeIcons.google,
                title: Platform.isIOS ? 'Apple Pay' : 'Google Pay',
                subtitle: 'Quick deposit with ${Platform.isIOS ? 'Apple' : 'Google'} Pay',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Navigate to Apple/Google Pay
                  // TODO: Implement Apple/Google Pay integration
                },
              ),

              const SizedBox(height: 12),

              // Option 3: External Wallet Address
              _DepositOption(
                icon: FontAwesomeIcons.wallet,
                title: 'External Wallet Address',
                subtitle: 'Send USDC from another wallet',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const WalletAddressScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepositOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DepositOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: WalletColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2C2C2E),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: WalletColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  color: WalletColors.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: WalletColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: WalletColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 16,
              color: WalletColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
