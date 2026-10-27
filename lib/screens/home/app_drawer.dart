import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../budget/budget_screen.dart';
import '../calendar/calendar_tab.dart';
import '../category/category_manage_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/transactions_screen.dart';

/// Single left-side navigation. Related management features live inside
/// Settings instead of appearing as repeated top-level destinations.
class AppDrawer extends StatelessWidget {
  AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: ListView(padding: EdgeInsets.zero, children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 26, horizontal: 18),
            color: AppColors.accent,
            child: Column(children: [
              CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Padding(padding: EdgeInsets.all(4), child: AppLogo(size: 46))),
              SizedBox(height: 10),
              Text('Student Expense Manager', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ]),
          ),
          SizedBox(height: 8),
          _tile(context, Icons.dashboard_outlined, 'Dashboard', () => Navigator.pop(context)),
          _tile(context, Icons.swap_vert_circle_outlined, 'Transactions', () => _open(context, TransactionsScreen())),
          _tile(context, Icons.calendar_month_outlined, 'Calendar', () => _open(context, CalendarTabPage())),
          _tile(context, Icons.account_balance_wallet_outlined, 'Budget', () => _open(context, BudgetScreen())),
          _tile(context, Icons.assessment_outlined, 'Reports', () => _open(context, ReportsScreen())),
          Divider(),
          ListTile(
            leading: Icon(app.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode, color: AppColors.accent),
            title: Text('Dark mode'),
            trailing: Switch(value: app.themeMode == ThemeMode.dark, onChanged: (_) => app.toggleTheme()),
          ),
          _tile(context, Icons.settings_outlined, 'Settings', () => _open(context, SettingsScreen())),
          _tile(context, Icons.category_outlined, 'Categories', () => _open(context, CategoryManageScreen())),
          Divider(),
          ListTile(leading: Icon(Icons.logout, color: AppColors.expense), title: Text('Log out'), onTap: () { app.logout(); Navigator.pop(context); }),
        ]),
      ),
    );
  }

  void _open(BuildContext context, Widget page) { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => page)); }
  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap) => ListTile(leading: Icon(icon, color: AppColors.accent, size: 21), title: Text(label), onTap: onTap);
}

/// Small wrapper so the Calendar tab can be opened from the drawer without
/// exposing the parent tab controller.
class CalendarTabPage extends StatelessWidget {
  CalendarTabPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Calendar')), body: CalendarTab());
}
