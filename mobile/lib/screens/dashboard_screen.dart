import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _showVirtualAccountSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _VirtualAccountBottomSheet(
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
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
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _showVirtualAccountSheet(context),
                          icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                          label: const Text('Fund via NGN Virtual Account'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4F46E5),
                            side: const BorderSide(color: Color(0xFF4F46E5)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
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

class _VirtualAccountBottomSheet extends StatefulWidget {
  final VoidCallback onClose;

  const _VirtualAccountBottomSheet({required this.onClose});

  @override
  State<_VirtualAccountBottomSheet> createState() =>
      _VirtualAccountBottomSheetState();
}

class _VirtualAccountBottomSheetState extends State<_VirtualAccountBottomSheet> {
  VirtualAccount? _account;
  bool _loading = true;
  String? _error;
  bool _needsBvn = false;
  final _bvnController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bvnController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _needsBvn = false;
    });
    try {
      final account = await context.read<AuthProvider>().getVirtualAccount();
      if (mounted) {
        setState(() {
          _account = account;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        final needsBvn = e.message.toLowerCase().contains('bvn');
        setState(() {
          _error = needsBvn ? null : e.message;
          _needsBvn = needsBvn;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load virtual account';
          _loading = false;
        });
      }
    }
  }

  Future<void> _submitBvn() async {
    final bvn = _bvnController.text.trim().replaceAll(RegExp(r'\s'), '');
    if (bvn.length != 11 || !RegExp(r'^\d{11}$').hasMatch(bvn)) {
      setState(() => _error = 'Enter a valid 11-digit BVN');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await context.read<AuthProvider>().submitBvn(bvn);
      if (mounted) await _load();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save BVN';
          _loading = false;
        });
      }
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'NGN Virtual Account',
                  style: AppTheme.header(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Transfer Naira to this account. It will be converted to USDC.',
                  style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_needsBvn) ...[
                  Text(
                    'BVN is required to create your permanent deposit account. Your data is encrypted and secure.',
                    style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _bvnController,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'BVN (11 digits)',
                      hintText: '•••••••••••',
                      counterText: '',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitBvn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Submit BVN & Get Account'),
                    ),
                  ),
                ]
                else if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626)),
                          ),
                        ),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (_account != null) ...[
                  _DetailRow(
                    label: 'Account Number',
                    value: _account!.accountNumber,
                    onCopy: () => _copy(_account!.accountNumber, 'Account number'),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Account Name',
                    value: _account!.accountName,
                    onCopy: () => _copy(_account!.accountName, 'Account name'),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Bank Name',
                    value: _account!.bankName,
                    onCopy: () => _copy(_account!.bankName, 'Bank name'),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: const Color(0xFF059669)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Use this account for bank transfers. Funds typically arrive within minutes.',
                            style: AppTheme.body(fontSize: 13, color: const Color(0xFF059669)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.body(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.body(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4F46E5),
            ),
          ),
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
