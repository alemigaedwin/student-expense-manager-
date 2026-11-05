import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/storage_service.dart';
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
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              color: AppColors.accent,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: AppColors.accent, size: 30),
                  ),
                  SizedBox(height: 8),
                  Text(
                    app.userDisplayName,
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (StorageService.getSetting('auth_email') != null)
                    Text(
                      StorageService.getSetting('auth_email')!,
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                    ),
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
