import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

/// User profile screen: view account info.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static String _displayName(dynamic user) {
    if (user == null) return 'Account';
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
    return 'Account';
  }

  static String _formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '—';
    if (phone.startsWith('email:')) return '—';
    return phone;
  }

  static String _orDash(String? s) =>
      (s != null && s.isNotEmpty) ? s : '—';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final displayName = _displayName(user);
    final displayEmail =
        user?.email ?? (user?.phoneNumber ?? '').replaceFirst('email:', '');
    final displayPhone = _formatPhone(user?.phoneNumber);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primary.withValues(alpha: 0.25),
                        primary.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: AppTheme.header(
                      context: context,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                displayName,
                style: AppTheme.header(
                  context: context,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (displayEmail.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  displayEmail,
                  style: AppTheme.caption(context: context, fontSize: 15),
                ),
              ],
              const SizedBox(height: 40),
              _ProfileInfoTile(
                icon: Icons.person_outline,
                label: 'First name',
                value: _orDash(user?.firstName?.trim()),
              ),
              const SizedBox(height: 12),
              _ProfileInfoTile(
                icon: Icons.badge_outlined,
                label: 'Last name',
                value: _orDash(user?.lastName?.trim()),
              ),
              const SizedBox(height: 12),
              _ProfileInfoTile(
                icon: Icons.phone_outlined,
                label: 'Phone number',
                value: displayPhone,
              ),
              const SizedBox(height: 12),
              _ProfileInfoTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: displayEmail.isNotEmpty ? displayEmail : '—',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDarkMuted
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark.withValues(alpha: 0.5)
              : AppColors.borderLight.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.caption(
                    context: context,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.body(
                    context: context,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
