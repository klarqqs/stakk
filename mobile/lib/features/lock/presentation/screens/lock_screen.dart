import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/components/inputs/amount_input.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class LockScreen extends StatefulWidget {
  final double balance;

  const LockScreen({super.key, required this.balance});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  List<LockedSaving> _locks = [];
  List<Map<String, dynamic>> _rates = [];
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
      final results = await Future.wait([
        context.read<AuthProvider>().lockedGetAll(),
        context.read<AuthProvider>().lockedGetRates(),
      ]);
      if (mounted) setState(() {
        _locks = results[0] as List<LockedSaving>;
        _rates = results[1] as List<Map<String, dynamic>>;
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

  void _showLockSheet(int duration, double apy) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Lock for $duration days', style: AppTheme.header(context: context, fontSize: 20, fontWeight: FontWeight.w700)),
              Text('$apy% APY', style: AppTheme.body(fontSize: 14, color: AppColors.success)),
              const SizedBox(height: 24),
              AmountInput(controller: controller, currencyPrefix: '\$', hintText: '0.00'),
              const SizedBox(height: 16),
              Text('Balance: \$${widget.balance.toStringAsFixed(2)}', style: AppTheme.body(fontSize: 14, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final amt = double.tryParse(controller.text) ?? 0;
                    if (amt <= 0 || amt > widget.balance) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      await context.read<AuthProvider>().lockedCreate(amt, duration);
                      _load();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funds locked successfully')));
                    } on ApiException catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  },
                  child: const Text('Lock Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lock Savings')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
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
                          FilledButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Choose duration', style: AppTheme.header(context: context, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ..._rates.map((r) {
                          final dur = r['duration'] as int? ?? 0;
                          final apy = (r['apy'] as num?)?.toDouble() ?? 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text('$dur days'),
                              subtitle: Text('$apy% APY'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => _showLockSheet(dur, apy),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                        Text('Active locks', style: AppTheme.header(context: context, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        if (_locks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text('No active locks', style: AppTheme.body(fontSize: 14, color: AppColors.textSecondaryLight)),
                          )
                        else
                          ..._locks.map((l) => _LockCard(
                                lock: l,
                                onWithdraw: () async {
                                  try {
                                    await context.read<AuthProvider>().lockedWithdraw(l.id);
                                    _load();
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawn')));
                                  } on ApiException catch (e) {
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                                  }
                                },
                              )),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _LockCard extends StatelessWidget {
  final LockedSaving lock;
  final VoidCallback onWithdraw;

  const _LockCard({required this.lock, required this.onWithdraw});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${lock.amountUsdc.toStringAsFixed(2)}', style: AppTheme.body(fontSize: 18, fontWeight: FontWeight.w700)),
                Text('${lock.apyRate}% APY', style: AppTheme.body(fontSize: 14, color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${lock.lockDuration} days • Matures: ${lock.maturityDate.length > 10 ? lock.maturityDate.substring(0, 10) : lock.maturityDate}', style: AppTheme.body(fontSize: 12, color: AppColors.textSecondaryLight)),
            if (lock.isMatured && lock.status == 'active') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: onWithdraw, child: const Text('Withdraw')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
