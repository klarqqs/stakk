import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/app_bottom_nav_bar.dart';
import 'package:stakk_savings/core/components/connectivity_banner.dart';
import 'package:stakk_savings/widgets/force_update_dialog.dart';
import 'package:stakk_savings/services/app_version_service.dart';
import 'package:stakk_savings/features/wallet/presentation/screens/usdc_wallet_screen.dart';
import 'package:stakk_savings/features/trading/presentation/screens/trading_screen.dart';
import 'package:stakk_savings/features/wealth/presentation/screens/wealth_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  AppTab _currentTab = AppTab.wallet;

  final _screens = const [
    UsdcWalletScreen(), // USDC Wallet tab
    TradingScreen(),    // Swap tab (stocks & crypto)
    WealthScreen(),     // Earn tab (Blend)
  ];

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void initState() {
    super.initState();
    // Check for force update after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForForceUpdate();
    });
  }

  Future<void> _checkForForceUpdate() async {
    await AppVersionService().checkForUpdates();
    if (mounted && AppVersionService().requiresForceUpdate) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ForceUpdateDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            ConnectivityBanner(
              child: IndexedStack(
                index: _currentTab.index,
                children: _screens,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomNavBar(
                currentTab: _currentTab,
                onTabSelected: (tab) {
                  _dismissKeyboard();
                  setState(() => _currentTab = tab);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
