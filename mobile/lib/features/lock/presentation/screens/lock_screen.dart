import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/components/inputs/amount_input.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/features/lock/presentation/widgets/lock_skeleton_loader.dart';
import 'package:stakk_savings/core/utils/snackbar_utils.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              Text('Balance: \$${widget.balance.toStringAsFixed(2)}', style: AppTheme.body(context: context, fontSize: 14)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Lock Now',
                  onPressed: () async {
                    final raw = controller.text.trim().replaceAll(',', '').replaceAll(' ', '');
                    final amt = double.tryParse(raw) ?? 0;
                    if (amt <= 0 || amt > widget.balance) {
                      showTopSnackBar(context, 'Enter a valid amount within your balance');
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      await context.read<AuthProvider>().lockedCreate(amt, duration);
                      _load();
                      if (mounted) showTopSnackBar(context, 'Funds locked successfully');
                    } on ApiException catch (e) {
                      if (mounted) showTopSnackBar(context, e.message);
                    }
                  },
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
            ? const LockSkeletonLoader()
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
                          return _LockDurationCard(
                            duration: dur,
                            apy: apy,
                            onTap: () => _showLockSheet(dur, apy),
                          );
                        }),
                        const SizedBox(height: 24),
                        Text('Active locks', style: AppTheme.header(context: context, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        if (_locks.isEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text('No active locks', style: AppTheme.body(context: context, fontSize: 14)),
                              ),
                            ),
                          )
                        else
                          ..._locks.map((l) => _LockCard(
                                lock: l,
                                onWithdraw: () async {
                                  try {
                                    await context.read<AuthProvider>().lockedWithdraw(l.id);
                                    _load();
                                    if (mounted) showTopSnackBar(context, 'Withdrawn');
                                  } on ApiException catch (e) {
                                    if (mounted) showTopSnackBar(context, e.message);
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

class _LockDurationCard extends StatelessWidget {
  final int duration;
  final double apy;
  final VoidCallback onTap;

  const _LockDurationCard({required this.duration, required this.apy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDarkMuted : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
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
                    gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$duration days', style: AppTheme.body(context: context, fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('$apy% APY', style: AppTheme.body(fontSize: 14, color: AppColors.success)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
              ],
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDarkMuted : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('\$${lock.amountUsdc.toStringAsFixed(2)}', style: AppTheme.body(context: context, fontSize: 18, fontWeight: FontWeight.w700)),
                          Text('${lock.apyRate}% APY', style: AppTheme.body(fontSize: 14, color: AppColors.success)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${lock.lockDuration} days • Matures: ${lock.maturityDate.length > 10 ? lock.maturityDate.substring(0, 10) : lock.maturityDate}', style: AppTheme.caption(context: context, fontSize: 12)),
                      if (lock.isMatured && lock.status == 'active') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(label: 'Withdraw', onPressed: onWithdraw),
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
  }
}
