import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/tokens/app_radius.dart';

enum AppTab { wallet, swap, earn }

// TON Wallet Color Palette (2026 Modern)
class WalletColors {
  static const Color background = Color(0xFF000000); // Pure black
  static const Color cardBackground = Color(0xFF1C1C1E); // Dark gray
  static const Color primary = Color(0xFF00D9C5); // Teal/Cyan accent
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color success = Color(0xFF34C759);
}

class AppBottomNavBar extends StatelessWidget {
  final AppTab currentTab;
  final void Function(AppTab) onTabSelected;

  const AppBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 16,
          left: 20,
          right: 20,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: WalletColors.cardBackground.withOpacity(0.75),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: const Color(0xFF2C2C2E).withOpacity(0.5),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: FontAwesomeIcons.wallet,
                    label: 'USDC Wallet',
                    isActive: currentTab == AppTab.wallet,
                    onTap: () => onTabSelected(AppTab.wallet),
                  ),
                  _NavItem(
                    icon: FontAwesomeIcons.arrowRightArrowLeft,
                    label: 'Swap',
                    isActive: currentTab == AppTab.swap,
                    onTap: () => onTabSelected(AppTab.swap),
                  ),
                  _NavItem(
                    icon: FontAwesomeIcons.percent,
                    label: 'Earn',
                    isActive: currentTab == AppTab.earn,
                    onTap: () => onTabSelected(AppTab.earn),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? WalletColors.primary : WalletColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
