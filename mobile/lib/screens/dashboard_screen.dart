import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../api/api_client.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;
  WalletBalance? _balance;
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
      final auth = context.read<AuthProvider>();
      final results = await Future.wait([
        auth.getBalance(),
        auth.getTransactions(),
      ]);
      setState(() {
        _balance = results[0] as WalletBalance;
        _transactions = (results[1] as TransactionsResponse).transactions;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Failed to load data');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stakk',
                            style: AppTheme.header(fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () async {
                              final nav = Navigator.of(context);
                              await context.read<AuthProvider>().logout();
                              if (mounted) nav.pushReplacementNamed('/');
                            },
                            child: Text(
                              'Logout',
                              style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Text(
                            _error!,
                            style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626)),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (_balance != null) ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Balance',
                                style: AppTheme.body(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${_balance!.usdc.toStringAsFixed(2)}',
                                style: AppTheme.header(fontSize: 36, fontWeight: FontWeight.w700, color: const Color(0xFF4F46E5)),
                              ),
                              Text(
                                'USDC',
                                style: AppTheme.body(fontSize: 14, color: const Color(0xFF9CA3AF)),
                              ),
                              if (_balance!.stellarAddress != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _balance!.stellarAddress!,
                                  style: AppTheme.body(fontSize: 11, color: const Color(0xFFD1D5DB)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Transactions',
                              style: AppTheme.header(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            if (_transactions.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  'No transactions yet',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.body(fontSize: 14, color: const Color(0xFF9CA3AF)),
                                ),
                              )
                            else
                              ..._transactions.map((tx) => _TransactionRow(tx: tx)),
                          ],
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

class _TransactionRow extends StatelessWidget {
  final Transaction tx;

  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final amount = tx.displayAmount;
    final isPositive = amount >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tx.type ?? 'Transaction',
            style: AppTheme.body(fontSize: 14, color: const Color(0xFF374151)),
          ),
          Text(
            '${isPositive ? '+' : ''}${amount.toStringAsFixed(2)} USDC',
            style: AppTheme.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}
