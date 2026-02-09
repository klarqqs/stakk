import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/app_bottom_nav_bar.dart';
import 'package:stakk_savings/core/components/connectivity_banner.dart';
import 'package:stakk_savings/widgets/force_update_dialog.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/services/app_version_service.dart';
import 'package:stakk_savings/features/home/presentation/screens/home_screen.dart';
import 'package:stakk_savings/features/bills/presentation/screens/bills_screen.dart';
import 'package:stakk_savings/features/send/presentation/screens/send_screen.dart';
import 'package:stakk_savings/features/save/presentation/screens/save_screen.dart';
import 'package:stakk_savings/features/more/presentation/screens/more_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  AppTab _currentTab = AppTab.home;

  final _screens = const [
    HomeScreen(),
    BillsScreen(),
    SendScreen(),
    SaveScreen(),
    MoreScreen(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.gradientStartDark,
                    AppColors.gradientEndDark,
                    AppColors.gradientStartDark,
                  ]
                : [
                    AppColors.gradientStartLight,
                    AppColors.gradientEndLight,
                    AppColors.backgroundLight,
                  ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: ConnectivityBanner(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: IndexedStack(
                key: ValueKey<int>(_currentTab.index),
                index: _currentTab.index,
                children: _screens,
              ),
            ),
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentTab: _currentTab,
            onTabSelected: (tab) {
              _dismissKeyboard();
              setState(() => _currentTab = tab);
            },
          ),
        ),
      ),
    );
  }
}
