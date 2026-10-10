import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../nav.dart';
import 'dashboard_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'suppliers_screen.dart';
import 'transactions_screen.dart';

/// الإطار الرئيسي: تنقل سفلي سريع + زر إضافة عائم متاح من أي تبويب.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final Set<int> _visited = {0};

  static const _tabs = <Widget>[
    DashboardScreen(),
    SuppliersScreen(),
    TransactionsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < _tabs.length; i++) _visited.contains(i) ? _tabs[i] : const SizedBox.shrink(),
        ],
      ),
      floatingActionButton: _index <= 2
          ? FloatingActionButton.extended(
              onPressed: () => showQuickAddSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة'),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: pal.border))),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() {
            _index = i;
            _visited.add(i);
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: kOrange),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded, color: kOrange),
              label: 'الموردون',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: kOrange),
              label: 'الحركات',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: kOrange),
              label: 'التقارير',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded, color: kOrange),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}
