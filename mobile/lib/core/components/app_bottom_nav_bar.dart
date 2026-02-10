import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/tokens/app_colors.dart';
import '../theme/tokens/app_radius.dart';

enum AppTab { home, loan, wealth, reward, more }

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
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceDark : Colors.white).withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: FontAwesomeIcons.house,
                activeIcon: FontAwesomeIcons.house,
                label: 'Home',
                isActive: currentTab == AppTab.home,
                onTap: () => onTabSelected(AppTab.home),
              ),
              _NavItem(
                icon: FontAwesomeIcons.sackDollar,
                activeIcon: FontAwesomeIcons.sackDollar,
                label: 'Loan',
                isActive: currentTab == AppTab.loan,
                onTap: () => onTabSelected(AppTab.loan),
              ),
              _NavItem(
                icon: FontAwesomeIcons.chartLine,
                activeIcon: FontAwesomeIcons.chartLine,
                label: 'Wealth',
                isActive: currentTab == AppTab.wealth,
                onTap: () => onTabSelected(AppTab.wealth),
              ),
              _NavItem(
                icon: FontAwesomeIcons.gift,
                activeIcon: FontAwesomeIcons.gift,
                label: 'Reward',
                isActive: currentTab == AppTab.reward,
                onTap: () => onTabSelected(AppTab.reward),
              ),
              _NavItem(
                icon: FontAwesomeIcons.circleUser,
                activeIcon: FontAwesomeIcons.circleUser,
                label: 'More',
                isActive: currentTab == AppTab.more,
                onTap: () => onTabSelected(AppTab.more),
              ),
            ],
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
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(isActive ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
