import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/features/more/presentation/widgets/transaction_history_skeleton_loader.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

/// Full transaction history. Same data as Home → Recent transactions.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<Transaction> _transactions = [];

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
      final res = await context.read<AuthProvider>().getTransactions();
      if (mounted) {
        setState(() {
          _transactions = res.transactions;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.message == 'Session expired') {
          await context.read<AuthProvider>().handleSessionExpired(context);
        } else {
          setState(() {
            _error = e.message;
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load transactions';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const TransactionHistorySkeletonLoader()
            : _error != null
                ? _ErrorView(message: _error!, onRetry: _load)
                : _transactions.isEmpty
                    ? _EmptyView()
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: _transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _TransactionRow(tx: _transactions[i]),
                      ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: AppTheme.body(context: context)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: PrimaryButton(label: 'Retry', onPressed: onRetry)),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textTertiaryLight),
          const SizedBox(height: 16),
          Text('No transactions yet', style: AppTheme.body(context: context)),
          const SizedBox(height: 8),
          Text('Your transactions will appear here', style: AppTheme.caption(context: context)),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction tx;

  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final amount = tx.displayAmount;
    final isPositive = amount >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceVariantDarkMuted
            : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx.type ?? 'Transaction',
                style: AppTheme.body(context: context, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              if (tx.createdAt != null)
                Text(
                  tx.createdAt!,
                  style: AppTheme.caption(context: context, fontSize: 12),
                ),
            ],
          ),
          Text(
            '${isPositive ? '+' : ''}\$${amount.toStringAsFixed(2)}',
            style: AppTheme.body(
              context: context,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
