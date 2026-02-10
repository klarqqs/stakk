import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:stakk_savings/core/components/inputs/amount_input.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/features/goals/presentation/widgets/goals_skeleton_loader.dart';
import 'package:stakk_savings/features/goals/presentation/widgets/goal_detail_skeleton_loader.dart';
import 'package:stakk_savings/core/utils/snackbar_utils.dart';
import 'package:stakk_savings/core/utils/error_message_formatter.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<SavingsGoal> _goals = [];
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
      final list = await context.read<AuthProvider>().goalsGetAll();
      if (mounted) {
        setState(() {
          _goals = list;
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
    } catch (e, st) {
      debugPrint('Goals load error: $e');
      debugPrint('Stack trace: $st');
      if (mounted) {
        setState(() {
          _error = _formatError(e);
          _loading = false;
        });
      }
    }
  }

  String _formatError(Object e) {
    return ErrorMessageFormatter.format(e);
  }

  void _showCreateGoal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (ctx) => _CreateGoalSheet(
        onSuccess: () {
          Navigator.pop(ctx);
          _load();
        },
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Savings Goals', style: AppTheme.title(context: context, fontSize: 18).copyWith(letterSpacing: -0.3)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const GoalsSkeletonLoader()
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.circleExclamation, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppTheme.body(
                          fontSize: 14,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(label: 'Retry', onPressed: _load),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_goals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.bullseye,
                            size: 56,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No goals yet',
                            style: AppTheme.header(
                              context: context,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a savings goal to start tracking your progress',
                            textAlign: TextAlign.center,
                            style: AppTheme.body(
                              fontSize: 14,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._goals.map(
                      (g) => _GoalCard(
                        goal: g,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GoalDetailScreen(goalId: g.id),
                          ),
                        ),
                        onSuccess: _load,
                      ),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _showCreateGoal,
                    icon: const FaIcon(FontAwesomeIcons.plus, size: 18),
                    label: const Text('Create New Goal'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onTap;
  final VoidCallback onSuccess;

  const _GoalCard({
    required this.goal,
    required this.onTap,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final cardSurface = isDark ? AppColors.cardSurfaceDark : AppColors.cardSurfaceLight;
    final progress = goal.progress;
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
              color: cardSurface,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.name,
                              style: AppTheme.body(
                                context: context,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (goal.deadline != null)
                            Text(
                              'Deadline: ${goal.deadline}',
                              style: AppTheme.caption(
                                context: context,
                                fontSize: 12,
                              ),
                            ),
                        ],
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
                          value: progress,
                          minHeight: 4,
                          backgroundColor: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceVariantLight,
                          valueColor: AlwaysStoppedAnimation<Color>(primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: AppTheme.body(
                    context: context,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
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

class _CreateGoalSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onClose;

  const _CreateGoalSheet({required this.onSuccess, required this.onClose});

  @override
  State<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<_CreateGoalSheet> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text) ?? 0;
    if (name.isEmpty) {
      setState(() => _error = 'Enter goal name');
      return;
    }
    if (target <= 0) {
      setState(() => _error = 'Enter valid target amount');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().goalsCreate({
        'name': name,
        'targetAmount': target,
      });
      widget.onSuccess();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _saving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to create goal';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Create Goal',
              style: AppTheme.header(
                context: context,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Goal name',
                hintText: 'e.g. Vacation fund',
              ),
            ),
            const SizedBox(height: 16),
            AmountInput(
              controller: _targetController,
              currencyPrefix: '\$',
              hintText: '0.00',
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: AppTheme.body(fontSize: 14, color: AppColors.error),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClose,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Create',
                    onPressed: _saving ? null : _create,
                    isLoading: _saving,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GoalDetailScreen extends StatefulWidget {
  final int goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  GoalDetail? _detail;
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
      final d = await context.read<AuthProvider>().goalsGetOne(widget.goalId);
      if (mounted) {
        setState(() {
          _detail = d;
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

  void _showAddMoney() {
    if (_detail == null) return;
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add to goal',
                style: AppTheme.header(
                  context: context,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              AmountInput(
                controller: controller,
                currencyPrefix: '\$',
                hintText: '0.00',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Add',
                  onPressed: () async {
                    final amt = double.tryParse(controller.text) ?? 0;
                    if (amt <= 0) return;
                    Navigator.pop(ctx);
                    try {
                      await context.read<AuthProvider>().goalsContribute(
                        widget.goalId,
                        amt,
                      );
                      _load();
                    } on ApiException catch (e) {
                      if (mounted) showTopSnackBar(context, e.message);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text('Goal Details'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _loading
          ? const GoalDetailSkeletonLoader()
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTheme.body(
                        fontSize: 14,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(label: 'Retry', onPressed: _load),
                    ),
                  ],
                ),
              ),
            )
          : _detail == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDarkMuted
                          : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark.withValues(alpha: 0.4)
                            : AppColors.borderLight.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.15 : 0.03,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _detail!.goal.progress,
                                strokeWidth: 10,
                                backgroundColor: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceVariantLight,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primary,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  '${(_detail!.goal.progress * 100).toStringAsFixed(0)}%',
                                  style: AppTheme.header(
                                    context: context,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _detail!.goal.name,
                          style: AppTheme.header(
                            context: context,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${_detail!.goal.currentAmount.toStringAsFixed(2)} / \$${_detail!.goal.targetAmount.toStringAsFixed(2)}',
                          style: AppTheme.body(context: context, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _showAddMoney,
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Add Money'),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final amt = _detail!.goal.currentAmount;
                            if (amt <= 0) return;
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Withdraw'),
                                content: Text(
                                  'Withdraw \$${amt.toStringAsFixed(2)} from this goal?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Withdraw'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && mounted) {
                              try {
                                await context
                                    .read<AuthProvider>()
                                    .goalsWithdraw(widget.goalId, amt);
                                _load();
                                if (mounted) Navigator.pop(context);
                              } on ApiException catch (e) {
                                if (mounted) showTopSnackBar(context, e.message);
                              }
                            }
                          },
                          icon: const Icon(Icons.remove_rounded, size: 20),
                          label: const Text('Withdraw'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primary,
                            side: BorderSide(
                              color: primary.withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Contributions',
                    style: AppTheme.header(
                      context: context,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_detail!.contributions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No contributions yet',
                        style: AppTheme.caption(context: context, fontSize: 14),
                      ),
                    )
                  else
                    ..._detail!.contributions.map(
                      (c) => _ContributionTile(
                        amount: c.amountUsdc,
                        source: c.source,
                        date: c.createdAt.length > 10
                            ? c.createdAt.substring(0, 10)
                            : c.createdAt,
                        isDark: isDark,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _ContributionTile extends StatelessWidget {
  final double amount;
  final String source;
  final String date;
  final bool isDark;

  const _ContributionTile({
    required this.amount,
    required this.source,
    required this.date,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDarkMuted : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
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
              height: 40,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: AppTheme.body(
                      context: context,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    source,
                    style: AppTheme.caption(context: context, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(date, style: AppTheme.caption(context: context, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
