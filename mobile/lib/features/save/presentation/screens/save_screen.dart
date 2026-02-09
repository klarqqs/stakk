import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/components/error_banner.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/providers/auth_provider.dart';
import 'package:stakk_savings/features/goals/presentation/screens/goals_screen.dart';
import 'package:stakk_savings/core/utils/snackbar_utils.dart';
import 'package:stakk_savings/features/lock/presentation/screens/lock_screen.dart';
import 'package:stakk_savings/features/save/presentation/widgets/save_skeleton_loader.dart';

/// Save tab: Goals, Lock savings, Ajo (group savings)
class SaveScreen extends StatefulWidget {
  const SaveScreen({super.key});

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  List<SavingsGoal> _goals = [];
  List<LockedSaving> _locks = [];
  double _balance = 0;
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
      final auth = context.read<AuthProvider>();
      final results = await Future.wait([
        auth.getBalance(),
        auth.goalsGetAll().catchError((_) => <SavingsGoal>[]),
        auth.lockedGetAll().catchError((_) => <LockedSaving>[]),
      ]);
      if (mounted) {
        setState(() {
          _balance = (results[0] as WalletBalance).usdc;
          _goals = results[1] as List<SavingsGoal>;
          _locks = results[2] as List<LockedSaving>;
          _loading = false;
        });
      }
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
      body: SafeArea(bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const SaveSkeletonLoader()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Save',
                        style: AppTheme.header(
                          context: context,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Goals, lock savings & group savings',
                        style: AppTheme.caption(context: context, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null) ...[
                        ErrorBanner(message: _error!, onRetry: _load),
                        const SizedBox(height: 24),
                      ],
                      _CreateGoalButton(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GoalsScreen(),
                          ),
                        ).then((_) => _load()),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Savings Goals',
                        style: AppTheme.title(context: context, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      if (_goals.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No goals yet. Tap the button above to create one.',
                              textAlign: TextAlign.center,
                              style: AppTheme.caption(
                                context: context,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._goals
                            .take(3)
                            .map(
                              (g) => _SavingsGoalCard(
                                goal: g,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GoalDetailScreen(goalId: g.id),
                                  ),
                                ).then((_) => _load()),
                              ),
                            ),
                      if (_goals.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GoalsScreen(),
                              ),
                            ),
                            child: const Text('View all goals'),
                          ),
                        ),
                      const SizedBox(height: 32),
                      Text(
                        'Lock Savings',
                        style: AppTheme.title(context: context, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      _LockSavingsCard(
                        activeLocks: _locks.length,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LockScreen(balance: _balance),
                          ),
                        ).then((_) => _load()),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Group Savings (Ajo)',
                        style: AppTheme.title(context: context, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      _AjoComingSoonCard(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _CreateGoalButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateGoalButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Goal',
                      style: AppTheme.header(
                        context: context,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Save towards a target',
                      style: AppTheme.caption(
                        context: context,
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingsGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onTap;

  const _SavingsGoalCard({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDarkMuted : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark.withValues(alpha: 0.4)
                    : AppColors.borderLight.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: AppTheme.body(
                          context: context,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\$${goal.currentAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}',
                        style: AppTheme.caption(context: context, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: goal.progress,
                          minHeight: 4,
                          backgroundColor: (isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceVariantLight),
                          valueColor: AlwaysStoppedAnimation<Color>(primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(goal.progress * 100).toStringAsFixed(0)}%',
                      style: AppTheme.body(
                        context: context,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockSavingsCard extends StatelessWidget {
  final int activeLocks;
  final VoidCallback onTap;

  const _LockSavingsCard({required this.activeLocks, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDarkMuted : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark.withValues(alpha: 0.4)
                  : AppColors.borderLight.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lock Savings',
                      style: AppTheme.body(
                        context: context,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '6-9% APY • 30-180 days',
                      style: AppTheme.caption(context: context),
                    ),
                    if (activeLocks > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '$activeLocks active',
                          style: AppTheme.caption(
                            context: context,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AjoComingSoonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showTopSnackBar(context, "We'll notify you when Ajo is ready!");
        },
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDarkMuted : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark.withValues(alpha: 0.4)
                  : AppColors.borderLight.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Group Savings (Ajo)', style: AppTheme.body(context: context, fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text('Coming soon', style: AppTheme.caption(context: context, fontSize: 12, fontWeight: FontWeight.w600, color: primary)),
                    ),
                    const SizedBox(height: 8),
                    Text('Create or join savings circles with automated contributions.', style: AppTheme.caption(context: context), textAlign: TextAlign.left),
                    const SizedBox(height: 8),
                    Text('Tap to get notified when it\'s ready', style: AppTheme.caption(context: context, fontSize: 13, color: primary)),
                  ],
                ),
              ),
              Icon(Icons.groups_rounded, size: 36, color: primary.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

