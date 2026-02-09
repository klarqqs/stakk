import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:stakk_savings/core/components/error_banner.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/providers/auth_provider.dart';
import 'package:stakk_savings/features/send/presentation/screens/send_p2p_screen.dart';
import 'package:stakk_savings/features/send/presentation/screens/p2p_history_screen.dart';
import 'package:stakk_savings/features/send/presentation/widgets/send_skeleton_loader.dart';

/// Send tab: P2P transfers, send to Stellar, request money, recent recipients
class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  WalletBalance? _balance;
  List<P2pTransfer> _recentTransfers = [];
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
      final auth = context.read<AuthProvider>();
      final results = await Future.wait([
        auth.getBalance(),
        auth.p2pGetHistory().catchError((_) => <P2pTransfer>[]),
      ]);
      if (mounted) {
        setState(() {
          _balance = results[0] as WalletBalance;
          _recentTransfers = (results[1] as List<P2pTransfer>).take(5).toList();
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load';
          _loading = false;
        });
      }
    }
  }

  void _navigateToP2PSend() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SendP2pScreen(balance: _balance?.usdc ?? 0, onSuccess: _load),
      ),
    );
  }

  void _showSendToStellar() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (ctx) => _SendToStellarSheet(
        balance: _balance?.usdc ?? 0,
        onClose: () => Navigator.pop(ctx),
        onSuccess: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const SendSkeletonLoader()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Send',
                        style: AppTheme.header(
                          context: context,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Send USDC to friends or withdraw to Stellar',
                        style: AppTheme.caption(context: context, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null) ...[
                        ErrorBanner(message: _error!, onRetry: _load),
                        const SizedBox(height: 24),
                      ],
                      _QuickActionGrid(
                        onP2P: _navigateToP2PSend,
                        onStellar: _showSendToStellar,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Recipients',
                            style: AppTheme.title(
                              context: context,
                              fontSize: 18,
                            ),
                          ),
                          if (_recentTransfers.isNotEmpty)
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const P2pHistoryScreen(),
                                ),
                              ),
                              child: const Text('See all'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_recentTransfers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No recent recipients.\nTap "Send to Stakk User" above to send.',
                              textAlign: TextAlign.center,
                              style: AppTheme.caption(
                                context: context,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._recentTransfers.map(
                          (t) => _RecentRecipientTile(
                            transfer: t,
                            onTap: _navigateToP2PSend,
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  final VoidCallback onP2P;
  final VoidCallback onStellar;

  const _QuickActionGrid({required this.onP2P, required this.onStellar});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _QuickActionCard(
          icon: Icons.person_outline,
          title: 'Send to Stakk User',
          subtitle: 'P2P instant transfer',
          onTap: onP2P,
        ),
        _QuickActionCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Send to Stellar',
          subtitle: 'External wallet address',
          onTap: onStellar,
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: primary),
              const SizedBox(height: 6),
              Text(
                title,
                style: AppTheme.body(
                  context: context,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.caption(context: context, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRecipientTile extends StatelessWidget {
  final P2pTransfer transfer;
  final VoidCallback onTap;

  const _RecentRecipientTile({required this.transfer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSent = transfer.direction == 'sent';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(14),
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
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSent ? AppColors.error : AppColors.success,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer.otherDisplay,
                        style: AppTheme.body(
                          context: context,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\$${transfer.amountUsdc.toStringAsFixed(2)}',
                        style: AppTheme.caption(context: context, fontSize: 13),
                      ),
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
      ),
    );
  }
}

class _SendToStellarSheet extends StatefulWidget {
  final double balance;
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  const _SendToStellarSheet({
    required this.balance,
    required this.onClose,
    required this.onSuccess,
  });

  @override
  State<_SendToStellarSheet> createState() => _SendToStellarSheetState();
}

class _SendToStellarSheetState extends State<_SendToStellarSheet> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final address = _addressController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (address.isEmpty) {
      setState(() => _error = 'Enter Stellar address');
      return;
    }
    if (amount <= 0 || amount > widget.balance) {
      setState(() => _error = 'Enter valid amount');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().withdrawToUSDC(
        stellarAddress: address,
        amountUSDC: amount,
      );
      widget.onSuccess();
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _sending = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Withdrawal failed';
          _sending = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Send to Stellar Address',
              style: AppTheme.header(context: context, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Balance: \$${widget.balance.toStringAsFixed(2)} USDC',
              style: AppTheme.caption(context: context),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Stellar address (G...)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (USDC)'),
              keyboardType: TextInputType.number,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: AppTheme.body(fontSize: 14, color: AppColors.error),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClose,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Send',
                    onPressed: _sending ? null : _send,
                    isLoading: _sending,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
