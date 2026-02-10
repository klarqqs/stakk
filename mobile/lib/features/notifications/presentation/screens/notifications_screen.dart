import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/features/notifications/presentation/widgets/notifications_skeleton_loader.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await context.read<AuthProvider>().notificationsGet();
      if (mounted) setState(() {
        _notifications = res.notifications;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _error = 'Failed to load';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardSurface = isDark ? AppColors.cardSurfaceDark : AppColors.cardSurfaceLight;
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: AppTheme.title(context: context, fontSize: 18).copyWith(letterSpacing: -0.3)),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                try {
                  await context.read<AuthProvider>().notificationsMarkAllRead();
                  _load();
                } catch (_) {}
              },
              child: Text(
                'Mark all read',
                style: AppTheme.body(context: context, fontSize: 13, fontWeight: FontWeight.w600)
                    .copyWith(color: isDark ? AppColors.primaryDark : AppColors.primary),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const NotificationsSkeletonLoader()
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.circleExclamation, size: 48, color: AppColors.error),
                          const SizedBox(height: 20),
                          Text(_error!, textAlign: TextAlign.center, style: AppTheme.body(context: context, fontSize: 15)),
                          const SizedBox(height: 20),
                          SizedBox(width: double.infinity, child: PrimaryButton(label: 'Retry', onPressed: _load)),
                        ],
                      ),
                    ),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.bellSlash, size: 56, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                            const SizedBox(height: 20),
                            Text('No notifications', style: AppTheme.header(context: context, fontSize: 18, fontWeight: FontWeight.w600).copyWith(letterSpacing: -0.2)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _notifications.length,
                        itemBuilder: (context, i) {
                          final n = _notifications[i];
                          final primary = isDark ? AppColors.primaryDark : AppColors.primary;
                          final muted = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  if (!n.read) {
                                    try {
                                      await context.read<AuthProvider>().notificationsMarkRead(n.id);
                                      _load();
                                    } catch (_) {}
                                  }
                                },
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: cardSurface,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                        blurRadius: 12,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: (n.read ? muted : primary).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: FaIcon(_iconForType(n.type), size: 20, color: n.read ? muted : primary),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              n.title ?? n.type,
                                              style: AppTheme.body(context: context, fontSize: 15, fontWeight: n.read ? FontWeight.w500 : FontWeight.w600)
                                                  .copyWith(letterSpacing: -0.1),
                                            ),
                                            if (n.message != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                n.message!,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.caption(context: context, fontSize: 13),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'deposit':
        return FontAwesomeIcons.wallet;
      case 'p2p_received':
        return FontAwesomeIcons.arrowsLeftRight;
      case 'goal_milestone':
        return FontAwesomeIcons.bullseye;
      case 'referral_reward':
        return FontAwesomeIcons.gift;
      default:
        return FontAwesomeIcons.bell;
    }
  }
}
