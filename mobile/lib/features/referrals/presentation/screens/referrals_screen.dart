import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  ReferralStats? _stats;
  List<Map<String, dynamic>> _leaderboard = [];
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
      final results = await Future.wait([
        context.read<AuthProvider>().referralsGetMine(),
        context.read<AuthProvider>().referralsGetLeaderboard(),
      ]);
      if (mounted) setState(() {
        _stats = results[0] as ReferralStats;
        _leaderboard = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _error = 'Failed to load';
        _loading = false;
      });
    }
  }

  void _copyCode() {
    if (_stats != null) {
      Clipboard.setData(ClipboardData(text: _stats!.code));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }

  void _share() {
    if (_stats != null) {
      Clipboard.setData(ClipboardData(text: 'Join Stakk with my referral code: ${_stats!.code}'));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral link copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Referrals')),
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
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text('Your Referral Code', style: AppTheme.body(fontSize: 14, color: AppColors.textSecondaryLight)),
                                const SizedBox(height: 8),
                                Text(_stats!.code, style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FilledButton.icon(onPressed: _copyCode, icon: const Icon(Icons.copy, size: 18), label: const Text('Copy')),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(onPressed: _share, icon: const Icon(Icons.share, size: 18), label: const Text('Share')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(label: 'Referred', value: '${_stats!.totalReferred}'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(label: 'Earned', value: '\$${_stats!.paidRewards.toStringAsFixed(2)}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text('How it works', style: AppTheme.header(context: context, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Text('Share your code with friends. When they sign up and deposit ₦10,000+, you earn \$1 USDC.', style: AppTheme.body(fontSize: 14, color: AppColors.textSecondaryLight)),
                        const SizedBox(height: 32),
                        Text('Leaderboard', style: AppTheme.header(context: context, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ..._leaderboard.asMap().entries.map((e) {
                          final i = e.key;
                          final r = e.value;
                          return ListTile(
                            leading: CircleAvatar(child: Text('${i + 1}')),
                            title: Text('User #${r['userId'] ?? ''}'),
                            trailing: Text('${r['totalReferred'] ?? 0} refs'),
                          );
                        }),
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

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.body(fontSize: 12, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 4),
            Text(value, style: AppTheme.header(context: context, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
