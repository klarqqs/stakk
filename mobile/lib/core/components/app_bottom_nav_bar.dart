import 'package:flutter/material.dart';
import '../theme/tokens/app_colors.dart';
import '../theme/tokens/app_radius.dart';

enum AppTab { home, bills, send, save, more }

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
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: currentTab == AppTab.home,
                onTap: () => onTabSelected(AppTab.home),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Bills',
                isActive: currentTab == AppTab.bills,
                onTap: () => onTabSelected(AppTab.bills),
              ),
              _NavItem(
                icon: Icons.send_outlined,
                activeIcon: Icons.send_rounded,
                label: 'Send',
                isActive: currentTab == AppTab.send,
                onTap: () => onTabSelected(AppTab.send),
              ),
              _NavItem(
                icon: Icons.savings_outlined,
                activeIcon: Icons.savings_rounded,
                label: 'Save',
                isActive: currentTab == AppTab.save,
                onTap: () => onTabSelected(AppTab.save),
              ),
              _NavItem(
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view_rounded,
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
            Icon(isActive ? activeIcon : icon, size: 24, color: color),
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
