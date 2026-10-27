import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../settings/settings_screen.dart';
import '../settings/backup_restore_screen.dart';
import '../settings/help_screen.dart';
import '../transactions/deleted_transactions_screen.dart';

/// Right drawer replicating the "Show On Home Screen" toggle list plus
/// Settings / Backup and Restore / Remove Ads / Deleted Transactions /
/// Help / Rate Us / Share App.
class DisplaySettingsDrawer extends StatelessWidget {
  DisplaySettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 24),
              color: AppColors.accent,
              child: Column(
                children: [
                  Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 30),
                  SizedBox(height: 6),
                  Text('Income Expense',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('Show On Home Screen',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            _toggle(context, Icons.list, 'Recent Transactions',
                app.showRecentTransactions, (v) {
              app.showRecentTransactions = v;
              app.saveHomeWidgetPrefs();
              app.notifyListeners();
            }),
            _toggle(context, Icons.account_balance_wallet, 'Payment Method',
                app.showPaymentMethod, (v) {
              app.showPaymentMethod = v;
              app.saveHomeWidgetPrefs();
              app.notifyListeners();
            }),
            _toggle(context, Icons.pie_chart, 'Category Chart',
                app.showCategoryChart, (v) {
              app.showCategoryChart = v;
              app.saveHomeWidgetPrefs();
              app.notifyListeners();
            }),
            _toggle(context, Icons.money_off, 'Budget', app.showBudget, (v) {
              app.showBudget = v;
              app.saveHomeWidgetPrefs();
              app.notifyListeners();
            }),
            _toggle(context, Icons.trending_up, 'Trend', app.showTrend, (v) {
              app.showTrend = v;
              app.saveHomeWidgetPrefs();
              app.notifyListeners();
            }),
            Divider(color: AppColors.border),
            _tile(context, Icons.settings, 'Settings', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SettingsScreen()));
            }),
            _tile(context, Icons.cloud_upload, 'Backup and Restore', () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BackupRestoreScreen()));
            }),
            _tile(context, Icons.ondemand_video, 'Remove Ads', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ads removed (demo)')));
            }),
            _tile(context, Icons.delete_outline, 'Deleted Transactions', () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DeletedTransactionsScreen()));
            }),
            _tile(context, Icons.help_outline, 'Help', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => HelpScreen()));
            }),
            _tile(context, Icons.star_border, 'Rate Us', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Thanks for the love!')));
            }),
            _tile(context, Icons.share, 'Share App', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share sheet (demo)')));
            }),
          ],
        ),
      ),
    );
  }

  Widget _toggle(BuildContext context, IconData icon, String label, bool value,
      ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent, size: 20),
      title: Text(label,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      trailing: Checkbox(
        value: value,
        activeColor: AppColors.accent,
        onChanged: (v) => onChanged(v ?? false),
      ),
    );
  }

  Widget _tile(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent, size: 20),
      title: Text(label,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      onTap: onTap,
    );
  }
}
