import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/providers/auth_provider.dart';
import 'package:stakk_savings/features/goals/presentation/screens/goals_screen.dart';
import 'package:stakk_savings/features/lock/presentation/screens/lock_screen.dart';

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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Save',
                        style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Goals, lock savings & group savings',
                        style: AppTheme.caption(context: context, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null) ...[
                        _ErrorBanner(message: _error!),
                        const SizedBox(height: 24),
                      ],
                      _CreateGoalButton(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())).then((_) => _load())),
                      const SizedBox(height: 24),
                      Text('Savings Goals', style: AppTheme.title(context: context, fontSize: 18)),
                      const SizedBox(height: 12),
                      if (_goals.isEmpty)
                        _EmptyCard(
                          icon: Icons.flag_outlined,
                          message: 'No goals yet',
                          action: 'Create Goal',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
                        )
                      else
                        ..._goals.take(3).map((g) => _SavingsGoalCard(goal: g, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())))),
                      if (_goals.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
                            child: const Text('View all goals'),
                          ),
                        ),
                      const SizedBox(height: 32),
                      Text('Lock Savings', style: AppTheme.title(context: context, fontSize: 18)),
                      const SizedBox(height: 12),
                      _LockSavingsCard(
                        activeLocks: _locks.length,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LockScreen(balance: _balance))).then((_) => _load()),
                      ),
                      const SizedBox(height: 32),
                      Text('Group Savings (Ajo)', style: AppTheme.title(context: context, fontSize: 18)),
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create Goal', style: AppTheme.header(context: context, fontSize: 18, color: Colors.white)),
                    Text('Save towards a target', style: AppTheme.caption(context: context, fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(goal.name, style: AppTheme.body(context: context, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${(goal.progress * 100).toStringAsFixed(0)}%', style: AppTheme.body(context: context, fontSize: 14, color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: goal.progress, minHeight: 8, borderRadius: BorderRadius.circular(4), backgroundColor: AppColors.surfaceVariantLight),
              const SizedBox(height: 8),
              Text(
                '\$${goal.currentAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)}',
                style: AppTheme.caption(context: context, fontSize: 13),
              ),
            ],
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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_outline, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lock Savings', style: AppTheme.body(context: context, fontSize: 16, fontWeight: FontWeight.w600)),
                    Text('6-9% APY • 30-180 days', style: AppTheme.caption(context: context)),
                    if (activeLocks > 0) Text('$activeLocks active lock(s)', style: AppTheme.caption(context: context, fontSize: 12, color: AppColors.success)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.groups_outlined, size: 48, color: AppColors.textTertiaryLight),
            const SizedBox(height: 16),
            Text('Group Savings (Ajo)', style: AppTheme.body(context: context, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Create or join savings circles with automated contributions. Coming soon.', style: AppTheme.caption(context: context), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String action;
  final VoidCallback onTap;

  const _EmptyCard({required this.icon, required this.message, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.textTertiaryLight),
            const SizedBox(height: 16),
            Text(message, style: AppTheme.body(context: context)),
            const SizedBox(height: 12),
            TextButton(onPressed: onTap, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Text(message, style: AppTheme.body(fontSize: 14, color: AppColors.error)),
    );
  }
}
