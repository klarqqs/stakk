import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/constants/app_constants.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

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
            ? const Center(child: CircularProgressIndicator())
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
                          FilledButton(onPressed: _load, child: const Text('Retry')),
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
                          '100% Transparent. 100% On-Chain',
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
                            onPressed: () {
                              // Could open Stellar explorer
                            },
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.body(fontSize: 13, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 4),
            Text(value, style: AppTheme.header(context: context, fontSize: 22, fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: AppTheme.body(fontSize: 12, color: AppColors.success)),
            ],
          ],
        ),
      ),
    );
  }
}
