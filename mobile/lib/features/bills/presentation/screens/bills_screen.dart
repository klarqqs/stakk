import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart' show ApiException, WalletBalance;
import 'package:stakk_savings/core/constants/app_constants.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/features/bills/domain/models/bill_models.dart';
import 'package:stakk_savings/features/bills/presentation/screens/bills_providers_screen.dart';
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

  void _navigateToCategory(BillCategoryModel? category, String label) {
    if (category == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (ctx) => BillsProvidersScreen(
          category: category,
          balance: _balance?.usdc ?? 0,
          onSuccess: () => _load(),
        ),
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
                      if (_balance != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Balance: \$${_balance!.usdc.toStringAsFixed(2)} USDC ≈ ₦${AppConstants.formatNgn((_balance!.usdc * AppConstants.ngnUsdRate).round())}',
                          style: AppTheme.caption(context: context, fontSize: 13),
                        ),
                      ],
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
                        Text('Quick Pay', style: AppTheme.title(context: context, fontSize: 18)),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.2,
                          children: _quickPayItems.map((item) {
                            final cat = _findCategory(item.$3);
                            return _QuickPayCard(
                              icon: item.$2,
                              label: item.$1,
                              onTap: () => _navigateToCategory(cat, item.$1),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Text('Amount Presets', style: AppTheme.title(context: context, fontSize: 18)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _presets.map((p) => _PresetChip(
                                amount: p,
                                onTap: () {
                                  final cat = _categories.isNotEmpty ? _categories.first : null;
                                  if (cat != null) _navigateToCategory(cat, '');
                                },
                              )).toList(),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceVariantDark : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(label, style: AppTheme.body(context: context, fontSize: 15, fontWeight: FontWeight.w600)),
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
    return ActionChip(
      label: Text('₦${AppConstants.formatNgn(amount)}'),
      onPressed: onTap,
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
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
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
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
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
