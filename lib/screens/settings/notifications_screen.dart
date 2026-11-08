import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../services/storage_service.dart';
import '../../utils/formatters.dart';

/// Local financial alerts. Preferences and alert calculations are available
/// offline; no email/SMS gateway or backend server is required.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _enabled = true;
  final _threshold = TextEditingController();
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _enabled = StorageService.getSetting('local_alerts_enabled') != '0';
    _threshold.text = StorageService.getSetting('local_alert_threshold') ?? '0';
    final savedTime = (StorageService.getSetting('local_reminder_time') ?? '20:00').split(':');
    if (savedTime.length == 2) {
      _reminderTime = TimeOfDay(hour: int.tryParse(savedTime[0]) ?? 20, minute: int.tryParse(savedTime[1]) ?? 0);
    }
  }

  @override
  void dispose() {
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _reminderTime);
    if (selected != null && mounted) setState(() => _reminderTime = selected);
  }

  void _save() {
    final threshold = double.tryParse(_threshold.text.trim());
    if (threshold == null || threshold < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid non-negative balance threshold.')));
      return;
    }
    StorageService.setSetting('local_alerts_enabled', _enabled ? '1' : '0');
    StorageService.setSetting('local_alert_threshold', threshold.toString());
    StorageService.setSetting('local_reminder_time', '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}');
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert settings saved on this device.')));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final transactions = app.transactionsAllTime;
    final income = app.totalIncome(transactions);
    final expenses = app.totalExpense(transactions);
    final balance = income - expenses;
    final threshold = double.tryParse(_threshold.text) ?? 0;
    final isLow = _enabled && threshold > 0 && balance <= threshold;
    final budgetAlerts = app.budgets.map((budget) {
      final category = app.categoryById(budget.categoryId);
      final spent = app.spentForCategory(budget.categoryId, budget.period, budget.periodStart);
      final remaining = budget.amount - spent;
      return (name: category?.name ?? 'Category', remaining: remaining, amount: budget.amount, low: remaining <= budget.amount * 0.2);
    }).where((item) => item.low).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts & reminders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Current balance', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(Formatters.amount(balance), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: balance < 0 ? Colors.red : Colors.green)),
                const SizedBox(height: 8),
                Text('Income  ${Formatters.amount(income)}     Spending  ${Formatters.amount(expenses)}'),
              ]),
            ),
          ),
          if (isLow)
            Card(color: Colors.orange.shade50, child: const ListTile(leading: Icon(Icons.warning_amber, color: Colors.deepOrange), title: Text('Balance is at or below your alert threshold.'))),
          if (budgetAlerts.isNotEmpty) ...[
            Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text('Budgets needing attention', style: Theme.of(context).textTheme.titleMedium)),
            ...budgetAlerts.map((item) => Card(child: ListTile(
              leading: const Icon(Icons.savings_outlined, color: Colors.deepOrange),
              title: Text(item.name),
              subtitle: Text('${Formatters.amount(item.remaining)} remaining of ${Formatters.amount(item.amount)}'),
            ))),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show local balance alerts'),
            subtitle: const Text('Alerts are calculated from transactions stored on this phone.'),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          TextField(
            controller: _threshold,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Low-balance threshold', helperText: 'Set to 0 to turn off the threshold check.', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Card(child: ListTile(
            leading: const Icon(Icons.alarm_outlined),
            title: const Text('Daily check-in time'),
            subtitle: Text(_reminderTime.format(context)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickTime,
          )),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('The selected time is saved as a reminder preference. This version displays in-app alerts when you open this page; it does not send SMS, email, or scheduled system notifications.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Save alert settings')),
        ],
      ),
    );
  }
}
