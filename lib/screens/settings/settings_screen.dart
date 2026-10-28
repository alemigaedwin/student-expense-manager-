import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/backend_service.dart';
import '../../utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _currencySymbol;
  late String _userName;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _currencySymbol = app.userSetting('currency_symbol');
    _userName = app.userSetting('user_name');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          _sectionLabel('General'),
          ListTile(
            title: Text('Currency symbol / code',
                style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(_currencySymbol.isEmpty ? 'Not set' : _currencySymbol,
                style: TextStyle(color: AppColors.textSecondary)),
            trailing: Icon(Icons.edit, color: AppColors.accent, size: 18),
            onTap: () => _editText(
                title: 'Currency symbol / code',
                initial: _currencySymbol,
                onSaved: (v) {
                  setState(() => _currencySymbol = v);
                  app.setUserSetting('currency_symbol', v);
                }),
          ),
          ListTile(
            title: Text('Your Name and Address',
                style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(_userName.isEmpty ? 'Not set' : _userName,
                style: TextStyle(color: AppColors.textSecondary)),
            trailing: Icon(Icons.edit, color: AppColors.accent, size: 18),
            onTap: () => _editText(
                title: 'Your Name and Address',
                initial: _userName,
                onSaved: (v) {
                  setState(() => _userName = v);
                  app.setUserSetting('user_name', v);
                }),
          ),
          ListTile(
            title: Text('Phone number', style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(app.userSetting('profile_phone').isEmpty ? 'Add phone number' : app.userSetting('profile_phone'), style: TextStyle(color: AppColors.textSecondary)),
            trailing: Icon(Icons.edit, color: AppColors.accent, size: 18),
            onTap: () => _editText(title: 'Phone number', initial: app.userSetting('profile_phone'), onSaved: (v) { app.setUserSetting('profile_phone', v); setState(() {}); }),
          ),
          ListTile(
            title: Text('School / institution', style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(app.userSetting('profile_school').isEmpty ? 'Add school or institution' : app.userSetting('profile_school'), style: TextStyle(color: AppColors.textSecondary)),
            trailing: Icon(Icons.edit, color: AppColors.accent, size: 18),
            onTap: () => _editText(title: 'School / institution', initial: app.userSetting('profile_school'), onSaved: (v) { app.setUserSetting('profile_school', v); setState(() {}); }),
          ),
          ListTile(
            title: Text('Course / programme', style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(app.userSetting('profile_course').isEmpty ? 'Add course or programme' : app.userSetting('profile_course'), style: TextStyle(color: AppColors.textSecondary)),
            trailing: Icon(Icons.edit, color: AppColors.accent, size: 18),
            onTap: () => _editText(title: 'Course / programme', initial: app.userSetting('profile_course'), onSaved: (v) { app.setUserSetting('profile_course', v); setState(() {}); }),
          ),
          _sectionLabel('Appearance'),
          SwitchListTile(
            title: Text('Dark mode'),
            subtitle: Text(app.themeMode == ThemeMode.dark ? 'Dark theme enabled' : 'Light theme enabled'),
            value: app.themeMode == ThemeMode.dark,
            activeColor: AppColors.accent,
            onChanged: (_) => app.toggleTheme(),
          ),
          _sectionLabel('Home Screen Widgets'),
          SwitchListTile(
            title: Text('Recent Transactions',
                style: TextStyle(color: AppColors.textPrimary)),
            value: app.showRecentTransactions,
            activeColor: AppColors.accent,
            onChanged: (v) {
              app.showRecentTransactions = v;
              app.saveHomeWidgetPrefs();
              app.notifyListeners();
            },
          ),
          SwitchListTile(
            title: Text('Payment Method',
                style: TextStyle(color: AppColors.textPrimary)),
            value: app.showPaymentMethod,
            activeColor: AppColors.accent,
            onChanged: (v) {
              app.showPaymentMethod = v;
              app.saveHomeWidgetPrefs();
              app.notifyListeners();
            },
          ),
          SwitchListTile(
            title: Text('Category Chart',
                style: TextStyle(color: AppColors.textPrimary)),
            value: app.showCategoryChart,
            activeColor: AppColors.accent,
            onChanged: (v) {
              app.showCategoryChart = v;
              app.saveHomeWidgetPrefs();
              app.notifyListeners();
            },
          ),
          SwitchListTile(
            title: Text('Budget', style: TextStyle(color: AppColors.textPrimary)),
            value: app.showBudget,
            activeColor: AppColors.accent,
            onChanged: (v) {
              app.showBudget = v;
              app.saveHomeWidgetPrefs();
              app.notifyListeners();
            },
          ),
          SwitchListTile(
            title: Text('Trend', style: TextStyle(color: AppColors.textPrimary)),
            value: app.showTrend,
            activeColor: AppColors.accent,
            onChanged: (v) {
              app.showTrend = v;
              app.saveHomeWidgetPrefs();
              app.notifyListeners();
            },
          ),
          _sectionLabel('Cloud Synchronization'),
          ListTile(
            leading: Icon(
              app.isSyncing ? Icons.sync : (app.syncError == null ? Icons.cloud_done : Icons.cloud_off),
              color: app.syncError == null ? AppColors.accent : AppColors.expense,
              size: 24,
            ),
            title: Text(app.isSyncing ? 'Synchronizing…' : (app.syncError == null ? 'Sync your data' : 'Synchronization needs attention'),
                style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(
              app.syncError ?? (app.lastSyncAt == null
                  ? 'Your records are stored in your account database. Connect to the server to save changes.'
                  : 'Last successful sync: ${app.lastSyncAt!.toLocal()}'),
              style: TextStyle(color: app.syncError == null ? AppColors.textSecondary : AppColors.expense),
            ),
            trailing: Icon(Icons.refresh, color: AppColors.accent, size: 22),
            onTap: app.isSyncing ? null : app.syncNow,
          ),
          ListTile(
            leading: Icon(Icons.dns_outlined, color: AppColors.accent, size: 24),
            title: Text('Backend Server URL',
                style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(
              BackendService.baseUrl,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: Icon(Icons.edit, color: AppColors.accent, size: 18),
            onTap: _editServerUrl,
          ),
          _sectionLabel('About'),
          ListTile(
            title: Text('Student Expense Manager',
                style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Text('Version 1.0.0',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text, style: TextStyle(color: AppColors.accent, fontSize: 13)),
      );

  void _editText({
    required String title,
    required String initial,
    required ValueChanged<String> onSaved,
  }) {
    final controller = TextEditingController(text: initial);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: title.contains('Address') ? 3 : 1,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              onSaved(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editServerUrl() {
    final controller = TextEditingController(text: BackendService.baseUrl);
    String? testStatus;
    bool testing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Backend Server URL', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your cloud hosted URL or your PC local IP (e.g. http://192.168.1.X/student_expense_manager_backend/backend/api.php):',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              SizedBox(height: 12),
              TextField(
                controller: controller,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'https://your-domain/backend/api.php',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: testing
                        ? null
                        : () async {
                            setDlgState(() {
                              testing = true;
                              testStatus = null;
                            });
                            final ok = await BackendService.testConnection(controller.text.trim());
                            setDlgState(() {
                              testing = false;
                              testStatus = ok
                                  ? 'Connected! Database is reachable.'
                                  : 'Connection failed. Check URL or Wi-Fi.';
                            });
                          },
                    icon: testing
                        ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.wifi_tethering, size: 16),
                    label: Text(testing ? 'Testing…' : 'Test Connection'),
                  ),
                ],
              ),
              if (testStatus != null) ...[
                SizedBox(height: 8),
                Text(
                  testStatus!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: testStatus!.contains('Connected') ? AppColors.income : AppColors.expense,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                BackendService.setCustomUrl('');
                setState(() {});
                Navigator.pop(ctx);
              },
              child: Text('Reset Default'),
            ),
            FilledButton(
              onPressed: () {
                BackendService.setCustomUrl(controller.text.trim());
                setState(() {});
                Navigator.pop(ctx);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
