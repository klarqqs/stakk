import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart' show ApiException, WalletBalance;
import 'package:stakk_savings/core/constants/app_constants.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/features/bills/domain/models/bill_models.dart';
import 'package:stakk_savings/features/bills/presentation/screens/bills_providers_screen.dart';
import 'package:stakk_savings/features/bills/presentation/widgets/bills_skeleton_loader.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

/// Bills tab: Quick pay (Airtime, Data, DSTV, Electricity), categories, presets
class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  List<BillCategoryModel> _categories = [];
  bool _loading = true;
  String? _error;
  WalletBalance? _balance;

  static const _quickPayItems = [
    ('Airtime', Icons.phone_android, 'AIRTIME'),
    ('Data', Icons.data_usage, 'MOBILEDATA'),
    ('DSTV', Icons.tv, 'CABLE'),
    ('Electricity', Icons.bolt, 'UTILITY'),
  ];

  static const _presets = [100, 500, 1000, 5000];

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
        auth.getBillTopCategories(),
        auth.getBalance(),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0] as List<BillCategoryModel>;
          _balance = results[1] as WalletBalance;
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load';
          _loading = false;
        });
      }
    }
  }

  BillCategoryModel? _findCategory(String code) {
    final upper = code.toUpperCase();
    for (final c in _categories) {
      if (c.code.toUpperCase().contains(upper) || upper.contains(c.code.toUpperCase())) {
        return c;
      }
    }
    return _categories.isNotEmpty ? _categories.first : null;
  }

  void _navigateToCategory(BillCategoryModel? category, String label, {double? presetAmount, String? preSelectProvider}) {
    if (category == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (ctx) => BillsProvidersScreen(
          category: category,
          balance: _balance?.usdc ?? 0,
          presetAmount: presetAmount,
          onSuccess: () => _load(),
          preSelectProviderName: preSelectProvider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const BillsSkeletonLoader()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Bills',
                        style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pay airtime, data, DSTV, electricity with USDC',
                        style: AppTheme.caption(context: context, fontSize: 14),
                      ),
                      // if (_balance != null) ...[
                      //   const SizedBox(height: 4),
                      //   Text(
                      //     'Balance: \$${_balance!.usdc.toStringAsFixed(2)} USDC ≈ ₦${AppConstants.formatNgn((_balance!.usdc * AppConstants.ngnUsdRate).round())}',
                      //     style: AppTheme.caption(context: context, fontSize: 13),
                      //   ),
                      // ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.errorBackground,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.errorBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(_error!, style: AppTheme.body(fontSize: 14, color: AppColors.error))),
                              TextButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      ],
                      if (_error == null) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Quick Pay',
                          style: AppTheme.title(context: context, fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.15,
                          children: _quickPayItems.map((item) {
                            final cat = _findCategory(item.$3);
                            return _QuickPayCard(
                              icon: item.$2,
                              label: item.$1,
                              onTap: () => _navigateToCategory(
                                cat,
                                item.$1,
                                preSelectProvider: item.$1 == 'DSTV' ? 'DSTV' : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        Text('Airtime quick amounts', style: AppTheme.title(context: context, fontSize: 18)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            for (var i = 0; i < _presets.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: _PresetChip(
                                  amount: _presets[i],
                                  onTap: () {
                                    final cat = _findCategory('AIRTIME');
                                    if (cat != null) _navigateToCategory(cat, 'Airtime', presetAmount: _presets[i].toDouble());
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text('All Categories', style: AppTheme.title(context: context, fontSize: 18)),
                        const SizedBox(height: 12),
                        if (_categories.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No bill categories available',
                              textAlign: TextAlign.center,
                              style: AppTheme.caption(context: context),
                            ),
                          )
                        else
                          ..._categories.map((c) => _CategoryTile(
                                category: c,
                                icon: _iconForCode(c.code),
                                onTap: () => _navigateToCategory(c, c.name),
                              )),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  IconData _iconForCode(String code) {
    final upper = code.toUpperCase();
    if (upper.contains('AIRTIME')) return Icons.phone_android;
    if (upper.contains('DATA') || upper.contains('MOBILEDATA')) return Icons.data_usage;
    if (upper.contains('CABLE') || upper.contains('TV')) return Icons.tv;
    if (upper.contains('UTILITY') || upper.contains('ELECTRIC')) return Icons.bolt;
    return Icons.receipt_long;
  }
}

class _QuickPayCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickPayCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceVariantDarkMuted
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: primary.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.25),
                      primary.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 24, color: primary),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: AppTheme.body(
                  context: context,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final int amount;
  final VoidCallback onTap;

  const _PresetChip({required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            border: Border.all(color: primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Center(
            child: Text(
              '₦${AppConstants.formatNgn(amount)}',
              style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.w500, color: primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final BillCategoryModel category;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.icon, required this.onTap});

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
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
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
                  height: 40,
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
                Icon(icon, color: primary, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name, style: AppTheme.body(context: context, fontSize: 16, fontWeight: FontWeight.w600)),
                      if (category.description.isNotEmpty)
                        Text(category.description, style: AppTheme.caption(context: context, fontSize: 13)),
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
