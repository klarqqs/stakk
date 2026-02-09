import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/features/send/presentation/widgets/p2p_history_skeleton_loader.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class P2pHistoryScreen extends StatefulWidget {
  const P2pHistoryScreen({super.key});

  @override
  State<P2pHistoryScreen> createState() => _P2pHistoryScreenState();
}

class _P2pHistoryScreenState extends State<P2pHistoryScreen> {
  List<P2pTransfer> _transfers = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // 'all', 'sent', 'received'

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
      final list = await context.read<AuthProvider>().p2pGetHistory();
      if (mounted) {
        setState(() {
          _transfers = list;
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
          _error = 'Failed to load history';
          _loading = false;
        });
      }
    }
  }

  List<P2pTransfer> get _filteredTransfers {
    switch (_filter) {
      case 'sent':
        return _transfers.where((t) => t.direction == 'sent').toList();
      case 'received':
        return _transfers.where((t) => t.direction == 'received').toList();
      default:
        return _transfers;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Transfers'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _filter,
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'sent', child: Text('Sent')),
              const PopupMenuItem(value: 'received', child: Text('Received')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const P2pHistorySkeletonLoader()
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center, style: AppTheme.body(fontSize: 14, color: AppColors.error)),
                          const SizedBox(height: 16),
                          SizedBox(width: double.infinity, child: PrimaryButton(label: 'Retry', onPressed: _load)),
                        ],
                      ),
                    ),
                  )
                : _filteredTransfers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.swap_horiz, size: 64, color: AppColors.textTertiaryLight),
                              const SizedBox(height: 16),
                              Text(
                                'No P2P transfers yet',
                                style: AppTheme.header(context: context, fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Send USDC to another Stakk user from the Send screen',
                                textAlign: TextAlign.center,
                                style: AppTheme.body(fontSize: 14, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredTransfers.length,
                        itemBuilder: (context, i) {
                          final t = _filteredTransfers[i];
                          return _P2pTransferTile(transfer: t);
                        },
                      ),
      ),
    );
  }
}

String _formatDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return iso;
  }
}

class _P2pTransferTile extends StatelessWidget {
  final P2pTransfer transfer;

  const _P2pTransferTile({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSent = transfer.direction == 'sent';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDarkMuted : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.borderDark.withValues(alpha: 0.4) : AppColors.borderLight.withValues(alpha: 0.6)),
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
            height: 48,
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
                  isSent ? 'To ${transfer.otherDisplay}' : 'From ${transfer.otherDisplay}',
                  style: AppTheme.body(fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (transfer.note != null && transfer.note!.isNotEmpty)
                  Text(
                    transfer.note!,
                    style: AppTheme.body(fontSize: 12, color: AppColors.textSecondaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  _formatDate(transfer.createdAt),
                  style: AppTheme.body(fontSize: 12, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isSent ? '-' : '+'}\$${transfer.amountUsdc.toStringAsFixed(2)}',
                style: AppTheme.body(fontSize: 16, fontWeight: FontWeight.w700, color: isSent ? AppColors.error : AppColors.success),
              ),
              if (transfer.feeUsdc > 0)
                Text(
                  'Fee: \$${transfer.feeUsdc.toStringAsFixed(2)}',
                  style: AppTheme.body(fontSize: 11, color: AppColors.textSecondaryLight),
                ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: transfer.status == 'completed' ? AppColors.success.withValues(alpha: 0.12) : AppColors.textSecondaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  transfer.status,
                  style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.w500, color: transfer.status == 'completed' ? AppColors.success : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
