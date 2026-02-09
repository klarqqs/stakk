import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/api/api_client.dart' show ApiException, WalletBalance;
import 'package:stakk_savings/features/bills/domain/models/bill_models.dart';
import 'package:stakk_savings/features/bills/presentation/screens/bills_providers_screen.dart';
import 'package:stakk_savings/features/bills/presentation/widgets/bills_categories_skeleton_loader.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

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
          onRefresh: _load,
          child: _loading
              ? const BillsCategoriesSkeletonLoader()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: AppTheme.body(
                          context: context,
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 200.ms)
                          .slideY(begin: -0.1, end: 0, duration: 500.ms, delay: 200.ms, curve: Curves.easeOutCubic),
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
                            )
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 300.ms),
                          )
                        else
                          ..._categories.asMap().entries.map((entry) {
                            final index = entry.key;
                            final c = entry.value;
                            return _CategoryTile(
                              category: c,
                              icon: _categoryIcon(c),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (ctx) => BillsProvidersScreen(
                                    category: c,
                                    balance: _balance?.usdc ?? 0,
                                    onSuccess: () => _load(),
                                  ),
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 400.ms, delay: (300 + index * 50).ms)
                                .slideX(begin: -0.1, end: 0, duration: 500.ms, delay: (300 + index * 50).ms, curve: Curves.easeOutCubic);
                          }),
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
