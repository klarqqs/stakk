import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/features/bills/domain/models/bill_models.dart';
import 'package:stakk_savings/features/bills/presentation/widgets/bills_pay_sheet.dart';
import 'package:stakk_savings/features/bills/presentation/widgets/bills_providers_skeleton_loader.dart';
import 'package:stakk_savings/providers/auth_provider.dart';
import 'package:stakk_savings/services/cache_service.dart';

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
      final cachedProviders = await _cacheService.getBillProviders(
        widget.category.code,
      );

      if (cachedProviders != null && cachedProviders.isNotEmpty) {
        final providers = cachedProviders
            .map((p) => BillProviderModel.fromJson(p))
            .toList();

        if (mounted) {
          setState(() {
            _providers = providers;
            _loading = false; // Show cached data immediately
          });
        }
      }
    } catch (e) {
      // Silently fail - cache is optional
      print('Failed to load bill providers from cache: $e');
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    // Check cache validity - skip API calls if cache is fresh
    if (!forceRefresh) {
      final providersCacheValid = await _cacheService.isValid(
        'bill_providers_${widget.category.code}',
      );

      // If cache is valid, skip API calls entirely
      if (providersCacheValid && _providers.isNotEmpty) {
        // Still check for preSelectProviderName even with cached data
        final preSelect = widget.preSelectProviderName?.trim();
        if (preSelect != null &&
            preSelect.isNotEmpty &&
            _providers.isNotEmpty) {
          BillProviderModel? match;
          for (final p in _providers) {
            if (p.name.toLowerCase().contains(preSelect.toLowerCase())) {
              match = p;
              break;
            }
          }
          if (match != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openPaySheet(match!, popRouteOnClose: true);
            });
          }
        }
        return;
      }
    }

    if (_providers.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final providers = await context.read<AuthProvider>().getBillProviders(
        widget.category.code,
      );
      if (mounted) {
        // Cache the fresh data
        await _cacheService.setBillProviders(
          widget.category.code,
          providers
              .map(
                (p) => {
                  'id': p.id,
                  'name': p.name,
                  'billerCode': p.billerCode,
                  'shortName': p.shortName,
                },
              )
              .toList(),
        );

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
        } else if (e.message.toLowerCase().contains('too many requests')) {
          // Silently handle 429 - use cached data
          setState(() {
            _loading = false;
            _error = null; // Don't show error if we have cached data
          });
        } else {
          // Only show error if we don't have cached data
          if (_providers.isEmpty) {
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
        if (_providers.isEmpty) {
          setState(() {
            _error = 'Failed to load providers';
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

  void _openPaySheet(
    BillProviderModel provider, {
    bool popRouteOnClose = false,
  }) {
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
          style: AppTheme.header(
            context: context,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          child: _loading
              ? const BillsProvidersSkeletonLoader()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          'Choose your service provider',
                          style: AppTheme.body(
                            context: context,
                            fontSize: 16,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
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
                                  style: AppTheme.body(
                                    fontSize: 14,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
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
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          )
                        else
                          ..._providers.map(
                            (p) => _ProviderTile(
                              provider: p,
                              onTap: () => _openPaySheet(p),
                            ),
                          ),
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
              color: isDark
                  ? AppColors.cardSurfaceDark
                  : AppColors.cardSurfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.building,
                      color: primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    provider.name,
                    style: AppTheme.body(
                      context: context,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ).copyWith(letterSpacing: -0.1),
                  ),
                ),
                FaIcon(
                  FontAwesomeIcons.chevronRight,
                  size: 12,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
