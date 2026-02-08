import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stakk_savings/core/components/slide_to_action/slide_to_action.dart';
import 'package:stakk_savings/core/constants/app_constants.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/core/utils/bank_account_validation.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/features/goals/presentation/screens/goals_screen.dart';
import 'package:stakk_savings/features/lock/presentation/screens/lock_screen.dart';
import 'package:stakk_savings/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:stakk_savings/features/referrals/presentation/screens/referrals_screen.dart';
import 'package:stakk_savings/features/send/presentation/screens/p2p_history_screen.dart';
import 'package:stakk_savings/features/send/presentation/screens/send_p2p_screen.dart';
import 'package:stakk_savings/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String? _error;
  WalletBalance? _balance;
  List<Transaction> _transactions = [];
  List<P2pTransfer> _p2pTransfers = [];
  int _unreadNotifications = 0;
  BlendEarningsResponse? _blendEarnings;
  BlendApyResponse? _blendApy;
  List<SavingsGoal> _goals = [];

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
        auth.getTransactions(),
        auth.p2pGetHistory().catchError((_) => <P2pTransfer>[]),
        auth.notificationsGetUnreadCount().catchError((_) => 0),
        auth.getBlendEarnings().catchError((_) => BlendEarningsResponse(supplied: 0, earned: 0, currentAPY: 5.5, totalValue: 0, isEarning: false)),
        auth.getBlendApy().catchError((_) => BlendApyResponse(apy: '5.5', raw: 5.5)),
        auth.goalsGetAll().catchError((_) => <SavingsGoal>[]),
      ]);
      setState(() {
        _balance = results[0] as WalletBalance;
        _transactions = (results[1] as TransactionsResponse).transactions;
        _p2pTransfers = results[2] as List<P2pTransfer>;
        _unreadNotifications = results[3] as int;
        _blendEarnings = results[4] as BlendEarningsResponse?;
        _blendApy = results[5] as BlendApyResponse?;
        _goals = results[6] as List<SavingsGoal>;
      });
    } on ApiException catch (e) {
      if (e.message == 'Session expired') {
        if (mounted) await context.read<AuthProvider>().handleSessionExpired(context);
      } else if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load data');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFundSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) => _FundOptionsSheet(
        onClose: () => Navigator.of(ctx).pop(),
        stellarAddress: _balance?.stellarAddress,
      ),
    );
  }

  void _showSendSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) => _SendOptionsSheet(
        balance: _balance?.usdc ?? 0,
        onClose: () => Navigator.of(ctx).pop(),
        onSuccess: () => _load(),
      ),
    );
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stakk',
                            style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            icon: Badge(
                              label: _unreadNotifications > 0 ? Text('$_unreadNotifications') : null,
                              child: const Icon(Icons.notifications_outlined),
                            ),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())).then((_) => _load()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Text(
                            _error!,
                            style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626)),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (_balance != null) ...[
                        _BalanceCard(balance: _balance!),
                        const SizedBox(height: 16),
                        _BlendEarningsCard(
                          earnings: _blendEarnings,
                          apy: _blendApy,
                          balance: _balance!.usdc,
                          onRefresh: _load,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showFundSheet(context),
                                icon: const Icon(Icons.add_circle_outline, size: 18),
                                label: const Text('Fund'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.primaryDark
                                      : AppColors.primary,
                                  side: BorderSide(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.primaryDark
                                        : AppColors.primary,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showSendSheet(context),
                                icon: const Icon(Icons.send_outlined, size: 18),
                                label: const Text('Send'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.primaryDark
                                      : AppColors.primary,
                                  side: BorderSide(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.primaryDark
                                        : AppColors.primary,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _QuickActionChip(
                              icon: Icons.flag_outlined,
                              label: 'Goals',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
                            ),
                            _QuickActionChip(
                              icon: Icons.lock_outline,
                              label: 'Lock',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LockScreen(balance: _balance?.usdc ?? 0))),
                            ),
                            _QuickActionChip(
                              icon: Icons.people_outline,
                              label: 'Referrals',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralsScreen())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_goals.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Savings Goals', style: AppTheme.title(context: context, fontSize: 18)),
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
                                child: const Text('See all'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _goals.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, i) {
                                final g = _goals[i];
                                return _GoalCardMini(
                                  goal: g,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (_p2pTransfers.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent P2P',
                                style: AppTheme.header(context: context, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => const P2pHistoryScreen()),
                                ),
                                child: const Text('See all'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._p2pTransfers.take(5).map((t) => _P2pTransferRow(transfer: t)),
                          const SizedBox(height: 24),
                        ],
                      ],
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Transactions',
                              style: AppTheme.header(context: context, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            if (_transactions.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  'No transactions yet',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.body(fontSize: 14, color: const Color(0xFF9CA3AF)),
                                ),
                              )
                            else
                              ..._transactions.map((tx) => _TransactionRow(tx: tx)),
                          ],
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

class _BalanceCard extends StatelessWidget {
  final WalletBalance balance;

  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Balance',
            style: AppTheme.body(
              context: context,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${balance.usdc.toStringAsFixed(2)}',
            style: AppTheme.balance(
              context: context,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '≈ ₦${AppConstants.formatNgn((balance.usdc * AppConstants.ngnUsdRate).round())}',
            style: AppTheme.caption(
              context: context,
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlendEarningsCard extends StatelessWidget {
  final BlendEarningsResponse? earnings;
  final BlendApyResponse? apy;
  final double balance;
  final VoidCallback onRefresh;

  const _BlendEarningsCard({
    required this.earnings,
    required this.apy,
    required this.balance,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isEarning = (earnings?.supplied ?? 0) > 0;
    final apyStr = apy?.apy ?? '5.5';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceVariantDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: AppColors.success, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    isEarning ? 'Earning $apyStr% APY' : 'Blend Earnings',
                    style: AppTheme.body(context: context, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (isEarning)
                Text(
                  'On \$${(earnings?.supplied ?? 0).toStringAsFixed(2)} USDC',
                  style: AppTheme.caption(context: context, fontSize: 13),
                ),
            ],
          ),
          if (isEarning && (earnings?.earned ?? 0) > 0) ...[
            const SizedBox(height: 12),
            Text(
              "You've earned \$${(earnings?.earned ?? 0).toStringAsFixed(2)}",
              style: AppTheme.body(context: context, fontSize: 14, color: AppColors.success),
            ),
          ],
          if (!isEarning) ...[
            const SizedBox(height: 8),
            Text(
              'Earn 5-8% APY on your USDC',
              style: AppTheme.caption(context: context),
            ),
          ],
          const SizedBox(height: 12),
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

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _enable() async {
    final amt = double.tryParse(_amountController.text) ?? 0;
    if (amt <= 0 || amt > widget.balance) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().blendEnable(amt);
      widget.onSuccess();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disable() async {
    final supplied = widget.earnings?.supplied ?? 0;
    if (supplied <= 0) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().blendDisable(supplied);
      widget.onSuccess();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supplied = widget.earnings?.supplied ?? 0;
    final isEarning = supplied > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Blend Earnings', style: AppTheme.header(context: context, fontSize: 20)),
            Text('Earn ${widget.apy?.apy ?? '5.5'}% APY on USDC', style: AppTheme.caption(context: context)),
            const SizedBox(height: 24),
            if (isEarning) ...[
              Text('Supplied: \$${supplied.toStringAsFixed(2)}', style: AppTheme.body(context: context)),
              Text('Earned: \$${(widget.earnings?.earned ?? 0).toStringAsFixed(2)}', style: AppTheme.body(context: context)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _disable,
                child: _loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Withdraw All'),
              ),
            ] else ...[
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (USDC)',
                  hintText: 'Balance: \$${widget.balance.toStringAsFixed(2)}',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _enable,
                child: _loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Start Earning'),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(onPressed: widget.onClose, child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }
}

class _FundOptionsSheet extends StatelessWidget {
  final VoidCallback onClose;
  final String? stellarAddress;

  const _FundOptionsSheet({
    required this.onClose,
    this.stellarAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Fund your wallet',
              style: AppTheme.header(context: context, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how to add USDC to your balance',
              style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            _OptionTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'NGN Virtual Account',
              subtitle: 'Transfer Naira from any Nigerian bank',
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => _VirtualAccountBottomSheet(
                    onClose: () => Navigator.of(ctx).pop(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _OptionTile(
              icon: Icons.wallet_outlined,
              title: 'USDC Wallet',
              subtitle: 'Send USDC to your Stellar address',
              onTap: () {
                Navigator.of(context).pop();
                if (stellarAddress != null && stellarAddress!.isNotEmpty) {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) => _UsdcWalletSheet(
                      stellarAddress: stellarAddress!,
                      onClose: () => Navigator.of(ctx).pop(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Wallet address not available'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UsdcWalletSheet extends StatelessWidget {
  final String stellarAddress;
  final VoidCallback onClose;

  const _UsdcWalletSheet({
    required this.stellarAddress,
    required this.onClose,
  });

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Fund via USDC',
                  style: AppTheme.header(context: context, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send USDC from Binance, Lobstr, or any Stellar wallet to this address. Use the Stellar network.',
                  style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: QrImageView(
                      data: stellarAddress,
                      version: QrVersions.auto,
                      size: 160,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          stellarAddress,
                          style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copy(context, stellarAddress, 'Address'),
                        icon: const Icon(Icons.copy_outlined),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: const Color(0xFF059669)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select Stellar network when withdrawing. USDC will appear in your balance within minutes.',
                          style: AppTheme.body(fontSize: 13, color: const Color(0xFF059669)),
                        ),
                      ),
                    ],
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

class _SendOptionsSheet extends StatelessWidget {
  final double balance;
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  const _SendOptionsSheet({
    required this.balance,
    required this.onClose,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Send / Withdraw',
              style: AppTheme.header(context: context, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Balance: \$${balance.toStringAsFixed(2)} USDC',
              style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            _OptionTile(
              icon: Icons.person_outline,
              title: 'Send to Stakk User',
              subtitle: 'Instant USDC transfer to another user',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (ctx) => SendP2pScreen(
                      balance: balance,
                      onSuccess: onSuccess,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _OptionTile(
              icon: Icons.account_balance_outlined,
              title: 'NGN Bank Account',
              subtitle: 'Withdraw to any Nigerian bank',
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => _WithdrawToBankSheet(
                    balance: balance,
                    onClose: () => Navigator.of(ctx).pop(),
                    onSuccess: onSuccess,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _OptionTile(
              icon: Icons.wallet_outlined,
              title: 'USDC Wallet',
              subtitle: 'Send to another Stellar address',
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => _WithdrawToUsdcSheet(
                    balance: balance,
                    onClose: () => Navigator.of(ctx).pop(),
                    onSuccess: onSuccess,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: primary, size: 24),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.header(context: context, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.body(context: context, fontSize: 13),
                  ),
                ],
              ),
            ),
              Icon(Icons.chevron_right_rounded, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _WithdrawToBankSheet extends StatefulWidget {
  final double balance;
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  const _WithdrawToBankSheet({
    required this.balance,
    required this.onClose,
    required this.onSuccess,
  });

  @override
  State<_WithdrawToBankSheet> createState() => _WithdrawToBankSheetState();
}

class _WithdrawToBankSheetState extends State<_WithdrawToBankSheet> {
  List<Bank> _banks = [];
  Bank? _selectedBank;
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  bool _loading = false;
  bool _banksLoading = true;
  String? _error;
  late BankAccountValidationController _validationController;

  void _onAmountChanged() => setState(() {});

  void _onAccountOrBankChanged() {
    setState(() => _error = null);
    _validationController.scheduleValidation(
      _accountController.text.trim(),
      _selectedBank?.code ?? '',
    );
  }

  @override
  void initState() {
    super.initState();
    _loadBanks();
    _amountController.addListener(_onAmountChanged);
    _validationController = BankAccountValidationController(
      resolveAccount: (acc, code) async {
        if (!mounted) throw StateError('Widget disposed');
        return await context.read<AuthProvider>().resolveBankAccount(
          accountNumber: acc,
          bankCode: code,
        );
      },
    );
    _accountController.addListener(_onAccountOrBankChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _accountController.removeListener(_onAccountOrBankChanged);
    _validationController.dispose();
    _accountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double? get _ngnAmount => double.tryParse(_amountController.text.trim());
  double get _usdcEquivalent =>
      (_ngnAmount ?? 0) > 0 ? (_ngnAmount! / AppConstants.ngnUsdRate) : 0.0;

  Future<void> _loadBanks() async {
    setState(() => _banksLoading = true);
    try {
      final banks = await context.read<AuthProvider>().getBanks();
      if (mounted) {
        banks.sort((a, b) => a.name.compareTo(b.name));
        setState(() {
          _banks = banks;
          _banksLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.message == 'Session expired') {
          await context.read<AuthProvider>().handleSessionExpired(context);
        } else {
          setState(() {
            _banks = [];
            _banksLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _banks = [];
          _banksLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedBank == null) {
      setState(() => _error = 'Select a bank');
      return;
    }
    final account = _accountController.text.trim();
    if (account.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit account number');
      return;
    }
    final ngn = double.tryParse(_amountController.text.trim());
    if (ngn == null || ngn < 100) {
      setState(() => _error = 'Minimum 100 NGN');
      return;
    }
    final usdcNeeded = ngn / AppConstants.ngnUsdRate;
    if (usdcNeeded > widget.balance) {
      setState(() => _error = 'Insufficient balance');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().withdrawToBank(
        accountNumber: account,
        bankCode: _selectedBank!.code,
        amountNGN: ngn,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdrawal initiated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.message == 'Session expired') {
          await context.read<AuthProvider>().handleSessionExpired(context);
        } else {
          setState(() {
            _error = e.message;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Withdrawal failed';
          _loading = false;
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
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Withdraw to NGN Bank',
                  style: AppTheme.header(context: context, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Balance: \$${widget.balance.toStringAsFixed(2)} USDC',
                  style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                if (_banksLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _BankSelector(
                    banks: _banks,
                    selectedBank: _selectedBank,
                    onSelect: (b) {
                      setState(() => _selectedBank = b);
                      _onAccountOrBankChanged();
                    },
                  ),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: _validationController,
                    builder: (_, __) {
                      final state = _validationController.state;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _accountController,
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            enabled: !_loading,
                            decoration: InputDecoration(
                              labelText: 'Account Number',
                              border: const OutlineInputBorder(),
                              counterText: '',
                              suffixIcon: state.isValidating
                                  ? Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: const Color(0xFF4F46E5),
                                        ),
                                      ),
                                    )
                                  : state.isValid
                                      ? Icon(Icons.check_circle, color: const Color(0xFF059669))
                                      : null,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          if (state.isValid && state.accountName != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '✓ ${state.accountName}',
                              style: AppTheme.body(fontSize: 13, color: const Color(0xFF059669)),
                            ),
                          ],
                          if (state.status == BankAccountValidationStatus.error && state.errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              state.errorMessage!,
                              style: AppTheme.body(fontSize: 13, color: const Color(0xFFDC2626)),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (NGN)',
                      hintText: 'e.g. 50000',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_usdcEquivalent > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: const Color(0xFF4F46E5)),
                          const SizedBox(width: 8),
                          Text(
                            '≈ \$${_usdcEquivalent.toStringAsFixed(2)} USDC will be deducted',
                            style: AppTheme.body(context: context, fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF4F46E5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ListenableBuilder(
                    listenable: _validationController,
                    builder: (_, __) {
                      final canSubmit = _validationController.state.isValid &&
                          _ngnAmount != null &&
                          _ngnAmount! >= 100 &&
                          (_usdcEquivalent) <= widget.balance;
                      return SlideToAction(
                        label: 'Slide to withdraw',
                        onComplete: _submit,
                        disabled: !canSubmit,
                        isLoading: _loading,
                      );
                    },
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

class _BankSelector extends StatelessWidget {
  final List<Bank> banks;
  final Bank? selectedBank;
  final ValueChanged<Bank> onSelect;

  const _BankSelector({
    required this.banks,
    required this.selectedBank,
    required this.onSelect,
  });

  void _showBankPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _BankPickerSheet(
        banks: banks,
        selectedBank: selectedBank,
        onSelect: (b) {
          onSelect(b);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showBankPicker(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Bank',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          selectedBank?.name ?? 'Select bank',
          style: AppTheme.body(
            fontSize: 16,
            color: selectedBank != null ? null : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}

class _BankPickerSheet extends StatefulWidget {
  final List<Bank> banks;
  final Bank? selectedBank;
  final ValueChanged<Bank> onSelect;

  const _BankPickerSheet({
    required this.banks,
    required this.selectedBank,
    required this.onSelect,
  });

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Bank> get _filteredBanks {
    if (_query.isEmpty) return widget.banks;
    return widget.banks.where((b) => b.name.toLowerCase().contains(_query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search banks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              autofocus: true,
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _filteredBanks.length,
              itemBuilder: (_, i) {
                final bank = _filteredBanks[i];
                final isSelected = widget.selectedBank?.code == bank.code;
                return ListTile(
                  title: Text(bank.name),
                  trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF4F46E5)) : null,
                  onTap: () => widget.onSelect(bank),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawToUsdcSheet extends StatefulWidget {
  final double balance;
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  const _WithdrawToUsdcSheet({
    required this.balance,
    required this.onClose,
    required this.onSuccess,
  });

  @override
  State<_WithdrawToUsdcSheet> createState() => _WithdrawToUsdcSheetState();
}

class _WithdrawToUsdcSheetState extends State<_WithdrawToUsdcSheet> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  bool _loading = false;
  String? _error;

  void _onFieldChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onFieldChanged);
    _amountController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _addressController.removeListener(_onFieldChanged);
    _amountController.removeListener(_onFieldChanged);
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final addr = _addressController.text.trim();
    if (addr.length < 20 || !addr.startsWith('G')) {
      setState(() => _error = 'Enter a valid Stellar address');
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 0.01) {
      setState(() => _error = 'Minimum 0.01 USDC');
      return;
    }
    if (amount > widget.balance) {
      setState(() => _error = 'Insufficient balance');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().withdrawToUSDC(
        stellarAddress: addr,
        amountUSDC: amount,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('USDC sent successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.message == 'Session expired') {
          await context.read<AuthProvider>().handleSessionExpired(context);
        } else {
          setState(() {
            _error = e.message;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Withdrawal failed';
          _loading = false;
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
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Send to USDC Wallet',
                  style: AppTheme.header(context: context, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Balance: \$${widget.balance.toStringAsFixed(2)} USDC',
                  style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Stellar Address',
                    hintText: 'G...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (USDC)',
                    hintText: 'e.g. 10.50',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: AppTheme.body(fontSize: 14, color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 24),
                SlideToAction(
                  label: 'Slide to send',
                  onComplete: _submit,
                  disabled: _addressController.text.trim().length < 20 ||
                      !_addressController.text.trim().startsWith('G') ||
                      (double.tryParse(_amountController.text.trim()) ?? 0) < 0.01 ||
                      (double.tryParse(_amountController.text.trim()) ?? 0) > widget.balance,
                  isLoading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VirtualAccountBottomSheet extends StatefulWidget {
  final VoidCallback onClose;

  const _VirtualAccountBottomSheet({required this.onClose});

  @override
  State<_VirtualAccountBottomSheet> createState() =>
      _VirtualAccountBottomSheetState();
}

class _VirtualAccountBottomSheetState extends State<_VirtualAccountBottomSheet> {
  VirtualAccount? _account;
  bool _loading = true;
  String? _error;
  bool _needsBvn = false;
  final _bvnController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bvnController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _needsBvn = false;
    });
    try {
      final account = await context.read<AuthProvider>().getVirtualAccount();
      if (mounted) {
        setState(() {
          _account = account;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.message == 'Session expired') {
          await context.read<AuthProvider>().handleSessionExpired(context);
        } else {
          final needsBvn = e.message.toLowerCase().contains('bvn');
          setState(() {
            _error = needsBvn ? null : e.message;
            _needsBvn = needsBvn;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load virtual account';
          _loading = false;
        });
      }
    }
  }

  Future<void> _submitBvn() async {
    final bvn = _bvnController.text.trim().replaceAll(RegExp(r'\s'), '');
    if (bvn.length != 11 || !RegExp(r'^\d{11}$').hasMatch(bvn)) {
      setState(() => _error = 'Enter a valid 11-digit BVN');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await context.read<AuthProvider>().submitBvn(bvn);
      if (mounted) await _load();
    } on ApiException catch (e) {
      if (mounted) {
        if (e.message == 'Session expired') {
          await context.read<AuthProvider>().handleSessionExpired(context);
        } else {
          setState(() {
            _error = e.message;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save BVN';
          _loading = false;
        });
      }
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'NGN Virtual Account',
                  style: AppTheme.header(context: context, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Transfer Naira to this account. It will be converted to USDC.',
                  style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_needsBvn) ...[
                  Text(
                    'BVN is required to create your permanent deposit account. Your data is encrypted and secure.',
                    style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _bvnController,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'BVN (11 digits)',
                      hintText: '•••••••••••',
                      counterText: '',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitBvn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Submit BVN & Get Account'),
                    ),
                  ),
                ]
                else if (_error != null)
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
                            style: AppTheme.body(fontSize: 14, color: const Color(0xFFDC2626)),
                          ),
                        ),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (_account != null) ...[
                  _DetailRow(
                    label: 'Account Number',
                    value: _account!.accountNumber,
                    onCopy: () => _copy(_account!.accountNumber, 'Account number'),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Account Name',
                    value: _account!.accountName,
                    onCopy: () => _copy(_account!.accountName, 'Account name'),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Bank Name',
                    value: _account!.bankName,
                    onCopy: () => _copy(_account!.bankName, 'Bank name'),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: const Color(0xFF059669)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Use this account for bank transfers. Funds typically arrive within minutes.',
                            style: AppTheme.body(fontSize: 13, color: const Color(0xFF059669)),
                          ),
                        ),
                      ],
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.body(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.body(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4F46E5),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCardMini extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onTap;

  const _GoalCardMini({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceVariantDark : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(goal.name, style: AppTheme.body(context: context, fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                LinearProgressIndicator(value: goal.progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
                Text('\$${goal.currentAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}', style: AppTheme.caption(context: context, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: primary.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: primary),
              const SizedBox(width: 8),
              Text(label, style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.w500, color: primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _P2pTransferRow extends StatelessWidget {
  final P2pTransfer transfer;

  const _P2pTransferRow({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final isSent = transfer.direction == 'sent';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const P2pHistoryScreen()),
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              Icon(
                isSent ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
                color: isSent ? AppColors.error : AppColors.success,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isSent ? 'To ${transfer.otherDisplay}' : 'From ${transfer.otherDisplay}',
                  style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${isSent ? '-' : '+'}\$${transfer.amountUsdc.toStringAsFixed(2)}',
                style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.w600, color: isSent ? AppColors.error : AppColors.success),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction tx;

  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final amount = tx.displayAmount;
    final isPositive = amount >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tx.type ?? 'Transaction',
            style: AppTheme.body(fontSize: 14, color: const Color(0xFF374151)),
          ),
          Text(
            '${isPositive ? '+' : ''}${amount.toStringAsFixed(2)} USDC',
            style: AppTheme.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}
