import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                try {
                  await context.read<AuthProvider>().notificationsMarkAllRead();
                  _load();
                } catch (_) {}
              },
              child: const Text('Mark all read'),
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
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
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
                            Icon(Icons.notifications_none, size: 64, color: AppColors.textTertiaryLight),
                            const SizedBox(height: 16),
                            Text('No notifications', style: AppTheme.header(context: context, fontSize: 18, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, i) {
                          final n = _notifications[i];
                          return ListTile(
                            leading: Icon(
                              _iconForType(n.type),
                              color: n.read ? AppColors.textTertiaryLight : AppColors.primary,
                            ),
                            title: Text(n.title ?? n.type, style: AppTheme.body(fontSize: 15, fontWeight: n.read ? FontWeight.normal : FontWeight.w600)),
                            subtitle: n.message != null ? Text(n.message!, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                            onTap: () async {
                              if (!n.read) {
                                try {
                                  await context.read<AuthProvider>().notificationsMarkRead(n.id);
                                  _load();
                                } catch (_) {}
                              }
                            },
                          );
                        },
                      ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'deposit':
        return Icons.account_balance_wallet;
      case 'p2p_received':
        return Icons.swap_horiz;
      case 'goal_milestone':
        return Icons.flag;
      case 'referral_reward':
        return Icons.card_giftcard;
      default:
        return Icons.notifications;
    }
  }
}
