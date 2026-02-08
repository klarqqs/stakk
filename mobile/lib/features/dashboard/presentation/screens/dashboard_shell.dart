import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/app_bottom_nav_bar.dart';
import 'package:stakk_savings/features/home/presentation/screens/home_screen.dart';
import 'package:stakk_savings/features/bills/presentation/screens/bills_categories_screen.dart';
import 'package:stakk_savings/features/invest/presentation/screens/invest_screen.dart';
import 'package:stakk_savings/features/card/presentation/screens/card_screen.dart';
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
    BillsCategoriesScreen(),
    InvestScreen(),
    CardScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab.index,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: _currentTab,
        onTabSelected: (tab) => setState(() => _currentTab = tab),
      ),
    );
  }
}
