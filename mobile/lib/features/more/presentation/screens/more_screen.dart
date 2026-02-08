import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/core/theme/theme_provider.dart';
import 'package:stakk_savings/features/card/presentation/screens/card_screen.dart';
import 'package:stakk_savings/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:stakk_savings/features/referrals/presentation/screens/referrals_screen.dart';
import 'package:stakk_savings/features/transparency/presentation/screens/transparency_screen.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

/// More tab: Virtual cards, Referrals, Transaction history, Settings, Transparency
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            Text(
              'More',
              style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Virtual cards, referrals & settings',
              style: AppTheme.caption(context: context, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _MoreSection(title: 'Services'),
            _SettingTile(
              icon: Icons.credit_card_outlined,
              title: 'Virtual Dollar Cards',
              subtitle: 'Create & manage cards',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CardScreen())),
            ),
            _SettingTile(
              icon: Icons.card_giftcard_outlined,
              title: 'Referral Rewards',
              subtitle: 'Earn \$5 per referral',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralsScreen())),
            ),
            const SizedBox(height: 24),
            _MoreSection(title: 'Account'),
            _SettingTile(
              icon: Icons.history,
              title: 'Transaction History',
              subtitle: 'View all transactions',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _TransactionHistoryPlaceholder())),
            ),
            _SettingTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
            const SizedBox(height: 24),
            _MoreSection(title: 'Trust'),
            _SettingTile(
              icon: Icons.verified_user_outlined,
              title: 'Transparency Dashboard',
              subtitle: 'Reserves, audit, blockchain',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransparencyScreen())),
            ),
            const SizedBox(height: 24),
            _MoreSection(title: 'Settings'),
            _SettingTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark mode',
              trailing: Switch(
                value: isDark,
                onChanged: (v) {
                  context.read<ThemeProvider>().setThemeMode(
                        v ? ThemeMode.dark : ThemeMode.light,
                      );
                },
              ),
            ),
            _SettingTile(
              icon: Icons.help_outline,
              title: 'Support & Help',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.logout,
              title: 'Log out',
              onTap: () async {
                final nav = Navigator.of(context);
                await context.read<AuthProvider>().logout();
                if (context.mounted) nav.pushNamedAndRemoveUntil('/', (r) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreSection extends StatelessWidget {
  final String title;

  const _MoreSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTheme.body(context: context, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
      ),
    );
  }
}

class _TransactionHistoryPlaceholder extends StatelessWidget {
  const _TransactionHistoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppColors.textTertiaryLight),
            const SizedBox(height: 16),
            Text('Full transaction history', style: AppTheme.body(context: context)),
            const SizedBox(height: 8),
            Text('View from Home → Recent transactions', style: AppTheme.caption(context: context)),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceVariantDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AppTheme.body(context: context, fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle!, style: AppTheme.caption(context: context, fontSize: 13)) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
