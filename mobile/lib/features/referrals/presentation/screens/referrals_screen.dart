import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/features/referrals/presentation/widgets/referrals_skeleton_loader.dart';
import 'package:stakk_savings/core/utils/snackbar_utils.dart';
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
      showTopSnackBar(context, 'Copied to clipboard');
    }
  }

  void _share() {
    if (_stats != null) {
      Clipboard.setData(ClipboardData(text: 'Join Stakk with my referral code: ${_stats!.code}'));
      showTopSnackBar(context, 'Referral link copied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Referrals', style: AppTheme.title(context: context, fontSize: 18).copyWith(letterSpacing: -0.3))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const ReferralsSkeletonLoader()
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.circleExclamation, size: 48, color: AppColors.error),
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
                        _ReferralCodeCard(
                          code: _stats!.code,
                          onCopy: _copyCode,
                          onShare: _share,
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

class _ReferralCodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _ReferralCodeCard({required this.code, required this.onCopy, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Container(
            width: 4,
            height: 24,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('Your Referral Code', style: AppTheme.body(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          const SizedBox(height: 8),
          Text(code, style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onCopy,
                icon: const FaIcon(FontAwesomeIcons.copy, size: 18),
                label: const Text('Copy'),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onShare,
                icon: const FaIcon(FontAwesomeIcons.shareNodes, size: 18),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
              ),
            ],
          ),
        ],
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
            height: 24,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(label, style: AppTheme.body(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.header(context: context, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
