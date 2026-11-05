import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/app_state.dart';
import '../../services/backend_service.dart';
import '../../utils/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool loading = true;
  bool saving = false;
  bool sendingTest = false;
  String? error;
  List<dynamic> notices = [];
  Map<String, dynamic> summary = {};

  final phone = TextEditingController();
  final threshold = TextEditingController(text: '0');
  final carrierGateway = TextEditingController();
  TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);

  bool emailEnabled = true;
  bool smsEnabled = false;
  bool dailyEnabled = true;
  bool balanceEnabled = true;
  bool prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    phone.dispose();
    threshold.dispose();
    carrierGateway.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await BackendService.notifications();
      final d = Map<String, dynamic>.from(r['data'] as Map? ?? {});
      final p = Map<String, dynamic>.from(d['preferences'] as Map? ?? {});

      if (!mounted) return;

      final rawTime = (p['reminderTime'] ?? '20:00').toString();
      final parts = rawTime.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]) ?? 20;
        final m = int.tryParse(parts[1]) ?? 0;
        reminderTime = TimeOfDay(hour: h, minute: m);
      }

      setState(() {
        notices = d['notifications'] as List? ?? [];
        summary = Map<String, dynamic>.from(d['summary'] as Map? ?? {});
        phone.text = '${p['phoneNumber'] ?? ''}';
        threshold.text = '${p['lowBalanceThreshold'] ?? 0}';
        carrierGateway.text = '${p['carrierGateway'] ?? ''}';
        emailEnabled = p['emailEnabled'] != false;
        smsEnabled = p['smsEnabled'] == true;
        dailyEnabled = p['dailyReminderEnabled'] != false;
        balanceEnabled = p['balanceAlertEnabled'] != false;
        prefsLoaded = true;
        loading = false;
        error = null;
      });

      await BackendService.markNotificationsRead();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime,
      helpText: 'SELECT DAILY REMINDER TIME',
    );
    if (picked != null) {
      setState(() => reminderTime = picked);
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final timeStr = _formatTimeOfDay(reminderTime);
      await BackendService.saveNotificationPreferences({
        'phoneNumber': phone.text.trim(),
        'emailEnabled': emailEnabled,
        'smsEnabled': smsEnabled,
        'dailyReminderEnabled': dailyEnabled,
        'balanceAlertEnabled': balanceEnabled,
        'lowBalanceThreshold': double.tryParse(threshold.text.trim()) ?? 0,
        'reminderTime': timeStr,
        'carrierGateway': carrierGateway.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preferences saved. Daily reminder scheduled for ${reminderTime.format(context)}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save preferences: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _sendDirectSms() async {
    final number = phone.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number first.')),
      );
      return;
    }
    final bal = summary['balance'] ?? 0;
    final inc = summary['income'] ?? 0;
    final exp = summary['expense'] ?? 0;
    final message = 'Student Expense Manager Alert: Current Balance: $bal (Income: $inc, Expense: $exp). Daily reminder at ${_formatTimeOfDay(reminderTime)}.';
    final uri = Uri.parse('sms:$number?body=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open default SMS application.')),
      );
    }
  }

  Future<void> _triggerTestAlert() async {
    setState(() => sendingTest = true);
    try {
      final testUrl = BackendService.buildUri('send_alerts', {'action': 'test'});
      // We can trigger it via a quick HTTP get or open in browser
      final uri = Uri.parse(BackendService.baseUrl.replaceAll('api.php', 'send_alerts.php?action=test'));
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert check dispatched! Refresh to view in history below.')),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error triggering alert: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => sendingTest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & Reminders'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Refresh notifications'),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load notifications.\n$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    children: [
                      // Balance Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet, color: AppColors.accent, size: 22),
                                  const SizedBox(width: 8),
                                  const Text('Recorded Financial Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const Spacer(),
                                  Text(
                                    '${summary['balance'] ?? 0}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: (summary['balance'] ?? 0) is num && (summary['balance'] ?? 0) < 0
                                          ? Colors.red
                                          : Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Income: +${summary['income'] ?? 0}', style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text('Total Expenses: -${summary['expense'] ?? 0}', style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Particular Time Setting
                      const Text('Schedule & Particular Time', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEFF6FF),
                            child: Icon(Icons.alarm, color: AppColors.accent),
                          ),
                          title: const Text('Daily Check-in Reminder Time', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Triggers daily at: ${reminderTime.format(context)} (${_formatTimeOfDay(reminderTime)})'),
                          trailing: FilledButton.tonal(
                            onPressed: _pickTime,
                            child: const Text('Change Time'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Delivery Channels
                      const Text('Notification Channels', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),

                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: dailyEnabled,
                              onChanged: (v) => setState(() => dailyEnabled = v),
                              secondary: const Icon(Icons.calendar_today, color: Colors.blue),
                              title: const Text('Daily Expense Reminder'),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              value: emailEnabled,
                              onChanged: (v) => setState(() => emailEnabled = v),
                              secondary: const Icon(Icons.email_outlined, color: Colors.deepPurple),
                              title: const Text('Email Notifications'),
                              subtitle: const Text('Sends alerts to your registered email address'),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              value: balanceEnabled,
                              onChanged: (v) => setState(() => balanceEnabled = v),
                              secondary: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                              title: const Text('Low Balance Safety Alerts'),
                              subtitle: const Text('Notifies you when total funds or category balance is running low'),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: TextField(
                                controller: threshold,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Overall Low Balance Alert Threshold',
                                  helperText: 'Alert triggers when your balance is at or below this amount',
                                  prefixIcon: Icon(Icons.attach_money),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              value: smsEnabled,
                              onChanged: (v) => setState(() => smsEnabled = v),
                              secondary: const Icon(Icons.sms_outlined, color: Colors.teal),
                              title: const Text('SMS / Mobile Carrier Alerts'),
                              subtitle: const Text('Delivers SMS alerts to your phone'),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: phone,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: 'Your Phone Number',
                                      hintText: '+2567XXXXXXXX or local mobile number',
                                      prefixIcon: Icon(Icons.phone),
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: carrierGateway,
                                    decoration: const InputDecoration(
                                      labelText: 'Email-to-SMS Gateway (Optional)',
                                      hintText: 'e.g. vtext.com, txt.att.net, tmomail.net',
                                      prefixIcon: Icon(Icons.cell_tower),
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildCategoryAlertCard(context),
                      const SizedBox(height: 16),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: saving ? null : _save,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(saving ? 'Saving...' : 'Save Preferences'),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.all(14)),
                        ),
                      ),

                      const Divider(height: 36),

                      // Notification History
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Alert & Message History', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          Text('${notices.length} recorded', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (notices.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: Center(
                            child: Text(
                              'No alerts yet. Scheduled reminders and balance alerts will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...notices.map((n) {
                          final m = Map<String, dynamic>.from(n as Map);
                          final isBal = m['type'] == 'balance_alert';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isBal ? Colors.orange.shade100 : Colors.blue.shade100,
                                child: Icon(
                                  isBal ? Icons.warning_amber_rounded : Icons.notifications_active_outlined,
                                  color: isBal ? Colors.orange.shade800 : Colors.blue.shade800,
                                ),
                              ),
                              title: Text('${m['title'] ?? 'Notification'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text('${m['message'] ?? ''}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Channel: ${m['channel'] ?? 'in_app'} • Status: ${m['deliveryStatus'] ?? ''}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCategoryAlertCard(BuildContext context) {
    final app = context.watch<AppState>();
    final budgets = app.budgets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Category Low Remaining Balance Alerts', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          'Monitors category spending caps (meals, books, tuition) to alert you when category funds run low.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: budgets.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No category budgets configured yet. Create category budgets to monitor remaining funds.', style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
                    ),
                  ]
                : budgets.map((b) {
                    final cat = app.categoryById(b.categoryId);
                    final spent = app.spentForCategory(b.categoryId, b.period, b.periodStart);
                    final remaining = b.amount - spent;
                    final isLow = remaining <= (b.amount * 0.2) || remaining < 0;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isLow ? Colors.red.shade100 : Colors.green.shade100,
                        child: Icon(cat?.icon ?? Icons.category, color: isLow ? Colors.red : Colors.green.shade800),
                      ),
                      title: Text(cat?.name ?? 'Category', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Budget: ${b.amount} • Spent: $spent • Remaining: $remaining'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: isLow ? Colors.red.shade100 : Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Text(isLow ? 'LOW' : 'OK', style: TextStyle(color: isLow ? Colors.red.shade900 : Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }
}
