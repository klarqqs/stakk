import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:stakk_savings/services/app_version_service.dart';
import 'dart:io';

/// Dialog shown when app update is required.
class ForceUpdateDialog extends StatelessWidget {
  const ForceUpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing
      child: AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.system_update,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Update Required',
                style: AppTheme.header(
                  context: context,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of STAKK is available. Please update to continue using the app.',
              style: AppTheme.body(
                context: context,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            if (AppVersionService().minimumVersion != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      'Current Version: ',
                      style: AppTheme.body(
                        context: context,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      AppVersionService().currentVersion ?? 'Unknown',
                      style: AppTheme.body(
                        context: context,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Required: ',
                      style: AppTheme.body(
                        context: context,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      AppVersionService().minimumVersion ?? 'Unknown',
                      style: AppTheme.body(
                        context: context,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
            SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Update Now',
              onPressed: () async {
                final urls = await AppVersionService().getAppStoreUrls();
                final url = Platform.isIOS ? urls['ios'] : urls['android'];
                
                if (url != null && url.isNotEmpty) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } else {
                  // Fallback: Open store search if URL not configured
                  final storeUrl = Platform.isIOS
                      ? 'https://apps.apple.com/search?term=stakk'
                      : 'https://play.google.com/store/search?q=stakk';
                  final uri = Uri.parse(storeUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
