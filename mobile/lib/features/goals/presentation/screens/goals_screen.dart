import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/core/components/inputs/amount_input.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
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
      if (mounted) setState(() {
        _goals = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _error = 'Failed to load goals';
        _loading = false;
      });
    }
  }

  void _showCreateGoal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl))),
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
      appBar: AppBar(title: const Text('Savings Goals')),
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
                          Text(_error!, textAlign: TextAlign.center, style: AppTheme.body(fontSize: 14, color: AppColors.error)),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _load, child: const Text('Retry')),
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
                              Icon(Icons.flag_outlined, size: 64, color: AppColors.textTertiaryLight),
                              const SizedBox(height: 16),
                              Text('No goals yet', style: AppTheme.header(context: context, fontSize: 18, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text('Create a savings goal to start tracking your progress', textAlign: TextAlign.center, style: AppTheme.body(fontSize: 14, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        )
                      else
                        ..._goals.map((g) => _GoalCard(
                              goal: g,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: g.id))),
                              onSuccess: _load,
                            )),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _showCreateGoal,
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Goal'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
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

  const _GoalCard({required this.goal, required this.onTap, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
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
                  Text(goal.name, style: AppTheme.body(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (goal.deadline != null)
                    Text(
                      'Deadline: ${goal.deadline}',
                      style: AppTheme.body(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 8),
              Text(
                '\$${goal.currentAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)} (${(progress * 100).toStringAsFixed(0)}%)',
                style: AppTheme.body(fontSize: 13, color: AppColors.textSecondaryLight),
              ),
            ],
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
      if (mounted) setState(() {
        _error = e.message;
        _saving = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _error = 'Failed to create goal';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create Goal', style: AppTheme.header(context: context, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Goal name', hintText: 'e.g. Vacation fund'),
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
              Text(_error!, style: AppTheme.body(fontSize: 14, color: AppColors.error)),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: widget.onClose, child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _create,
                    child: _saving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create'),
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
      if (mounted) setState(() {
        _detail = d;
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

  void _showAddMoney() {
    if (_detail == null) return;
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add to goal', style: AppTheme.header(context: context, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              AmountInput(controller: controller, currencyPrefix: '\$', hintText: '0.00'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final amt = double.tryParse(controller.text) ?? 0;
                    if (amt <= 0) return;
                    Navigator.pop(ctx);
                    try {
                      await context.read<AuthProvider>().goalsContribute(widget.goalId, amt);
                      _load();
                    } on ApiException catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  },
                  child: const Text('Add'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Goal Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: AppTheme.body(fontSize: 14, color: AppColors.error)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _detail == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
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
                                  strokeWidth: 8,
                                  backgroundColor: AppColors.surfaceVariantLight,
                                ),
                                Text(
                                  '${(_detail!.goal.progress * 100).toStringAsFixed(0)}%',
                                  style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(_detail!.goal.name, style: AppTheme.header(context: context, fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            '\$${_detail!.goal.currentAmount.toStringAsFixed(2)} / \$${_detail!.goal.targetAmount.toStringAsFixed(2)}',
                            style: AppTheme.body(fontSize: 16, color: AppColors.textSecondaryLight),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(child: FilledButton.icon(onPressed: _showAddMoney, icon: const Icon(Icons.add), label: const Text('Add Money'))),
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
                                        content: Text('Withdraw \$${amt.toStringAsFixed(2)} from this goal?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Withdraw')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true && mounted) {
                                      try {
                                        await context.read<AuthProvider>().goalsWithdraw(widget.goalId, amt);
                                        _load();
                                        if (mounted) Navigator.pop(context);
                                      } on ApiException catch (e) {
                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.remove),
                                  label: const Text('Withdraw'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text('Contributions', style: AppTheme.header(context: context, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          ..._detail!.contributions.map((c) => ListTile(
                                title: Text('\$${c.amountUsdc.toStringAsFixed(2)}'),
                                subtitle: Text(c.source),
                                trailing: Text(c.createdAt.length > 10 ? c.createdAt.substring(0, 10) : c.createdAt),
                              )),
                        ],
                      ),
                    ),
    );
  }
}
