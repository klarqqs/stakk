import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/components/inputs/amount_input.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/core/theme/tokens/app_spacing.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class InvestScreen extends StatefulWidget {
  const InvestScreen({super.key});

  @override
  State<InvestScreen> createState() => _InvestScreenState();
}

class _InvestScreenState extends State<InvestScreen> {
  bool _loading = true;
  String? _error;
  BlendApyResponse? _apy;
  BlendEarningsResponse? _earnings;
  WalletBalance? _balance;
  final _amountController = TextEditingController();
  bool _actionLoading = false;

  double get _amountToInvest => double.tryParse(_amountController.text) ?? 0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

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
        auth.getBlendApy(),
        auth.getBlendEarnings(),
        auth.getBalance(),
      ]);
      if (mounted) {
        setState(() {
          _apy = results[0] as BlendApyResponse;
          _earnings = results[1] as BlendEarningsResponse;
          _balance = results[2] as WalletBalance;
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

  Future<void> _enableEarning() async {
    if (_amountToInvest <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter amount to invest')),
      );
      return;
    }
    final available = _balance?.usdc ?? 0;
    if (_amountToInvest > available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient USDC balance')),
      );
      return;
    }

    setState(() => _actionLoading = true);
    try {
      await context.read<AuthProvider>().blendEnable(_amountToInvest);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deposited \$${_amountToInvest.toStringAsFixed(2)} USDC to earn ${_apy?.apy ?? '5.5%'} APY')),
        );
        _amountController.clear();
        await _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to enable earning')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _disableEarning() async {
    final toWithdraw = _earnings?.supplied ?? 0;
    if (toWithdraw <= 0) return;

    setState(() => _actionLoading = true);
    try {
      await context.read<AuthProvider>().blendDisable(toWithdraw);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Withdrawn \$${toWithdraw.toStringAsFixed(2)} USDC from Blend')),
        );
        await _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to withdraw')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
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
                      Text(
                        'Earn',
                        style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Earn up to ${_apy?.apy ?? '5.5%'} APY on your USDC',
                        style: AppTheme.body(fontSize: 14, color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 32),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.errorBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.errorBorder),
                          ),
                          child: Text(
                            _error!,
                            style: AppTheme.body(fontSize: 14, color: AppColors.error),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      _EarningsCard(
                        apy: _apy?.apy ?? '5.5%',
                        earnings: _earnings,
                        balance: _balance,
                      ),
                      const SizedBox(height: 24),
                      if (_earnings?.isEarning == true) ...[
                        OutlinedButton.icon(
                          onPressed: _actionLoading ? null : _disableEarning,
                          icon: _actionLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.trending_down, size: 20),
                          label: Text(_actionLoading ? 'Withdrawing...' : 'Withdraw All'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Amount to invest',
                          style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        AmountInput(
                          controller: _amountController,
                          currencyPrefix: '\$',
                          hintText: '0.00',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _actionLoading ? null : _enableEarning,
                            icon: _actionLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.trending_up, size: 20),
                            label: Text(_actionLoading ? 'Depositing...' : 'Start Earning'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariantLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: AppColors.textSecondaryLight),
                                const SizedBox(width: 8),
                                Text(
                                  'How it works',
                                  style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your USDC is deposited into the Blend Protocol on Stellar. '
                              'Interest accrues daily and compounds automatically. '
                              'You can withdraw anytime with no lock-up.',
                              style: AppTheme.body(fontSize: 13, color: AppColors.textSecondaryLight),
                            ),
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

class _EarningsCard extends StatelessWidget {
  final String apy;
  final BlendEarningsResponse? earnings;
  final WalletBalance? balance;

  const _EarningsCard({
    required this.apy,
    this.earnings,
    this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final isEarning = earnings?.isEarning ?? false;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current APY',
                style: AppTheme.body(fontSize: 14, color: AppColors.textSecondaryLight),
              ),
              Text(
                apy,
                style: AppTheme.header(context: context, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isEarning) ...[
            _StatRow(label: 'Supplied', value: '\$${(earnings!.supplied).toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _StatRow(label: 'Earned', value: '+\$${(earnings!.earned).toStringAsFixed(2)}', valueColor: AppColors.success),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _StatRow(label: 'Total', value: '\$${(earnings!.totalValue).toStringAsFixed(2)}'),
          ] else ...[
            Text(
              'Available to invest',
              style: AppTheme.body(fontSize: 14, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${(balance?.usdc ?? 0).toStringAsFixed(2)} USDC',
              style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.body(fontSize: 14, color: AppColors.textSecondaryLight)),
        Text(
          value,
          style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor),
        ),
      ],
    );
  }
}
