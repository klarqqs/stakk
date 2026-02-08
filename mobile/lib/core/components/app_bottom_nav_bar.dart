import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/tokens/app_colors.dart';

enum AppTab { home, bills, invest, card, more }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppColors.surfaceDark : Colors.white).withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: (isDark ? AppColors.borderDark : AppColors.borderLight).withOpacity(0.5),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    isActive: currentTab == AppTab.home,
                    onTap: () => onTabSelected(AppTab.home),
                  ),
                  _NavItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    label: 'Bills',
                    isActive: currentTab == AppTab.bills,
                    onTap: () => onTabSelected(AppTab.bills),
                  ),
                  _NavItem(
                    icon: Icons.trending_up_outlined,
                    activeIcon: Icons.trending_up,
                    label: 'Invest',
                    isActive: currentTab == AppTab.invest,
                    onTap: () => onTabSelected(AppTab.invest),
                  ),
                  _NavItem(
                    icon: Icons.credit_card_outlined,
                    activeIcon: Icons.credit_card,
                    label: 'Card',
                    isActive: currentTab == AppTab.card,
                    onTap: () => onTabSelected(AppTab.card),
                  ),
                  _NavItem(
                    icon: Icons.more_horiz,
                    activeIcon: Icons.more_horiz,
                    label: 'More',
                    isActive: currentTab == AppTab.more,
                    onTap: () => onTabSelected(AppTab.more),
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
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive
        ? (isDark ? AppColors.primaryDark : AppColors.primary)
        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
