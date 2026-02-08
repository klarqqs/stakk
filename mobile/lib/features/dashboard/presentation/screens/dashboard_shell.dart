import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/app_bottom_nav_bar.dart';
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: IndexedStack(
          index: _currentTab.index,
          children: _screens,
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentTab: _currentTab,
          onTabSelected: (tab) {
            _dismissKeyboard();
            setState(() => _currentTab = tab);
          },
        ),
      ),
    );
  }
}
