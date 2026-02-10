import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:stakk_savings/core/components/error_dialog.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/core/utils/snackbar_utils.dart';
import 'package:stakk_savings/providers/auth_provider.dart';
import 'package:stakk_savings/api/api_client.dart';
import 'package:stakk_savings/features/trading/presentation/screens/trading_screen.dart';
import 'package:stakk_savings/features/wealth/presentation/screens/wealth_screen.dart';
import 'package:stakk_savings/features/wallet/presentation/screens/deposit_screen.dart';
import 'package:stakk_savings/features/wallet/presentation/screens/transfer_screen.dart';
import 'package:stakk_savings/features/wallet/presentation/screens/withdraw_screen.dart';

enum WalletTab { wallet, swap, earn }

// TON Wallet Color Palette (2026 Modern)
class WalletColors {
  static const Color background = Color(0xFF000000); // Pure black
  static const Color cardBackground = Color(0xFF1C1C1E); // Dark gray
  static const Color primary = Color(0xFF00D9C5); // Teal/Cyan accent
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color success = Color(0xFF34C759);
}

class UsdcWalletScreen extends StatefulWidget {
  const UsdcWalletScreen({super.key});

  @override
  State<UsdcWalletScreen> createState() => _UsdcWalletScreenState();
}

class _UsdcWalletScreenState extends State<UsdcWalletScreen> {
  WalletTab _currentTab = WalletTab.wallet;
  String _timeframe = 'All Time';
  bool _balanceVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WalletColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: WalletColors.cardBackground,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF2C2C2E),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TabButton(
                    label: 'USDC Wallet',
                    icon: FontAwesomeIcons.wallet,
                    isActive: _currentTab == WalletTab.wallet,
                    onTap: () => setState(() => _currentTab = WalletTab.wallet),
                  ),
                  _TabButton(
                    label: 'Swap',
                    icon: FontAwesomeIcons.arrowRightArrowLeft,
                    isActive: _currentTab == WalletTab.swap,
                    onTap: () => setState(() => _currentTab = WalletTab.swap),
                  ),
                  _TabButton(
                    label: 'Earn',
                    icon: FontAwesomeIcons.percent,
                    isActive: _currentTab == WalletTab.earn,
                    onTap: () => setState(() => _currentTab = WalletTab.earn),
                  ),
                ],
              ),
            ),

            // Tab Content - Instant transitions (no animations)
            Expanded(
              child: IndexedStack(
                index: _currentTab.index,
                children: [
                  _WalletTabContent(
                    timeframe: _timeframe,
                    onTimeframeTap: () {
                      setState(() {
                        _timeframe = _timeframe == 'All Time' ? '24h' : 'All Time';
                      });
                    },
                    balanceVisible: _balanceVisible,
                    onToggleVisibility: () {
                      setState(() => _balanceVisible = !_balanceVisible);
                    },
                  ),
                  const TradingScreen(),
                  const WealthScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                icon,
                size: 22,
                color: isActive ? WalletColors.primary : WalletColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? WalletColors.primary : WalletColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletTabContent extends StatefulWidget {
  final String timeframe;
  final VoidCallback onTimeframeTap;
  final bool balanceVisible;
  final VoidCallback onToggleVisibility;

  const _WalletTabContent({
    required this.timeframe,
    required this.onTimeframeTap,
    required this.balanceVisible,
    required this.onToggleVisibility,
  });

  @override
  State<_WalletTabContent> createState() => _WalletTabContentState();
}

class _WalletTabContentState extends State<_WalletTabContent> {
  WalletBalance? _balance;
  BlendEarningsResponse? _earnings;
  String? _stellarAddress;
  bool _loading = true;
  Timer? _carouselTimer;
  final PageController _carouselController = PageController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _startCarousel();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_carouselController.hasClients) {
        final currentPage = _carouselController.page?.round() ?? 0;
        final nextPage = (currentPage + 1) % 3;
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final auth = context.read<AuthProvider>();
      final results = await Future.wait([
        auth.getBalance(),
        auth.getBlendEarnings().catchError(
          (_) => BlendEarningsResponse(
            supplied: 0,
            earned: 0,
            currentAPY: 5.5,
            totalValue: 0,
            isEarning: false,
          ),
        ),
      ]);

      if (mounted) {
        setState(() {
          _balance = results[0] as WalletBalance;
          _earnings = results[1] as BlendEarningsResponse;
          _stellarAddress = _balance?.stellarAddress;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ErrorDialog.show(context, message: 'Failed to load wallet data');
      }
    }
  }

  double get _totalEarned {
    if (_earnings == null) return 0;
    return _earnings!.earned;
  }

  double get _earnedPercent {
    if (_balance == null || _balance!.usdc == 0) return 0;
    return (_totalEarned / _balance!.usdc) * 100;
  }

  String _formatAddress(String? address) {
    if (address == null || address.isEmpty) return '';
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}....${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: WalletColors.primary,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: WalletColors.primary,
      backgroundColor: WalletColors.cardBackground,
      child: CustomScrollView(
        slivers: [
          // Section 1: Balance Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _BalanceCard(
                address: _formatAddress(_stellarAddress),
                balance: _balance?.usdc ?? 0,
                earned: _totalEarned,
                earnedPercent: _earnedPercent,
                timeframe: widget.timeframe,
                onTimeframeTap: widget.onTimeframeTap,
                balanceVisible: widget.balanceVisible,
                onToggleVisibility: widget.onToggleVisibility,
                onCopyAddress: () {
                  if (_stellarAddress != null) {
                    Clipboard.setData(ClipboardData(text: _stellarAddress!));
                    HapticFeedback.lightImpact();
                    showTopSnackBar(context, 'Address copied!');
                  }
                },
              ),
            ),
          ),

          // Section 2: Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: FontAwesomeIcons.arrowRight,
                      label: 'Transfer',
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const TransferScreen(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: FontAwesomeIcons.arrowDown,
                      label: 'Deposit',
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const DepositScreen(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: FontAwesomeIcons.arrowUp,
                      label: 'Withdraw',
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const WithdrawScreen(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Section 3: Finish Setup Card
          if ((_balance?.usdc ?? 0) == 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _FinishSetupCard(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const DepositScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                ),
              ),
            ),

          // Section 4: Promotional Carousel
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: _PromotionalCarousel(controller: _carouselController),
            ),
          ),

          // Section 5: Tokens List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tokens',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: WalletColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TokenItem(
                    icon: FontAwesomeIcons.dollarSign,
                    iconColor: WalletColors.primary,
                    name: 'USDC',
                    amount: '${(_balance?.usdc ?? 0).toStringAsFixed(2)} USDC',
                    value: '\$${(_balance?.usdc ?? 0).toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  _TokenItem(
                    icon: FontAwesomeIcons.bitcoin,
                    iconColor: Colors.orange,
                    name: 'Bitcoin',
                    amount: '0 cbBTC',
                    value: '\$0.00',
                  ),
                  const SizedBox(height: 12),
                  _TokenItem(
                    icon: FontAwesomeIcons.ethereum,
                    iconColor: Colors.blue,
                    name: 'Ethereum',
                    amount: '0 wETH',
                    value: '\$0.00',
                  ),
                  const SizedBox(height: 12),
                  _TokenItem(
                    icon: FontAwesomeIcons.coins,
                    iconColor: Colors.amber,
                    name: 'Gold',
                    amount: '0 XAUt0',
                    value: '\$0.00',
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Section 6: Earning Assets Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _EarningAssetsCard(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Navigate to Earn tab or Blend screen
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Section 7: Activity
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: WalletColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ActivityItem(
                    icon: 'K',
                    title: 'You created USDC Wallet',
                    timestamp: 'Dec 11, 2025 at 12:43 PM',
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String address;
  final double balance;
  final double earned;
  final double earnedPercent;
  final String timeframe;
  final VoidCallback onTimeframeTap;
  final bool balanceVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onCopyAddress;

  const _BalanceCard({
    required this.address,
    required this.balance,
    required this.earned,
    required this.earnedPercent,
    required this.timeframe,
    required this.onTimeframeTap,
    required this.balanceVisible,
    required this.onToggleVisibility,
    required this.onCopyAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WalletColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Wallet Address
          if (address.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: WalletColors.textPrimary,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onCopyAddress,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: FaIcon(
                      FontAwesomeIcons.copy,
                      size: 14,
                      color: WalletColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          if (address.isNotEmpty) const SizedBox(height: 24),

          // Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                balanceVisible
                    ? '\$${balance.toStringAsFixed(2)}'
                    : '\$ ••••••',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: WalletColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onToggleVisibility,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: FaIcon(
                    balanceVisible
                        ? FontAwesomeIcons.eye
                        : FontAwesomeIcons.eyeSlash,
                    size: 18,
                    color: WalletColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Profit Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.arrowTrendUp,
                size: 16,
                color: WalletColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                balanceVisible
                    ? '${earnedPercent >= 0 ? '+' : ''}${earnedPercent.toStringAsFixed(2)}%'
                    : '•••%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: WalletColors.success,
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onTimeframeTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeframe,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: WalletColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const FaIcon(
                        FontAwesomeIcons.chevronDown,
                        size: 12,
                        color: WalletColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: WalletColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2C2C2E),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: WalletColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  color: WalletColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: WalletColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishSetupCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FinishSetupCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: WalletColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: WalletColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: WalletColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.dollarSign,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get your first USDC',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: WalletColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Deposit USDC to start earning',
                    style: TextStyle(
                      fontSize: 12,
                      color: WalletColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 16,
              color: WalletColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionalCarousel extends StatefulWidget {
  final PageController controller;

  const _PromotionalCarousel({required this.controller});

  @override
  State<_PromotionalCarousel> createState() => _PromotionalCarouselState();
}

class _PromotionalCarouselState extends State<_PromotionalCarousel> {
  int _currentPage = 0;

  final List<Map<String, dynamic>> _ads = [
    {
      'icon': FontAwesomeIcons.briefcase,
      'title': 'Trade US Stocks and ETFs',
      'subtitle': 'without network fees',
      'cta': 'Try now',
      'color': WalletColors.primary,
    },
    {
      'icon': FontAwesomeIcons.percent,
      'title': 'Earn Flexible',
      'subtitle': 'Flexible interest rates',
      'cta': 'Learn more',
      'color': WalletColors.success,
    },
    {
      'icon': FontAwesomeIcons.chartLine,
      'title': 'Earn Fixed',
      'subtitle': 'Lock funds, guaranteed APY',
      'cta': 'Start earning',
      'color': Colors.blue,
    },
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (widget.controller.page != null) {
        setState(() {
          _currentPage = widget.controller.page!.round();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: widget.controller,
            itemCount: _ads.length,
            itemBuilder: (context, index) {
              final ad = _ads[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _AdCard(
                  icon: ad['icon'] as IconData,
                  title: ad['title'] as String,
                  subtitle: ad['subtitle'] as String,
                  cta: ad['cta'] as String,
                  color: ad['color'] as Color,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _ads.length,
            (index) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? WalletColors.primary
                    : WalletColors.textSecondary.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String cta;
  final Color color;

  const _AdCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(
                icon,
                color: color,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: WalletColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: WalletColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cta,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String amount;
  final String value;

  const _TokenItem({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.amount,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WalletColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2C2C2E),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: WalletColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 12,
                    color: WalletColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: WalletColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningAssetsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EarningAssetsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: WalletColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2C2C2E),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: WalletColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.percent,
                  color: WalletColors.success,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earning Assets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: WalletColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Get rewards for holding crypto',
                    style: TextStyle(
                      fontSize: 12,
                      color: WalletColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 16,
              color: WalletColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String icon;
  final String title;
  final String timestamp;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WalletColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2C2C2E),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: WalletColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: WalletColors.success,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: WalletColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: const TextStyle(
                    fontSize: 12,
                    color: WalletColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
