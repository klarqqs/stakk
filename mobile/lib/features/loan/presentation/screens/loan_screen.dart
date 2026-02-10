import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

/// Loan (Borrowing) tab - Blend Protocol integration
/// Borrow USDC using savings as collateral
class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  double _collateral = 0;
  double _borrowed = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final balance = await auth.getBalance();
      final earnings = await auth.getBlendEarnings().catchError((_) => null);
      if (mounted) {
        setState(() {
          _collateral = earnings?.supplied ?? 0;
          _borrowed = 0; // TODO: Get from Blend position API
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _collateral = 0;
        _borrowed = 0;
      });
    }
  }

  double get _maxBorrow => _collateral * 0.5;
  double get _availableToBorrow => _maxBorrow - _borrowed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Loan',
                  style: AppTheme.header(
                    context: context,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Borrow USDC using your savings as collateral',
                  style: AppTheme.body(
                    context: context,
                    fontSize: 16,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 32),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  _Card(
                    title: 'Your Collateral',
                    subtitle: 'Amount in lending',
                    amount: _collateral,
                  ),
                  const SizedBox(height: 20),
                  _Card(
                    title: 'Available to Borrow',
                    subtitle: 'at ~7.5% APY',
                    amount: _availableToBorrow,
                    highlight: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _availableToBorrow > 0 ? _showBorrowSheet : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: Text(
                        _borrowed > 0 ? 'Repay Loan' : 'Borrow Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (_borrowed > 0) ...[
                    const SizedBox(height: 24),
                    _Card(
                      title: 'Active Loan',
                      subtitle: 'Total due',
                      amount: _borrowed,
                      isDebt: true,
                    ),
                  ],
                  const SizedBox(height: 32),
                  _HowItWorksSection(isDark: isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBorrowSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Borrow USDC',
                style: AppTheme.header(
                  context: context,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Max: \$${_availableToBorrow.toStringAsFixed(2)} USDC',
                style: AppTheme.caption(context: context),
              ),
              const SizedBox(height: 24),
              Text(
                'Blend borrowing integration coming soon. You will be able to borrow up to 50% of your collateral at competitive rates.',
                style: AppTheme.body(context: context, fontSize: 14),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final bool highlight;
  final bool isDebt;

  const _Card({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.highlight = false,
    this.isDebt = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlight
            ? primary.withValues(alpha: 0.12)
            : (isDark ? AppColors.surfaceVariantDarkMuted : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: highlight
            ? Border.all(color: primary.withValues(alpha: 0.5), width: 2)
            : Border.all(
                color: isDark
                    ? AppColors.borderDark.withValues(alpha: 0.3)
                    : AppColors.borderLight.withValues(alpha: 0.4),
                width: 1.5,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.body(
              context: context,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.caption(context: context),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: AppTheme.balance(
              context: context,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDebt ? AppColors.error : (highlight ? primary : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  final bool isDark;

  const _HowItWorksSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Keep earning on your savings',
      'Borrow up to 50% of balance',
      'No credit check needed',
      'Repay anytime',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDarkMuted
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark.withValues(alpha: 0.3)
              : AppColors.borderLight.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: AppTheme.title(
              context: context,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item,
                    style: AppTheme.body(context: context, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
