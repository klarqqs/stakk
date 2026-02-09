import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'package:stakk_savings/services/cache_service.dart';

/// Bills tab: Quick pay (Airtime, Data, DSTV, Electricity), categories, presets
class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  List<BillCategoryModel> _categories = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  WalletBalance? _balance;
  final _cacheService = CacheService();

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
    _loadWithCache();
  }

  /// Load cached data first, then refresh in background
  Future<void> _loadWithCache() async {
    if (!mounted) return;
    
    // Try to load cached data first
    await _loadFromCache();
    
    // Then refresh from API in background
    _load();
  }

  /// Load data from cache if available
  Future<void> _loadFromCache() async {
    try {
      final cachedCategories = await _cacheService.getBillCategories();
      final cachedBalance = await _cacheService.getBalance();
      
      if (cachedCategories != null && cachedBalance != null) {
        final categories = cachedCategories.map((c) => BillCategoryModel.fromJson(c)).toList();
        final balance = WalletBalance.fromJson({
          'database_balance': {'usdc': cachedBalance['usdc']},
          'stellar_address': cachedBalance['stellar_address'],
        });
        
        if (mounted) {
          setState(() {
            _categories = categories;
            _balance = balance;
            _loading = false; // Show cached data immediately
          });
        }
      }
    } catch (e) {
      // Silently fail - cache is optional
      print('Failed to load bills from cache: $e');
    }
  }

  Future<void> _load() async {
    if (_categories.isEmpty || _balance == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _refreshing = true;
      });
    }
    
    try {
      final auth = context.read<AuthProvider>();
      final results = await Future.wait([
        auth.getBillTopCategories(),
        auth.getBalance(),
      ]);
      if (mounted) {
        final categories = results[0] as List<BillCategoryModel>;
        final balance = results[1] as WalletBalance;
        
        // Cache the fresh data
        await _cacheService.setBillCategories(
          categories.map((c) => {
            'id': c.id,
            'code': c.code,
            'name': c.name,
            'description': c.description,
          }).toList(),
        );
        await _cacheService.setBalance({
          'usdc': balance.usdc,
          'stellar_address': balance.stellarAddress,
        });
        
        setState(() {
          _categories = categories;
          _balance = balance;
          _loading = false;
          _refreshing = false;
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
            _refreshing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load';
          _loading = false;
          _refreshing = false;
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
                      // Header with animation
                      Text(
                        'Bills',
                        style: AppTheme.header(context: context, fontSize: 32, fontWeight: FontWeight.w800),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms)
                          .slideY(begin: -0.2, end: 0, duration: 500.ms, delay: 100.ms, curve: Curves.easeOutCubic),
                      const SizedBox(height: 12),
                      Text(
                        'Pay airtime, data, DSTV, electricity with USDC',
                        style: AppTheme.body(context: context, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 200.ms)
                          .slideY(begin: -0.1, end: 0, duration: 500.ms, delay: 200.ms, curve: Curves.easeOutCubic),
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
                        const SizedBox(height: 32),
                        Text(
                          'Quick Pay',
                          style: AppTheme.title(context: context, fontSize: 20, fontWeight: FontWeight.w700),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 300.ms)
                            .slideX(begin: -0.1, end: 0, duration: 500.ms, delay: 300.ms, curve: Curves.easeOutCubic),
                        const SizedBox(height: 20),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.15,
                          children: _quickPayItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final cat = _findCategory(item.$3);
                            return _QuickPayCard(
                              icon: item.$2,
                              label: item.$1,
                              onTap: () => _navigateToCategory(
                                cat,
                                item.$1,
                                preSelectProvider: item.$1 == 'DSTV' ? 'DSTV' : null,
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 400.ms, delay: (400 + index * 100).ms)
                                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), duration: 500.ms, delay: (400 + index * 100).ms, curve: Curves.easeOutBack);
                          }).toList(),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'Airtime Quick Amounts',
                          style: AppTheme.title(context: context, fontSize: 20, fontWeight: FontWeight.w700),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 600.ms)
                            .slideX(begin: -0.1, end: 0, duration: 500.ms, delay: 600.ms, curve: Curves.easeOutCubic),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            for (var i = 0; i < _presets.length; i++) ...[
                              if (i > 0) const SizedBox(width: 12),
                              Expanded(
                                child: _PresetChip(
                                  amount: _presets[i],
                                  onTap: () {
                                    final cat = _findCategory('AIRTIME');
                                    if (cat != null) _navigateToCategory(cat, 'Airtime', presetAmount: _presets[i].toDouble());
                                  },
                                )
                                    .animate()
                                    .fadeIn(duration: 400.ms, delay: (700 + i * 80).ms)
                                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0), duration: 400.ms, delay: (700 + i * 80).ms, curve: Curves.easeOut),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'All Categories',
                          style: AppTheme.title(context: context, fontSize: 20, fontWeight: FontWeight.w700),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 900.ms)
                            .slideX(begin: -0.1, end: 0, duration: 500.ms, delay: 900.ms, curve: Curves.easeOutCubic),
                        const SizedBox(height: 16),
                        if (_categories.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Text(
                              'No bill categories available',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(context: context, fontSize: 15, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                            )
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 1000.ms),
                          )
                        else
                          ..._categories.asMap().entries.map((entry) {
                            final index = entry.key;
                            final c = entry.value;
                            return _CategoryTile(
                              category: c,
                              icon: _iconForCode(c.code),
                              onTap: () => _navigateToCategory(c, c.name),
                            )
                                .animate()
                                .fadeIn(duration: 400.ms, delay: (1000 + index * 50).ms)
                                .slideX(begin: -0.1, end: 0, duration: 500.ms, delay: (1000 + index * 50).ms, curve: Curves.easeOutCubic);
                          }),
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
    final primaryGradientEnd = isDark ? AppColors.primaryDark : AppColors.primaryGradientEnd;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceVariantDarkMuted
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Enhanced icon container with premium styling
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary.withValues(alpha: 0.2),
                      primaryGradientEnd.withValues(alpha: 0.1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primary.withValues(alpha: 0.3), width: 2),
                      ),
                    ),
                    // Icon
                    Icon(icon, size: 28, color: primary),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: AppTheme.body(
                  context: context,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDarkMuted : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: isDark 
                    ? AppColors.borderDark.withValues(alpha: 0.3) 
                    : AppColors.borderLight.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Enhanced gradient accent bar
                Container(
                  width: 5,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primary,
                        primary.withValues(alpha: 0.7),
                        primary.withValues(alpha: 0.4),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2.5),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                // Icon with background
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: primary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: AppTheme.body(
                          context: context,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (category.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          category.description,
                          style: AppTheme.caption(
                            context: context,
                            fontSize: 14,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
