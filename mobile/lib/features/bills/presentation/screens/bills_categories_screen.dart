import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/api/api_client.dart' show ApiException, WalletBalance;
import 'package:stakk_savings/features/bills/domain/models/bill_models.dart';
import 'package:stakk_savings/features/bills/presentation/screens/bills_providers_screen.dart';
import 'package:stakk_savings/features/bills/presentation/widgets/bills_categories_skeleton_loader.dart';
import 'package:stakk_savings/providers/auth_provider.dart';
import 'package:stakk_savings/services/cache_service.dart';

class BillsCategoriesScreen extends StatefulWidget {
  const BillsCategoriesScreen({super.key});

  @override
  State<BillsCategoriesScreen> createState() => _BillsCategoriesScreenState();
}

class _BillsCategoriesScreenState extends State<BillsCategoriesScreen> {
  List<BillCategoryModel> _categories = [];
  bool _loading = true;
  String? _error;
  WalletBalance? _balance;
  final _cacheService = CacheService();

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
      print('Failed to load bills categories from cache: $e');
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    // Check cache validity - skip API calls if cache is fresh
    if (!forceRefresh) {
      final categoriesCacheValid = await _cacheService.isValid('bill_categories');
      final balanceCacheValid = await _cacheService.isValid('balance');
      
      // If both caches are valid, skip API calls entirely
      if (categoriesCacheValid && balanceCacheValid) {
        return;
      }
    }
    
    if (_categories.isEmpty || _balance == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    
    try {
      final auth = context.read<AuthProvider>();
      // Space out requests slightly
      final results = await Future.wait([
        Future.delayed(const Duration(milliseconds: 0), () => auth.getBillTopCategories()),
        Future.delayed(const Duration(milliseconds: 50), () => auth.getBalance()),
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
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.message == 'Session expired') {
          await context.read<AuthProvider>().handleSessionExpired(context);
        } else if (e.message.toLowerCase().contains('too many requests')) {
          // Silently handle 429 - use cached data
          setState(() {
            _loading = false;
            _error = null; // Don't show error if we have cached data
          });
        } else {
          // Only show error if we don't have cached data
          if (_categories.isEmpty && _balance == null) {
            setState(() {
              _error = e.message;
              _loading = false;
            });
          } else {
            setState(() {
              _loading = false;
              _error = null; // Keep using cached data
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Only show error if we don't have cached data
        if (_categories.isEmpty && _balance == null) {
          setState(() {
            _error = 'Failed to load';
            _loading = false;
          });
        } else {
          setState(() {
            _loading = false;
            _error = null; // Keep using cached data
          });
        }
      }
    }
  }

  IconData _categoryIcon(BillCategoryModel c) {
    final code = c.code.toUpperCase();
    if (code.contains('AIRTIME')) return Icons.phone_android;
    if (code.contains('MOBILEDATA') || code.contains('DATA')) return Icons.data_usage;
    if (code.contains('CABLE') || code.contains('TV')) return Icons.tv;
    if (code.contains('UTILITY') || code.contains('ELECTRIC')) return Icons.bolt;
    if (code.contains('BET') || code.contains('BETTING')) return Icons.sports_esports;
    return Icons.receipt_long;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          child: _loading
              ? const BillsCategoriesSkeletonLoader()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bills',
                        style: AppTheme.header(context: context, fontSize: 32, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pay airtime, data, DSTV, electricity with USDC',
                        style: AppTheme.body(
                          context: context,
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
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
                              TextButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      ],
                      if (_error == null) ...[
                        const SizedBox(height: 32),
                        if (_categories.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Text(
                              'No bill categories available',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(
                                context: context,
                                fontSize: 15,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          )
                        else
                          ..._categories.map((c) => _CategoryTile(
                            category: c,
                            icon: _categoryIcon(c),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (ctx) => BillsProvidersScreen(
                                  category: c,
                                  balance: _balance?.usdc ?? 0,
                                  onSuccess: () => _load(forceRefresh: true),
                                ),
                              ),
                            ),
                          )),
                      ],
                    ],
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

  const _CategoryTile({
    required this.category,
    required this.icon,
    required this.onTap,
  });

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
                // Icon with premium background
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary.withValues(alpha: 0.15),
                        primary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
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
