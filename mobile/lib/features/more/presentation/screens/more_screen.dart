import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/theme_provider.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

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
            const SizedBox(height: 32),
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
            const SizedBox(height: 8),
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

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
