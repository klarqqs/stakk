import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/features/goals/presentation/screens/goals_screen.dart';
import 'package:stakk_savings/features/lock/presentation/screens/lock_screen.dart';
import 'package:stakk_savings/features/save/presentation/widgets/save_skeleton_loader.dart';
import 'package:stakk_savings/providers/auth_provider.dart';
import 'package:stakk_savings/services/cache_service.dart';

/// Wealth (Lending) tab - Blend lending + Savings Goals
/// Grow USDC through lending and goals
class WealthScreen extends StatefulWidget {
  const WealthScreen({super.key});

  @override
  State<WealthScreen> createState() => _WealthScreenState();
}

class _WealthScreenState extends State<WealthScreen> {
  List<SavingsGoal> _goals = [];
  List<LockedSaving> _locks = [];
  double _balance = 0;
  BlendEarningsResponse? _blendEarnings;
  BlendApyResponse? _blendApy;
  bool _loading = true;
  final _cacheService = CacheService();

  @override
  void initState() {
    super.initState();
    _loadWithCache();
  }

  Future<void> _loadWithCache() async {
    if (!mounted) return;
    await _loadFromCache();
    _load();
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedBalance = await _cacheService.getBalance();
      final cachedGoals = await _cacheService.getGoals();
      final cachedLocks = await _cacheService.getLocks();
      final cachedEarnings = await _cacheService.getBlendEarnings();
      final cachedApy = await _cacheService.getBlendApy();

      if (cachedBalance != null) {
        final balance = (cachedBalance['usdc'] as num).toDouble();
        final goals = cachedGoals?.map((g) => SavingsGoal.fromJson(g)).toList() ?? [];
        final locks = cachedLocks?.map((l) => LockedSaving.fromJson(l)).toList() ?? [];
        final earnings = cachedEarnings != null
            ? BlendEarningsResponse.fromJson(cachedEarnings)
            : null;
        final apy = cachedApy != null
            ? BlendApyResponse.fromJson(cachedApy)
            : null;

        if (mounted) {
          setState(() {
            _balance = balance;
            _goals = goals;
            _locks = locks;
            _blendEarnings = earnings;
            _blendApy = apy;
            _loading = false;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final valid = await _cacheService.isValid('balance') &&
          await _cacheService.isValid('goals') &&
          await _cacheService.isValid('locks');
      if (valid && _goals.isNotEmpty) return;
    }

    if (_goals.isEmpty) setState(() => _loading = true);

    try {
      final auth = context.read<AuthProvider>();
      final results = await Future.wait([
        auth.getBalance(),
        auth.goalsGetAll().catchError((_) => <SavingsGoal>[]),
        auth.lockedGetAll().catchError((_) => <LockedSaving>[]),
        auth.getBlendEarnings().catchError(
          (_) => BlendEarningsResponse(
            supplied: 0,
            earned: 0,
            currentAPY: 5.5,
            totalValue: 0,
            isEarning: false,
          ),
        ),
        auth.getBlendApy().catchError(
          (_) => BlendApyResponse(apy: '5.5', raw: 5.5),
        ),
      ]);

      if (!mounted) return;

      final balance = (results[0] as WalletBalance).usdc;
      final goals = results[1] as List<SavingsGoal>;
      final locks = results[2] as List<LockedSaving>;
      final earnings = results[3] as BlendEarningsResponse?;
      final apy = results[4] as BlendApyResponse?;

      await _cacheService.setBalance({
        'usdc': balance,
        'stellar_address': (results[0] as WalletBalance).stellarAddress,
      });
      await _cacheService.setGoals(
        goals.map((g) => {
          'id': g.id,
          'name': g.name,
          'target_amount': g.targetAmount,
          'current_amount': g.currentAmount,
          'deadline': g.deadline,
          'status': g.status,
        }).toList(),
      );
      await _cacheService.setLocks(
        locks.map((l) => {
          'id': l.id,
          'amount_usdc': l.amountUsdc,
          'lock_duration': l.lockDuration,
          'apy_rate': l.apyRate,
          'start_date': l.startDate,
          'maturity_date': l.maturityDate,
          'status': l.status,
          'interest_earned': l.interestEarned,
        }).toList(),
      );

      setState(() {
        _balance = balance;
        _goals = goals;
        _locks = locks;
        _blendEarnings = earnings;
        _blendApy = apy;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          child: _loading
              ? const SaveSkeletonLoader()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Wealth',
                        style: AppTheme.header(
                          context: context,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Grow your USDC through lending and goals',
                        style: AppTheme.body(
                          context: context,
                          fontSize: 16,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _FlexibleLendingCard(
                        balance: _balance,
                        earnings: _blendEarnings,
                        apy: _blendApy,
                        onRefresh: () => _load(forceRefresh: true),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Savings Goals',
                            style: AppTheme.title(
                              context: context,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GoalsScreen(),
                              ),
                            ).then((_) => _load()),
                            child: Text(
                              'See all',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _CreateGoalButton(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GoalsScreen(),
                          ),
                        ).then((_) => _load()),
                      ),
                      if (_goals.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ..._goals.take(3).map(
                          (g) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _GoalCard(
                              goal: g,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GoalDetailScreen(goalId: g.id),
                                ),
                              ).then((_) => _load()),
                            ),
                          ),
                        ),
                      ],
                      if (_locks.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Locked Savings',
                          style: AppTheme.header(
                            context: context,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._locks.map(
                          (l) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const FaIcon(FontAwesomeIcons.lock, color: AppColors.primary, size: 20),
                              title: Text(
                                '\$${l.amountUsdc.toStringAsFixed(2)}',
                                style: AppTheme.body(
                                  context: context,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${l.lockDuration} days • ${l.apyRate}% APY',
                                style: AppTheme.caption(context: context),
                              ),
                              trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 14),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LockScreen(balance: _balance),
                                ),
                              ).then((_) => _load()),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LockScreen(balance: _balance),
                          ),
                        ).then((_) => _load()),
                        icon: const FaIcon(FontAwesomeIcons.lock),
                        label: const Text('Lock Savings'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _FlexibleLendingCard extends StatelessWidget {
  final double balance;
  final BlendEarningsResponse? earnings;
  final BlendApyResponse? apy;
  final VoidCallback onRefresh;

  const _FlexibleLendingCard({
    required this.balance,
    required this.earnings,
    required this.apy,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isEarning = (earnings?.supplied ?? 0) > 0;
    final apyStr = apy?.apy ?? '5.5';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.15),
            primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.arrowTrendUp, color: primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    isEarning ? 'Earning $apyStr% APY' : 'Flexible Lending',
                    style: AppTheme.body(
                      context: context,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (isEarning)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$${(earnings?.supplied ?? 0).toStringAsFixed(2)}',
            style: AppTheme.balance(
              context: context,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isEarning && (earnings?.earned ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Text(
              "Earned \$${(earnings?.earned ?? 0).toStringAsFixed(2)}",
              style: AppTheme.body(
                context: context,
                fontSize: 14,
                color: AppColors.success,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showBlendSheet(context),
              child: Text(isEarning ? 'Manage' : 'Start Earning'),
            ),
          ),
        ],
      ),
    );
  }

  void _showBlendSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) => _BlendSheet(
        balance: balance,
        earnings: earnings,
        apy: apy,
        onSuccess: () {
          Navigator.pop(ctx);
          onRefresh();
        },
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }
}

class _BlendSheet extends StatefulWidget {
  final double balance;
  final BlendEarningsResponse? earnings;
  final BlendApyResponse? apy;
  final VoidCallback onSuccess;
  final VoidCallback onClose;

  const _BlendSheet({
    required this.balance,
    required this.earnings,
    required this.apy,
    required this.onSuccess,
    required this.onClose,
  });

  @override
  State<_BlendSheet> createState() => _BlendSheetState();
}

class _BlendSheetState extends State<_BlendSheet> {
  final _amountController = TextEditingController();
  bool _loading = false;

  double get _amount => double.tryParse(_amountController.text) ?? 0;
  bool get _isAmountValid => _amount > 0 && _amount <= widget.balance;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _enable() async {
    if (!_isAmountValid) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().blendEnable(_amount);
      if (!mounted) return;
      widget.onSuccess();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEarning = (widget.earnings?.supplied ?? 0) > 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEarning ? 'Manage Lending' : 'Start Earning',
                  style: AppTheme.header(
                    context: context,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const FaIcon(FontAwesomeIcons.xmark),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isEarning)
              Text(
                'Withdraw or add more to your Blend position.',
                style: AppTheme.body(context: context),
              )
            else
              Text(
                'Earn ~${widget.apy?.apy ?? '5.5'}% APY on your USDC.',
                style: AppTheme.body(context: context),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (USDC)',
                hintText: '0.00',
                suffixText: 'Max: \$${widget.balance.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _enable,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEarning ? 'Update' : 'Start Earning'),
              ),
            ),
          ],
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
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: FaIcon(FontAwesomeIcons.plus, color: primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Goal',
                      style: AppTheme.body(
                        context: context,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Save towards a target',
                      style: AppTheme.caption(context: context),
                    ),
                  ],
                ),
              ),
              FaIcon(FontAwesomeIcons.chevronRight, size: 12, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onTap;

  const _GoalCard({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceVariantDarkMuted
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.borderDark.withValues(alpha: 0.3)
                  : AppColors.borderLight.withValues(alpha: 0.4),
            ),
          ),
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
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.primaryDark
                      : AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${goal.currentAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)}',
                style: AppTheme.caption(context: context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
