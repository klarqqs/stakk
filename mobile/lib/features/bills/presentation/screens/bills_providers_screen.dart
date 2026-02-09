import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/features/bills/domain/models/bill_models.dart';
import 'package:stakk_savings/features/bills/presentation/widgets/bills_pay_sheet.dart';
import 'package:stakk_savings/features/bills/presentation/widgets/bills_providers_skeleton_loader.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class BillsProvidersScreen extends StatefulWidget {
  final BillCategoryModel category;
  final double balance;
  final double? presetAmount;
  final VoidCallback onSuccess;
  /// If set, opens pay sheet directly for first matching provider (e.g. 'DSTV' for quick pay)
  final String? preSelectProviderName;

  const BillsProvidersScreen({
    super.key,
    required this.category,
    required this.balance,
    this.presetAmount,
    required this.onSuccess,
    this.preSelectProviderName,
  });

  @override
  State<BillsProvidersScreen> createState() => _BillsProvidersScreenState();
}

class _BillsProvidersScreenState extends State<BillsProvidersScreen> {
  List<BillProviderModel> _providers = [];
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
      final providers = await context.read<AuthProvider>().getBillProviders(widget.category.code);
      if (mounted) {
        setState(() {
          _providers = providers;
          _loading = false;
        });
        final preSelect = widget.preSelectProviderName?.trim();
        if (preSelect != null && preSelect.isNotEmpty && providers.isNotEmpty) {
          BillProviderModel? match;
          for (final p in providers) {
            if (p.name.toLowerCase().contains(preSelect.toLowerCase())) {
              match = p;
              break;
            }
          }
          if (match != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openPaySheet(match!, popRouteOnClose: true);
            });
            return;
          }
        }
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
          _error = 'Failed to load providers';
          _loading = false;
        });
      }
    }
  }

  void _openPaySheet(BillProviderModel provider, {bool popRouteOnClose = false}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BillsPaySheet(
        category: widget.category,
        provider: provider,
        balance: widget.balance,
        presetAmount: widget.presetAmount,
        onClose: () => Navigator.of(ctx).pop(),
        onSuccess: () {
          Navigator.of(ctx).pop();
          widget.onSuccess();
        },
      ),
    ).then((_) {
      if (popRouteOnClose && mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.category.name,
          style: AppTheme.header(context: context, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const BillsProvidersSkeletonLoader()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with animation
                      Text(
                        'Select Provider',
                        style: AppTheme.header(context: context, fontSize: 28, fontWeight: FontWeight.w800),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms)
                          .slideY(begin: -0.2, end: 0, duration: 500.ms, delay: 100.ms, curve: Curves.easeOutCubic),
                      const SizedBox(height: 12),
                      Text(
                        'Choose your service provider',
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
                              Expanded(child: Text(_error!, style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626)))),
                              TextButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      ],
                      if (_error == null) ...[
                        const SizedBox(height: 32),
                        if (_providers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Text(
                              'No providers available',
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
                          ..._providers.asMap().entries.map((entry) {
                            final index = entry.key;
                            final p = entry.value;
                            return _ProviderTile(
                              provider: p,
                              onTap: () => _openPaySheet(p),
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

class _ProviderTile extends StatelessWidget {
  final BillProviderModel provider;
  final VoidCallback onTap;

  const _ProviderTile({required this.provider, required this.onTap});

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
                  child: Icon(Icons.business, color: primary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    provider.name,
                    style: AppTheme.body(
                      context: context,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
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
