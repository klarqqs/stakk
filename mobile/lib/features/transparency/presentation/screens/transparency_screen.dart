import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/constants/app_constants.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/features/transparency/presentation/widgets/transparency_skeleton_loader.dart';
import 'package:stakk_savings/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TransparencyScreen extends StatefulWidget {
  const TransparencyScreen({super.key});

  @override
  State<TransparencyScreen> createState() => _TransparencyScreenState();
}

class _TransparencyScreenState extends State<TransparencyScreen> {
  TransparencyStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _openStellarExplorer(String address) async {
    final url = Uri.parse('https://stellar.expert/explorer/public/account/$address');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppWebView);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await context.read<AuthProvider>().transparencyGetStats();
      if (mounted) setState(() {
        _stats = stats;
        _loading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transparency')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const TransparencySkeletonLoader()
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '100% Transparent.\n100% On-Chain',
                          style: AppTheme.header(context: context, fontSize: 22, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Verify our reserves on the Stellar blockchain',
                          style: AppTheme.body(fontSize: 14, color: AppColors.textSecondaryLight),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        _StatCard(
                          label: 'Treasury USDC',
                          value: '\$${_stats!.treasuryUsdc.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 12),
                        _StatCard(
                          label: 'User Balances',
                          value: '\$${_stats!.totalUserBalances.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 12),
                        _StatCard(
                          label: 'Reserves Ratio',
                          value: '${_stats!.reservesRatio}%',
                          subtitle: 'Over-collateralized',
                        ),
                        const SizedBox(height: 12),
                        _StatCard(
                          label: 'Total Transactions',
                          value: '${_stats!.totalTransactions}',
                        ),
                        const SizedBox(height: 12),
                        _StatCard(
                          label: 'Saved from Devaluation',
                          value: '₦${AppConstants.formatNgn(_stats!.totalSavedNaira.round())}',
                        ),
                        const SizedBox(height: 32),
                        if (_stats!.treasuryAddress.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => _openStellarExplorer(_stats!.treasuryAddress),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Verify on Blockchain'),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  const _StatCard({required this.label, required this.value, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 28,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(label, style: AppTheme.body(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.header(context: context, fontSize: 22, fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTheme.body(fontSize: 12, color: AppColors.success)),
          ],
        ],
      ),
    );
  }
}
