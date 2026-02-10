import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stakk_savings/core/components/error_dialog.dart';
import 'package:stakk_savings/core/components/buttons/primary_button.dart';
import 'package:stakk_savings/core/components/slide_to_action/slide_to_action.dart';
import 'package:stakk_savings/core/constants/app_constants.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/core/utils/bank_account_validation.dart';
import 'package:stakk_savings/core/utils/snackbar_utils.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/features/bills/domain/models/bill_models.dart';
import 'package:stakk_savings/features/bills/presentation/screens/bills_providers_screen.dart';
import 'package:stakk_savings/features/goals/presentation/screens/goals_screen.dart';
import 'package:stakk_savings/features/lock/presentation/screens/lock_screen.dart';
import 'package:stakk_savings/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:stakk_savings/features/referrals/presentation/screens/referrals_screen.dart';
import 'package:stakk_savings/features/loan/presentation/screens/loan_screen.dart';
import 'package:stakk_savings/features/wealth/presentation/screens/wealth_screen.dart';
import 'package:stakk_savings/features/trading/presentation/screens/trading_screen.dart';
import 'package:stakk_savings/features/home/presentation/widgets/home_skeleton_loader.dart';
import 'package:stakk_savings/features/send/presentation/screens/p2p_history_screen.dart';
import 'package:stakk_savings/features/send/presentation/screens/send_p2p_screen.dart';
import 'package:stakk_savings/providers/auth_provider.dart';
import 'package:stakk_savings/services/cache_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  bool _balanceVisible = true;
  bool _addressCopied = false;
  WalletBalance? _balance;
  List<Transaction> _transactions = [];
  List<P2pTransfer> _p2pTransfers = [];
  int _unreadNotifications = 0;
  BlendEarningsResponse? _blendEarnings;
  BlendApyResponse? _blendApy;
  final _cacheService = CacheService();
  static const _kBalanceVisible = 'balanceVisible';

  @override
  void initState() {
    super.initState();
    _loadBalanceVisible();
    _loadWithCache();
  }

  Future<void> _loadBalanceVisible() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(() => _balanceVisible = prefs.getBool(_kBalanceVisible) ?? true);
  }

  Future<void> _toggleBalanceVisible() async {
    final newVal = !_balanceVisible;
    setState(() => _balanceVisible = newVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBalanceVisible, newVal);
  }

  /// Load cached data first, then refresh in background
  Future<void> _loadWithCache() async {
    if (!mounted) return;

    // Try to load cached data first
    await _loadFromCache();

    // Then refresh from API in background
    _load();
  }

  /// Load data from cache if available
  Future<void> _loadFromCache() async {
    try {
      final cachedBalance = await _cacheService.getBalance();
      if (cachedBalance != null) {
        final balance = WalletBalance.fromJson({
          'database_balance': {'usdc': cachedBalance['usdc']},
          'stellar_address': cachedBalance['stellar_address'],
        });

        final cachedTransactions = await _cacheService.getTransactions();
        final transactions =
            cachedTransactions?.map((t) => Transaction.fromJson(t)).toList() ??
            [];

        final cachedP2p = await _cacheService.getP2pHistory();
        final p2pTransfers =
            cachedP2p?.map((p) => P2pTransfer.fromJson(p)).toList() ?? [];

        final cachedNotifications = await _cacheService.getNotifications();

        final cachedBlendEarnings = await _cacheService.getBlendEarnings();
        final blendEarnings = cachedBlendEarnings != null
            ? BlendEarningsResponse.fromJson(cachedBlendEarnings)
            : null;

        final cachedBlendApy = await _cacheService.getBlendApy();
        final blendApy = cachedBlendApy != null
            ? BlendApyResponse.fromJson(cachedBlendApy)
            : null;

        if (mounted) {
          setState(() {
            _balance = balance;
            _transactions = transactions;
            _p2pTransfers = p2pTransfers;
            _unreadNotifications = cachedNotifications ?? 0;
            _blendEarnings = blendEarnings;
            _blendApy = blendApy;
            _loading = false; // Show cached data immediately
          });
        }
      }
    } catch (e) {
      // Silently fail - cache is optional
      print('Failed to load from cache: $e');
    }
  }

  /// Load fresh data from API
  /// Only makes API calls if cache is expired or missing
  Future<void> _load({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Check cache validity - skip API calls if cache is fresh
    if (!forceRefresh) {
      final balanceCacheValid = await _cacheService.isValid('balance');
      final transactionsCacheValid = await _cacheService.isValid(
        'transactions',
      );
      final p2pCacheValid = await _cacheService.isValid('p2p_history');
      final notificationsCacheValid = await _cacheService.isValid(
        'notifications',
      );
      final blendEarningsCacheValid = await _cacheService.isValid(
        'blend_earnings',
      );
      final blendApyCacheValid = await _cacheService.isValid('blend_apy');
      final goalsCacheValid = await _cacheService.isValid('goals');

      // If all caches are valid, skip API calls entirely
      if (balanceCacheValid &&
          transactionsCacheValid &&
          p2pCacheValid &&
          notificationsCacheValid &&
          blendEarningsCacheValid &&
          blendApyCacheValid &&
          goalsCacheValid) {
        // All data is cached and fresh - no API calls needed
        return;
      }
    }

    // Only show loading spinner if we don't have cached data
    if (_balance == null) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final auth = context.read<AuthProvider>();

      // Space out requests slightly to avoid bursts
      final results = await Future.wait([
        Future.delayed(
          const Duration(milliseconds: 0),
          () => auth.getBalance(),
        ),
        Future.delayed(
          const Duration(milliseconds: 50),
          () => auth.getTransactions(),
        ),
        Future.delayed(
          const Duration(milliseconds: 100),
          () => auth.p2pGetHistory().catchError((_) => <P2pTransfer>[]),
        ),
        Future.delayed(
          const Duration(milliseconds: 150),
          () => auth.notificationsGetUnreadCount().catchError((_) => 0),
        ),
        Future.delayed(
          const Duration(milliseconds: 200),
          () => auth.getBlendEarnings().catchError(
            (_) => BlendEarningsResponse(
              supplied: 0,
              earned: 0,
              currentAPY: 5.5,
              totalValue: 0,
              isEarning: false,
            ),
          ),
        ),
        Future.delayed(
          const Duration(milliseconds: 250),
          () => auth.getBlendApy().catchError(
            (_) => BlendApyResponse(apy: '5.5', raw: 5.5),
          ),
        ),
        Future.delayed(
          const Duration(milliseconds: 300),
          () => auth.goalsGetAll().catchError((_) => <SavingsGoal>[]),
        ),
      ]);

      if (!mounted) return;

      final balance = results[0] as WalletBalance;
      final transactionsResponse = results[1] as TransactionsResponse;
      final p2pTransfers = results[2] as List<P2pTransfer>;
      final unreadNotifications = results[3] as int;
      final blendEarnings = results[4] as BlendEarningsResponse?;
      final blendApy = results[5] as BlendApyResponse?;
      final goals = results[6] as List<SavingsGoal>;

      // Cache the fresh data
      await _cacheData(
        balance: balance,
        transactions: transactionsResponse.transactions,
        p2pTransfers: p2pTransfers,
        unreadNotifications: unreadNotifications,
        blendEarnings: blendEarnings,
        blendApy: blendApy,
        goals: goals,
      );

      setState(() {
        _balance = balance;
        _transactions = transactionsResponse.transactions;
        _p2pTransfers = p2pTransfers;
        _unreadNotifications = unreadNotifications;
        _blendEarnings = blendEarnings;
        _blendApy = blendApy;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.message == 'Session expired') {
        await context.read<AuthProvider>().handleSessionExpired(context);
      } else if (e.message.toLowerCase().contains('too many requests')) {
        // Silently handle 429 errors - user already has cached data displayed
        // Don't show error dialog, just keep using cached data
        setState(() {
          _loading = false;
        });
        // Silently fail - cached data is already displayed
      } else {
        // Only show error dialog for non-429 errors if we don't have cached data
        if (_balance == null) {
          setState(() {
            _loading = false;
          });
          _showErrorDialog(context, e.message);
        } else {
          // We have cached data, silently fail and keep using it
          setState(() {
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      // Only show error if we don't have cached data
      if (_balance == null) {
        setState(() {
          _loading = false;
        });
        _showErrorDialog(context, 'Failed to load data');
      } else {
        // Silently fail - cached data is already displayed
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Cache data for future use
  Future<void> _cacheData({
    required WalletBalance balance,
    required List<Transaction> transactions,
    required List<P2pTransfer> p2pTransfers,
    required int unreadNotifications,
    BlendEarningsResponse? blendEarnings,
    BlendApyResponse? blendApy,
    required List<SavingsGoal> goals,
  }) async {
    try {
      await _cacheService.setBalance({
        'usdc': balance.usdc,
        'stellar_address': balance.stellarAddress,
      });

      await _cacheService.setTransactions(
        transactions
            .map(
              (t) => {
                'id': t.id,
                'type': t.type,
                'amount_naira': t.amountNaira,
                'amount_usdc': t.amountUsdc,
                'status': t.status,
                'created_at': t.createdAt,
              },
            )
            .toList(),
      );

      await _cacheService.setP2pHistory(
        p2pTransfers
            .map(
              (p) => {
                'id': p.id,
                'amount_usdc': p.amountUsdc,
                'fee_usdc': p.feeUsdc,
                'status': p.status,
                'note': p.note,
                'created_at': p.createdAt,
                'direction': p.direction,
                'other_user': {
                  'phone_number': p.otherPhone,
                  'email': p.otherEmail,
                },
              },
            )
            .toList(),
      );

      await _cacheService.setNotifications(unreadNotifications);

      if (blendEarnings != null) {
        await _cacheService.setBlendEarnings({
          'supplied': blendEarnings.supplied,
          'earned': blendEarnings.earned,
          'currentAPY': blendEarnings.currentAPY,
          'totalValue': blendEarnings.totalValue,
          'isEarning': blendEarnings.isEarning,
        });
      }

      if (blendApy != null) {
        await _cacheService.setBlendApy({
          'apy': blendApy.apy,
          'raw': blendApy.raw,
        });
      }

      await _cacheService.setGoals(
        goals
            .map(
              (g) => {
                'id': g.id,
                'name': g.name,
                'target_amount': g.targetAmount,
                'current_amount': g.currentAmount,
                'deadline': g.deadline,
                'status': g.status,
              },
            )
            .toList(),
      );
    } catch (e) {
      // Silently fail - caching is not critical
      print('Failed to cache data: $e');
    }
  }

  void _showFundSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (ctx) => _FundOptionsSheet(
        onClose: () => Navigator.of(ctx).pop(),
        stellarAddress: _balance?.stellarAddress,
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    ErrorDialog.show(context, message: message, onRetry: _load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: _GreetingHeader(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Badge(
                label: _unreadNotifications > 0
                    ? Text('$_unreadNotifications')
                    : null,
                child: const FaIcon(FontAwesomeIcons.bell, size: 22),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ).then((_) => _load()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          child: _loading
              ? const HomeSkeletonLoader()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_balance != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _BalanceCard(
                            balance: _balance!,
                            balanceVisible: _balanceVisible,
                            monthlyEarnings: _blendEarnings?.earned ?? 0,
                            onToggleVisibility: _toggleBalanceVisible,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _WalletAddressCard(
                            address: _balance!.stellarAddress ?? '',
                            copied: _addressCopied,
                            onCopy: () async {
                              final addr = _balance?.stellarAddress ?? '';
                              if (addr.isEmpty) return;
                              await Clipboard.setData(
                                ClipboardData(text: addr),
                              );
                              setState(() => _addressCopied = true);
                              if (mounted) {
                                TopSnackbar.show(
                                  context,
                                  message: 'Copied!',
                                  duration: const Duration(seconds: 1),
                                );
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (mounted)
                                    setState(() => _addressCopied = false);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(horizontal: 16),
                        //   child: _FundAndSendRow(
                        //     onFund: () => _showFundSheet(context),
                        //     onSend: () {
                        //       showModalBottomSheet<void>(
                        //         context: context,
                        //         isScrollControlled: true,
                        //         backgroundColor: Theme.of(
                        //           context,
                        //         ).scaffoldBackgroundColor,
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.vertical(
                        //             top: Radius.circular(AppRadius.xxl),
                        //           ),
                        //         ),
                        //         builder: (ctx) => _SendOptionsSheet(
                        //           balance: _balance!.usdc,
                        //           onClose: () => Navigator.pop(ctx),
                        //           onSuccess: _load,
                        //         ),
                        //       );
                        //     },
                        //   ),
                        // ),
                        // const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _SendOptionsGrid(
                            balance: _balance!.usdc,
                            onRefresh: _load,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _RecentTransactionsSection(
                            transactions: _transactions,
                            p2pTransfers: _p2pTransfers,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _ServicesGrid(
                            balance: _balance!.usdc,
                            onRefresh: _load,
                          ),
                        ),

                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _SavingsPromoCards(
                            balance: _balance!.usdc,
                            blendApy: _blendApy?.raw ?? 5.5,
                            onRefresh: _load,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Home screen premium palette (editorial, high-fashion)
class _HomePalette {
  _HomePalette._();
  static const Color balanceCardStart = Color(0xFF0D0D0F);
  static const Color balanceCardEnd = Color(0xFF1A1A2E);
  static const Color accentGold = Color(0xFFC9A962);
  static const Color accentGoldMuted = Color(0x66C9A962);
  static const Color cardSurfaceLight = Color(0xFFFAFAFA);
  static const Color cardSurfaceDark = Color(0xFF16181A);
  static const Color dividerLight = Color(0xFFF0F0F0);
  static const Color dividerDark = Color(0xFF2A2A2E);
}

class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = _displayName(user);
    final display = name.isNotEmpty ? name : 'there';
    return Text(
      'Hi, ${display.toUpperCase()}',
      style: AppTheme.header(
        context: context,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ).copyWith(letterSpacing: -0.3),
    );
  }
}

String _displayName(dynamic user) {
  if (user == null) return '';
  final first = user.firstName as String?;
  // final last = user.lastName as String?;
  if (first != null && first.isNotEmpty) {
    final parts = [first];
    // if (last != null && last.isNotEmpty) parts.add(last);
    return parts.join(' ');
  }
  final email = user.email as String?;
  final phone = user.phoneNumber as String;
  if (email != null && email.isNotEmpty && !email.startsWith('email:')) {
    return email.split('@').first;
  }
  if (phone.isNotEmpty && !phone.startsWith('email:')) {
    return phone;
  }
  return '';
}

class _BalanceCard extends StatelessWidget {
  final WalletBalance balance;
  final bool balanceVisible;
  final double monthlyEarnings;
  final VoidCallback onToggleVisibility;

  const _BalanceCard({
    required this.balance,
    required this.balanceVisible,
    required this.monthlyEarnings,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_HomePalette.balanceCardStart, _HomePalette.balanceCardEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Available Balance',
                          style: AppTheme.body(
                            context: context,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.65),
                          ).copyWith(letterSpacing: 0.5),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onToggleVisibility,
                          child: FaIcon(
                            balanceVisible
                                ? FontAwesomeIcons.eye
                                : FontAwesomeIcons.eyeSlash,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      balanceVisible
                          ? '\$${balance.usdc.toStringAsFixed(2)}'
                          : '\$ ••••••',
                      style: AppTheme.balance(
                        context: context,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ).copyWith(letterSpacing: -1),
                    ),
                    // const SizedBox(height: 6),
                    // Text(
                    //   balanceVisible
                    //       ? '≈ ₦${AppConstants.formatNgn((balance.usdc * AppConstants.ngnUsdRate).round())}'
                    //       : '≈ ₦ ••••••',
                    //   style: AppTheme.caption(
                    //     context: context,
                    //     fontSize: 16,
                    //     color: Colors.white.withValues(alpha: 0.8),
                    //   ),
                    // ),
                    if (monthlyEarnings > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        '+\$${monthlyEarnings.toStringAsFixed(2)} this month',
                        style: AppTheme.body(
                          context: context,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _HomePalette.accentGold,
                        ).copyWith(letterSpacing: 0.3),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FundAndSendRow extends StatelessWidget {
  final VoidCallback onFund;
  final VoidCallback onSend;

  const _FundAndSendRow({required this.onFund, required this.onSend});

  static const _radius = 24.0;
  static const _padding = EdgeInsets.symmetric(vertical: 16);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final surface = isDark
        ? _HomePalette.cardSurfaceDark
        : _HomePalette.cardSurfaceLight;

    final fillColor = primary;
    final onFill = Colors.white;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(_radius),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: isDark ? 0.35 : 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: onFund,
                borderRadius: BorderRadius.circular(_radius),
                splashColor: onFill.withValues(alpha: 0.25),
                highlightColor: onFill.withValues(alpha: 0.12),
                child: Padding(
                  padding: _padding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.plus, size: 18, color: onFill),
                      const SizedBox(width: 10),
                      Text(
                        'Fund',
                        style: AppTheme.body(
                          context: context,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ).copyWith(letterSpacing: 0.8, color: onFill),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(_radius),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: isDark ? 0.35 : 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: onSend,
                borderRadius: BorderRadius.circular(_radius),
                splashColor: onFill.withValues(alpha: 0.25),
                highlightColor: onFill.withValues(alpha: 0.12),
                child: Padding(
                  padding: _padding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.paperPlane, size: 18, color: onFill),
                      const SizedBox(width: 10),
                      Text(
                        'Send',
                        style: AppTheme.body(
                          context: context,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ).copyWith(letterSpacing: 0.8, color: onFill),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletAddressCard extends StatelessWidget {
  final String address;
  final bool copied;
  final VoidCallback onCopy;

  const _WalletAddressCard({
    required this.address,
    required this.copied,
    required this.onCopy,
  });

  String _formatAddress(String addr) {
    if (addr.isEmpty || addr.length < 8) return '';
    return '${addr.substring(0, 4)}...${addr.substring(addr.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? _HomePalette.cardSurfaceDark
        : _HomePalette.cardSurfaceLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Wallet Address',
                  style: AppTheme.caption(
                    context: context,
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatAddress(address),
                  style:
                      AppTheme.body(
                        context: context,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ).copyWith(
                        fontFamily: 'monospace',
                        fontFamilyFallback: const ['Menlo', 'monospace'],
                      ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: address.isNotEmpty ? onCopy : null,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      copied ? FontAwesomeIcons.check : FontAwesomeIcons.copy,
                      size: 16,
                      color: copied
                          ? AppColors.success
                          : (isDark
                                ? AppColors.primaryDark
                                : AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      copied ? 'Copied!' : 'Copy',
                      style: AppTheme.body(
                        context: context,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: copied
                            ? AppColors.success
                            : (isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SendOptionsGrid extends StatelessWidget {
  final double balance;
  final VoidCallback onRefresh;

  const _SendOptionsGrid({required this.balance, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.9,
      children: [
        _SendOptionTile(
          icon: FontAwesomeIcons.buildingColumns,
          line1: 'Send to',
          line2: 'NGN Bank',
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xxl),
                ),
              ),
              builder: (ctx) => _WithdrawToBankSheet(
                balance: balance,
                onClose: () => Navigator.pop(ctx),
                onSuccess: onRefresh,
              ),
            );
          },
        ),
        _SendOptionTile(
          icon: FontAwesomeIcons.user,
          line1: 'Send to',
          line2: 'Stakk User',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SendP2pScreen(balance: balance, onSuccess: onRefresh),
            ),
          ).then((_) => onRefresh()),
        ),
        _SendOptionTile(
          icon: FontAwesomeIcons.wallet,
          line1: 'Send to',
          line2: 'USDC Wallet',
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xxl),
                ),
              ),
              builder: (ctx) => _WithdrawToUsdcSheet(
                balance: balance,
                onClose: () => Navigator.pop(ctx),
                onSuccess: onRefresh,
              ),
            );
          },
        ),
        _SendOptionTile(
          icon: FontAwesomeIcons.piggyBank,
          line1: 'Send to',
          line2: 'Savings',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoalsScreen()),
          ).then((_) => onRefresh()),
        ),
      ],
    );
  }
}

class _SendOptionTile extends StatelessWidget {
  final IconData icon;
  final String line1;
  final String line2;
  final VoidCallback onTap;

  const _SendOptionTile({
    required this.icon,
    required this.line1,
    required this.line2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? _HomePalette.cardSurfaceDark
        : _HomePalette.cardSurfaceLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 22,
                color: isDark ? AppColors.primaryDark : AppColors.primary,
              ),
              const SizedBox(height: 6),
              Text(
                line1,
                style: AppTheme.caption(
                  context: context,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ).copyWith(letterSpacing: 0.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                line2,
                style: AppTheme.body(
                  context: context,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  final double balance;
  final VoidCallback onRefresh;

  const _ServicesGrid({required this.balance, required this.onRefresh});

  static const _airtimeCategory = BillCategoryModel(
    id: 0,
    code: 'AIRTIME',
    name: 'Airtime',
    description: 'Buy airtime',
  );
  static const _dataCategory = BillCategoryModel(
    id: 0,
    code: 'MOBILEDATA',
    name: 'Data',
    description: 'Buy data',
  );
  static const _utilityCategory = BillCategoryModel(
    id: 0,
    code: 'UTILITYBILLS',
    name: 'Utility',
    description: 'Utility bills',
  );
  static const _cableCategory = BillCategoryModel(
    id: 0,
    code: 'CABLEBILLS',
    name: 'Cable',
    description: 'Cable bill payment',
  );
  static const _internetCategory = BillCategoryModel(
    id: 0,
    code: 'INTSERVICE',
    name: 'Internet',
    description: 'Internet service',
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? _HomePalette.cardSurfaceDark
        : _HomePalette.cardSurfaceLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   'Services',
        //   style: AppTheme.title(
        //     context: context,
        //     fontSize: 18,
        //     fontWeight: FontWeight.w600,
        //   ),
        // ),
        // const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.2,
            children: [
              // Row 1 - Trading Services
              _ServiceTile(
                icon: FontAwesomeIcons.chartLine,
                label: 'Stocks',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TradingScreen()),
                ).then((_) => onRefresh()),
              ),
              _ServiceTile(
                icon: FontAwesomeIcons.bitcoin,
                label: 'Crypto',
                onTap: () {
                  // TODO: Navigate to crypto trading screen
                  TopSnackbar.show(context, message: 'Crypto trading coming soon!');
                },
              ),
              _ServiceTile(
                icon: FontAwesomeIcons.fire,
                label: 'Trending',
                onTap: () {
                  // TODO: Navigate to trending assets screen
                  TopSnackbar.show(context, message: 'Trending assets coming soon!');
                },
              ),
              _ServiceTile(
                icon: FontAwesomeIcons.globe,
                label: 'Forex',
                onTap: () {
                  // TODO: Navigate to forex trading screen
                  TopSnackbar.show(context, message: 'Forex trading coming soon!');
                },
              ),
              // Row 2 - Other Services
              _ServiceTile(
                icon: FontAwesomeIcons.gift,
                label: 'Refer & Earn',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReferralsScreen()),
                ).then((_) => onRefresh()),
              ),
              _ServiceTile(
                icon: FontAwesomeIcons.sackDollar,
                label: 'Loan',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoanScreen()),
                ).then((_) => onRefresh()),
              ),
              _ServiceTile(
                icon: FontAwesomeIcons.bullseye,
                label: 'Goals',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GoalsScreen()),
                ).then((_) => onRefresh()),
              ),
              _ServiceTile(
                icon: FontAwesomeIcons.mobileScreen,
                label: 'Airtime',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BillsProvidersScreen(
                      category: _airtimeCategory,
                      balance: balance,
                      onSuccess: onRefresh,
                    ),
                  ),
                ).then((_) => onRefresh()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.icon,
    required this.label,
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 22, color: primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTheme.body(
                  context: context,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  final List<Transaction> transactions;
  final List<P2pTransfer> p2pTransfers;

  const _RecentTransactionsSection({
    required this.transactions,
    required this.p2pTransfers,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final combined = <_RecentItem>[];
    for (final tx in transactions.take(5)) {
      combined.add(
        _RecentItem(
          type: tx.type ?? 'transaction',
          amount: (tx.amountUsdc ?? 0).toDouble(),
          subtitle: tx.createdAt ?? '',
          title: _txTitle(tx.type ?? ''),
        ),
      );
    }
    for (final t in p2pTransfers.take(5)) {
      final amt = t.amountUsdc;
      combined.add(
        _RecentItem(
          type: t.direction == 'sent' ? 'p2p_sent' : 'p2p_received',
          amount: t.direction == 'sent' ? -amt : amt,
          subtitle: t.createdAt,
          title: t.direction == 'sent'
              ? 'Sent to ${t.otherPhone ?? 'user'}'
              : 'Received from ${t.otherPhone ?? 'user'}',
        ),
      );
    }
    combined.sort((a, b) => (b.subtitle).compareTo(a.subtitle));
    final items = combined.take(3).toList();

    final cardSurface = isDark
        ? _HomePalette.cardSurfaceDark
        : _HomePalette.cardSurfaceLight;
    final dividerColor = isDark
        ? _HomePalette.dividerDark
        : _HomePalette.dividerLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No transactions yet',
                  style: AppTheme.body(
                    context: context,
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            )
          else
            ...items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return Column(
                children: [
                  _RecentTransactionRow(item: item),
                  if (i < items.length - 1)
                    Divider(height: 24, color: dividerColor),
                ],
              );
            }),
        ],
      ),
    );
  }

  String _txTitle(String type) {
    const map = {
      'deposit': 'Deposit',
      'withdrawal': 'Withdrawal',
      'p2p_sent': 'P2P Sent',
      'p2p_received': 'P2P Received',
      'bill_payment': 'Bill Payment',
      'lending_interest': 'Lending Interest',
      'referral_reward': 'Referral Reward',
      'borrow': 'Borrow',
      'repay': 'Repay',
    };
    return map[type] ?? type.replaceAll('_', ' ');
  }
}

class _RecentItem {
  final String type;
  final double amount;
  final String subtitle;
  final String title;
  _RecentItem({
    required this.type,
    required this.amount,
    required this.subtitle,
    required this.title,
  });
}

class _RecentTransactionRow extends StatelessWidget {
  final _RecentItem item;

  const _RecentTransactionRow({required this.item});

  String _icon(String type) {
    const map = {
      'deposit': '💵',
      'withdrawal': '🏦',
      'p2p_sent': '💸',
      'p2p_received': '💰',
      'bill_payment': '📱',
      'lending_interest': '📈',
      'referral_reward': '🎁',
      'borrow': '💳',
      'repay': '✅',
    };
    return map[type] ?? '📄';
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = item.amount > 0;
    return Row(
      children: [
        Text(_icon(item.type), style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: AppTheme.body(
                  context: context,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                item.subtitle,
                style: AppTheme.caption(context: context, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          '${item.amount >= 0 ? '+' : ''}\$${item.amount.toStringAsFixed(2)}',
          style: AppTheme.body(
            context: context,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isPositive ? AppColors.success : AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _SavingsPromoCards extends StatelessWidget {
  final double balance;
  final double blendApy;
  final VoidCallback onRefresh;

  const _SavingsPromoCards({
    required this.balance,
    required this.blendApy,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SavingsPromoCard(
            icon: '🔒',
            title: 'Lock Savings',
            apyLine: 'Up to',
            apyValue: '12.0% APY',
            buttonLabel: 'Lock Now →',
            gradient: const [Color(0xFF2D2420), Color(0xFF1A1814)],
            accent: _HomePalette.accentGold,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LockScreen(balance: balance)),
            ).then((_) => onRefresh()),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SavingsPromoCard(
            icon: '💎',
            title: 'Flexible Savings',
            apyLine: 'Earn',
            apyValue: '${blendApy.toStringAsFixed(2)}% APY',
            buttonLabel: 'Start Earning →',
            gradient: const [Color(0xFF0F1F14), Color(0xFF0A1510)],
            accent: const Color(0xFF4ADE80),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WealthScreen()),
            ).then((_) => onRefresh()),
          ),
        ),
      ],
    );
  }
}

class _SavingsPromoCard extends StatelessWidget {
  final String icon;
  final String title;
  final String apyLine;
  final String apyValue;
  final String buttonLabel;
  final List<Color> gradient;
  final Color accent;
  final VoidCallback onTap;

  const _SavingsPromoCard({
    required this.icon,
    required this.title,
    required this.apyLine,
    required this.apyValue,
    required this.buttonLabel,
    required this.gradient,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 10),
              Text(
                title,
                style: AppTheme.body(
                  context: context,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ).copyWith(letterSpacing: -0.1),
              ),
              const SizedBox(height: 6),
              Text(
                apyLine,
                style: AppTheme.body(
                  context: context,
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.6),
                ).copyWith(letterSpacing: 0.5),
              ),
              Text(
                apyValue,
                style: AppTheme.balance(
                  context: context,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ).copyWith(letterSpacing: -0.5),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  buttonLabel,
                  style: AppTheme.body(
                    context: context,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ).copyWith(letterSpacing: 0.2),
                ),
              ),
            ],
          ),
        ),
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (_error != null && mounted) {
      setState(() => _error = null);
    }
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;
  bool get _isAmountValid => _amount > 0 && _amount <= widget.balance;

  Future<void> _enable() async {
    if (!_isAmountValid) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().blendEnable(_amount);
      if (!mounted) return;
      _showSuccessSheet(
        'Deposited \$${_amount.toStringAsFixed(2)} USDC',
        'You\'re now earning ${widget.apy?.apy ?? '5.5'}% APY.',
      );
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
          _error = 'Failed to enable earning';
          _loading = false;
        });
      }
    }
  }

  Future<void> _disable() async {
    final supplied = widget.earnings?.supplied ?? 0;
    if (supplied <= 0) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().blendDisable(supplied);
      if (!mounted) return;
      _showSuccessSheet(
        'Withdrawn \$${supplied.toStringAsFixed(2)} USDC',
        'Funds have been returned to your wallet.',
      );
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
          _error = 'Failed to withdraw';
          _loading = false;
        });
      }
    }
  }

  void _showSuccessSheet(String title, String subtitle) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SuccessBottomSheet(
        title: title,
        subtitle: subtitle,
        onDone: () {
          Navigator.pop(ctx);
          widget.onSuccess();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supplied = widget.earnings?.supplied ?? 0;
    final isEarning = supplied > 0;

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
              'Blend Earnings',
              style: AppTheme.header(context: context, fontSize: 20),
            ),
            Text(
              'Earn ${widget.apy?.apy ?? '5.5'}% APY on USDC',
              style: AppTheme.caption(context: context),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available balance',
                    style: AppTheme.caption(context: context),
                  ),
                  Text(
                    '\$${widget.balance.toStringAsFixed(2)} USDC',
                    style: AppTheme.body(
                      context: context,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (isEarning) ...[
              Text(
                'Supplied: \$${supplied.toStringAsFixed(2)}',
                style: AppTheme.body(context: context),
              ),
              Text(
                'Earned: \$${(widget.earnings?.earned ?? 0).toStringAsFixed(2)}',
                style: AppTheme.body(context: context),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: AppTheme.body(fontSize: 14, color: AppColors.error),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Withdraw All',
                  onPressed: _loading ? null : _disable,
                  isLoading: _loading,
                ),
              ),
            ] else ...[
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (USDC)',
                  hintText: 'e.g. 100',
                  errorText: _error,
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              if (_amount > 0 && _amount > widget.balance)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Insufficient funds. Your balance is \$${widget.balance.toStringAsFixed(2)} USDC.',
                    style: AppTheme.body(fontSize: 14, color: AppColors.error),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Start Earning',
                  onPressed: (_loading || !_isAmountValid) ? null : _enable,
                  isLoading: _loading,
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: widget.onClose,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onDone;

  const _SuccessBottomSheet({
    required this.title,
    required this.subtitle,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDarkMuted : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark.withValues(alpha: 0.4)
              : AppColors.borderLight.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.circleCheck,
            color: AppColors.success,
            size: 52,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTheme.header(
              context: context,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTheme.caption(context: context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(label: 'Done', onPressed: onDone),
          ),
        ],
      ),
    );
  }
}

class _FundOptionsSheet extends StatelessWidget {
  final VoidCallback onClose;
  final String? stellarAddress;

  const _FundOptionsSheet({required this.onClose, this.stellarAddress});

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
              style: AppTheme.header(
                context: context,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how to add USDC to your balance',
              style: AppTheme.body(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            _OptionTile(
              icon: FontAwesomeIcons.buildingColumns,
              title: 'NGN Virtual Account',
              subtitle: 'Transfer Naira from any Nigerian bank',
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (ctx) => _VirtualAccountBottomSheet(
                    onClose: () => Navigator.of(ctx).pop(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _OptionTile(
              icon: FontAwesomeIcons.wallet,
              title: 'USDC Wallet',
              subtitle: 'Send USDC to your Stellar address',
              onTap: () {
                Navigator.of(context).pop();
                if (stellarAddress != null && stellarAddress!.isNotEmpty) {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (ctx) => _UsdcWalletSheet(
                      stellarAddress: stellarAddress!,
                      onClose: () => Navigator.of(ctx).pop(),
                    ),
                  );
                } else {
                  showTopSnackBar(context, 'Wallet address not available');
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

  const _UsdcWalletSheet({required this.stellarAddress, required this.onClose});

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    showTopSnackBar(
      context,
      '$label copied',
      duration: const Duration(seconds: 1),
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
                  style: AppTheme.header(
                    context: context,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send USDC from Binance, Lobstr, or any Stellar wallet to this address. Use the Stellar network.',
                  style: AppTheme.body(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                Builder(
                  builder: (context) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceVariantDarkMuted
                              : Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark.withValues(alpha: 0.3)
                                : AppColors.borderLight,
                          ),
                        ),
                        child: QrImageView(
                          data: stellarAddress,
                          version: QrVersions.auto,
                          size: 140,
                          backgroundColor: isDark
                              ? AppColors.surfaceVariantDarkMuted
                              : Colors.white,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _UsdcAddressRow(
                  address: stellarAddress,
                  onCopy: () => _copy(context, stellarAddress, 'Address'),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.circleInfo,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Select Stellar network when withdrawing. USDC will appear in your balance within minutes.',
                          style: AppTheme.body(
                            fontSize: 12,
                            color: AppColors.success,
                          ),
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

class _UsdcAddressRow extends StatelessWidget {
  final String address;
  final VoidCallback onCopy;

  const _UsdcAddressRow({required this.address, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final surface = isDark
        ? AppColors.surfaceVariantDarkMuted
        : AppColors.surfaceVariantLight;
    final borderColor = isDark
        ? AppColors.borderDark.withValues(alpha: 0.3)
        : AppColors.borderLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              address,
              style: AppTheme.body(
                context: context,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: FaIcon(FontAwesomeIcons.copy, size: 14, color: primary),
              ),
            ),
          ),
        ],
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
              style: AppTheme.header(
                context: context,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a way to send',
              style: AppTheme.body(
                context: context,
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            _OptionTile(
              icon: FontAwesomeIcons.user,
              title: 'Send to Stakk User',
              subtitle: 'Instant USDC transfer to another user',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (ctx) =>
                        SendP2pScreen(balance: balance, onSuccess: onSuccess),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _OptionTile(
              icon: FontAwesomeIcons.buildingColumns,
              title: 'Send to NGN Bank',
              subtitle: 'Withdraw to any Nigerian bank',
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
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
              icon: FontAwesomeIcons.wallet,
              title: 'Send to USDC Wallet',
              subtitle: 'Send to another Stellar address',
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
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
    final cardSurface = isDark
        ? AppColors.cardSurfaceDark
        : AppColors.cardSurfaceLight;
    final muted = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: FaIcon(icon, color: primary, size: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.header(
                        context: context,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ).copyWith(letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.body(context: context, fontSize: 13),
                    ),
                  ],
                ),
              ),
              FaIcon(FontAwesomeIcons.chevronRight, size: 12, color: muted),
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

  void _onAmountChanged() {
    // Only rebuild if needed - this is called on text field changes
    // The text field itself handles its own state
  }

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
        showTopSnackBar(context, 'Withdrawal initiated');
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Send to NGN Bank',
                  style: AppTheme.header(
                    context: context,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ).copyWith(letterSpacing: -0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose amount and account to send to your bank',
                  style: AppTheme.body(
                    context: context,
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
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
                                  ? FaIcon(
                                      FontAwesomeIcons.circleCheck,
                                      size: 22,
                                      color: AppColors.success,
                                    )
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
                              style: AppTheme.body(
                                fontSize: 13,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ],
                          if (state.status ==
                                  BankAccountValidationStatus.error &&
                              state.errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              state.errorMessage!,
                              style: AppTheme.body(
                                fontSize: 13,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                          FaIcon(
                            FontAwesomeIcons.circleInfo,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '≈ \$${_usdcEquivalent.toStringAsFixed(2)} USDC will be deducted',
                            style: AppTheme.body(
                              context: context,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: AppTheme.body(
                        fontSize: 14,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ListenableBuilder(
                    listenable: _validationController,
                    builder: (_, __) {
                      final canSubmit =
                          _validationController.state.isValid &&
                          _ngnAmount != null &&
                          _ngnAmount! >= 100 &&
                          (_usdcEquivalent) <= widget.balance;
                      return SlideToAction(
                        label: 'Withdraw',
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          suffixIcon: FaIcon(FontAwesomeIcons.chevronDown, size: 20),
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
    _searchController.addListener(
      () =>
          setState(() => _query = _searchController.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Bank> get _filteredBanks {
    if (_query.isEmpty) return widget.banks;
    return widget.banks
        .where((b) => b.name.toLowerCase().contains(_query))
        .toList();
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
                prefixIcon: const FaIcon(
                  FontAwesomeIcons.magnifyingGlass,
                  size: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                  trailing: isSelected
                      ? FaIcon(
                          FontAwesomeIcons.check,
                          size: 20,
                          color: AppColors.primary,
                        )
                      : null,
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
        showTopSnackBar(context, 'USDC sent successfully');
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
                  style: AppTheme.header(
                    context: context,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter recipient address and amount to send',
                  style: AppTheme.body(
                    context: context,
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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
                  label: 'Send',
                  onComplete: _submit,
                  disabled:
                      _addressController.text.trim().length < 20 ||
                      !_addressController.text.trim().startsWith('G') ||
                      (double.tryParse(_amountController.text.trim()) ?? 0) <
                          0.01 ||
                      (double.tryParse(_amountController.text.trim()) ?? 0) >
                          widget.balance,
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

class _VirtualAccountBottomSheetState
    extends State<_VirtualAccountBottomSheet> {
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
    showTopSnackBar(
      context,
      '$label copied',
      duration: const Duration(seconds: 1),
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
                  style: AppTheme.header(
                    context: context,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Transfer Naira to this account. It will be converted to USDC.',
                  style: AppTheme.body(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
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
                    style: AppTheme.body(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _bvnController,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                      style: AppTheme.body(
                        fontSize: 14,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Submit BVN & Get Account',
                      onPressed: _submitBvn,
                    ),
                  ),
                ] else if (_error != null)
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
                            style: AppTheme.body(
                              fontSize: 14,
                              color: const Color(0xFFDC2626),
                            ),
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
                    onCopy: () =>
                        _copy(_account!.accountNumber, 'Account number'),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Account Name',
                    value: _account!.accountName,
                    onCopy: () => _copy(_account!.accountName, 'Account name'),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Bank Name',
                    value: _account!.bankName,
                    onCopy: () => _copy(_account!.bankName, 'Bank name'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.circleInfo,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Use this account for bank transfers. Funds typically arrive within minutes.',
                            style: AppTheme.body(
                              fontSize: 12,
                              color: AppColors.success,
                            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final surface = isDark
        ? AppColors.surfaceVariantDarkMuted
        : AppColors.surfaceVariantLight;
    final borderColor = isDark
        ? AppColors.borderDark.withValues(alpha: 0.3)
        : AppColors.borderLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTheme.body(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.body(
                    context: context,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: FaIcon(FontAwesomeIcons.copy, size: 14, color: primary),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 24,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal.name,
                        style: AppTheme.body(
                          context: context,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 4,
                    backgroundColor: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceVariantLight,
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),
                Text(
                  '\$${goal.currentAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}',
                  style: AppTheme.caption(context: context, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final primaryGradientEnd = isDark
        ? AppColors.primaryDark
        : AppColors.primaryGradientEnd;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withValues(alpha: 0.1),
                primaryGradientEnd.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: FaIcon(icon, size: 16, color: primary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTheme.body(
                  context: context,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
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
              FaIcon(
                isSent ? FontAwesomeIcons.arrowUp : FontAwesomeIcons.arrowDown,
                size: 18,
                color: isSent ? AppColors.error : AppColors.success,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isSent
                      ? 'To ${transfer.otherDisplay}'
                      : 'From ${transfer.otherDisplay}',
                  style: AppTheme.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${isSent ? '-' : '+'}\$${transfer.amountUsdc.toStringAsFixed(2)}',
                style: AppTheme.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSent ? AppColors.error : AppColors.success,
                ),
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
              color: isPositive
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}
