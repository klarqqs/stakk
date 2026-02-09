import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/core/theme/theme_provider.dart';
import 'package:stakk_savings/features/card/presentation/screens/card_screen.dart';
import 'package:stakk_savings/features/more/presentation/screens/privacy_policy_screen.dart';
import 'package:stakk_savings/features/more/presentation/screens/terms_of_service_screen.dart';
import 'package:stakk_savings/features/more/presentation/screens/transaction_history_screen.dart';
import 'package:stakk_savings/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:stakk_savings/features/referrals/presentation/screens/referrals_screen.dart';
import 'package:stakk_savings/features/more/presentation/screens/profile_screen.dart';
import 'package:stakk_savings/features/transparency/presentation/screens/transparency_screen.dart';
import 'package:stakk_savings/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// More tab: Virtual cards, Referrals, Transaction history, Settings, Transparency
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark =
        themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);
    final user = auth.user;
    final displayName = _displayName(user);
    final displayEmail =
        user?.email ?? (user?.phoneNumber ?? '').replaceFirst('email:', '');
    final hasUserInfo = displayName.isNotEmpty || displayEmail.isNotEmpty;

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            bottom: false,
            child: AbsorbPointer(
              absorbing: _isLoggingOut,
              child: Opacity(
                opacity: _isLoggingOut ? 0.6 : 1.0,
                child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            Text(
              'More',
              style: AppTheme.header(
                context: context,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Virtual cards, referrals & settings',
              style: AppTheme.caption(context: context, fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (hasUserInfo) ...[
              _ProfileCard(
                displayName: displayName.isEmpty ? 'Account' : displayName,
                displayEmail: displayEmail,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
            _MoreSection(title: 'Services'),
            _SettingTile(
              icon: Icons.credit_card_outlined,
              title: 'Virtual Dollar Cards',
              subtitle: 'Create & manage cards',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CardScreen()),
              ),
            ),
            _SettingTile(
              icon: Icons.card_giftcard_outlined,
              title: 'Referral Rewards',
              subtitle: 'Earn \$5 per referral',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReferralsScreen()),
              ),
            ),
            const SizedBox(height: 24),
            _MoreSection(title: 'Account'),
            _SettingTile(
              icon: Icons.history,
              title: 'Transaction History',
              subtitle: 'View all transactions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionHistoryScreen(),
                ),
              ),
            ),
            _SettingTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            const SizedBox(height: 24),
            _MoreSection(title: 'Trust'),
            _SettingTile(
              icon: Icons.verified_user_outlined,
              title: 'Transparency Dashboard',
              subtitle: 'Reserves, audit, blockchain',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransparencyScreen()),
              ),
            ),
            const SizedBox(height: 24),
            _MoreSection(title: 'Settings'),
            _SettingTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark mode',
              trailing: Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: isDark,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) {
                    context.read<ThemeProvider>().setThemeMode(
                      v ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ),
            ),
            _SettingTile(
              icon: Icons.help_outline,
              title: 'Support & Help',
              subtitle: 'support@stakk.com',
              onTap: () async {
                final uri = Uri(scheme: 'mailto', path: 'support@stakk.com');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            _SettingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
            ),
            _SettingTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
              ),
            ),
            _SettingTile(
              icon: Icons.logout,
              title: 'Log out',
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Log out', style: AppTheme.header(context: context, fontSize: 18, fontWeight: FontWeight.w600)),
                    content: Text(
                      'Are you sure you want to log out? You will need to sign in again to access your account.',
                      style: AppTheme.body(context: context, fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      PrimaryButton(
                        label: 'Log out',
                        onPressed: () => Navigator.pop(ctx, true),
                      ),
                    ],
                  ),
                );
                if (confirm != true || !context.mounted) return;
                setState(() => _isLoggingOut = true);
                final nav = Navigator.of(context);
                try {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    nav.pushNamedAndRemoveUntil('/', (r) => false);
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoggingOut = false);
                  }
                }
              },
            ),
          ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoggingOut)
          Container(
            color: Colors.black.withOpacity(0.1),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

String _displayName(dynamic user) {
  if (user == null) return '';
  final first = user.firstName as String?;
  final last = user.lastName as String?;
  if (first != null && first.isNotEmpty) {
    final parts = [first];
    if (last != null && last.isNotEmpty) parts.add(last);
    return parts.join(' ');
  }
  final email = user.email as String?;
  final phone = user.phoneNumber as String;
  if (email != null && email.isNotEmpty && !email.startsWith('email:')) {
    return email.split('@').first;
  }
  if (phone.isNotEmpty && !phone.startsWith('email:')) {
    return phone;
  }
  return '';
}

class _ProfileCard extends StatelessWidget {
  final String displayName;
  final String displayEmail;
  final bool isDark;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.displayName,
    required this.displayEmail,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final avatarLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceVariantDarkMuted
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: primary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.3),
                      primary.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                alignment: Alignment.center,
                child: Text(
                  avatarLetter,
                  style: AppTheme.header(
                    context: context,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTheme.body(
                        context: context,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (displayEmail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        displayEmail,
                        style: AppTheme.caption(
                          context: context,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ],
          ),
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
        style: AppTheme.body(
          context: context,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryLight,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDarkMuted : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark.withValues(alpha: 0.4)
                    : AppColors.borderLight.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(icon, color: primary, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.body(
                          context: context,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppTheme.caption(
                            context: context,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
