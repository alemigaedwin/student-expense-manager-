import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/category_model.dart';
import '../../models/reminder_model.dart';
import '../../models/transaction_model.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../category/category_picker_screen.dart';
import '../payment_method/payment_method_picker_screen.dart';

const _uuid = Uuid();

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Map<RecurrenceType, Color> _legendColors = {
    RecurrenceType.once: Color(0xFF4CAF50),
    RecurrenceType.daily: Color(0xFF2196F3),
    RecurrenceType.weekly: Color(0xFFFF5722),
    RecurrenceType.monthly: Color(0xFFFFEB3B),
    RecurrenceType.yearly: Color(0xFFE91E63),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Reminders'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [Tab(text: 'TODAY'), Tab(text: 'ALL')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () => _openAddReminder(context, app),
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _list(app, app.remindersToday),
                _list(app, app.reminders),
              ],
            ),
          ),
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              children: _legendColors.entries
                  .map((e) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 10,
                              height: 10,
                              color: e.value,
                              margin: EdgeInsets.only(right: 4)),
                          Text(_label(e.key),
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _label(RecurrenceType t) {
    switch (t) {
      case RecurrenceType.once:
        return 'Once';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
    }
  }

  Widget _list(AppState app, List<ReminderModel> list) {
    if (list.isEmpty) {
      return Center(
          child: Text('No reminders', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final r = list[i];
        final cat = app.categoryById(r.categoryId);
        final pm = app.paymentMethodById(r.paymentMethodId);
        return Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(left: BorderSide(color: _legendColors[r.recurrence]!, width: 4)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: ListTile(
            leading: Icon(cat?.icon ?? Icons.category, color: cat?.color ?? AppColors.accent),
            title: Text(cat?.name ?? '-', style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(
                '${Formatters.dateOnly.format(r.nextDate)} • ${pm?.name ?? '-'}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(Formatters.amount(r.amount),
                    style: TextStyle(
                        color: r.type == TransactionType.income
                            ? AppColors.income
                            : AppColors.expense)),
                IconButton(
                  icon: Icon(Icons.check_circle_outline, color: AppColors.accent),
                  tooltip: 'Record transaction now',
                  onPressed: () => _recordReminder(app, r),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.expense),
                  onPressed: () => app.deleteReminder(r.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _recordReminder(AppState app, ReminderModel reminder) async {
    final saved = await app.applyReminder(reminder.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved
            ? 'Reminder transaction recorded successfully.'
            : 'Could not save the reminder transaction to your account.'),
      ),
    );
  }

  Future<void> _openAddReminder(BuildContext context, AppState app) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (ctx) => const _AddReminderSheet(),
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _amountController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  CategoryModel? _category;
  String? _paymentMethodId;
  String? _paymentMethodName;
  RecurrenceType _recurrence = RecurrenceType.monthly;
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New Reminder',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(value: TransactionType.income, label: Text('Income')),
                ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _category = null;
              }),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: 'Amount'),
            ),
            SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_category?.name ?? 'Select category',
                  style: TextStyle(color: AppColors.textPrimary)),
              trailing: Icon(Icons.chevron_right, color: AppColors.accent),
              onTap: () async {
                final selected = await Navigator.push<CategoryModel>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CategoryPickerScreen(
                            kind: _type == TransactionType.income
                                ? CategoryKind.income
                                : CategoryKind.expense)));
                if (selected != null) setState(() => _category = selected);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_paymentMethodName ?? 'Select payment method',
                  style: TextStyle(color: AppColors.textPrimary)),
              trailing: Icon(Icons.chevron_right, color: AppColors.accent),
              onTap: () async {
                final selected = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PaymentMethodPickerScreen()));
                if (selected != null) {
                  setState(() {
                    _paymentMethodId = selected.id;
                    _paymentMethodName = selected.name;
                  });
                }
              },
            ),
            DropdownButtonFormField<RecurrenceType>(
              initialValue: _recurrence,
              dropdownColor: AppColors.surface,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: 'Repeat'),
              items: RecurrenceType.values
                  .map((r) => DropdownMenuItem(
                      value: r, child: Text(r.name[0].toUpperCase() + r.name.substring(1))))
                  .toList(),
              onChanged: (v) => setState(() => _recurrence = v ?? _recurrence),
            ),
            SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Next: ${Formatters.dateOnly.format(_date)}',
                  style: TextStyle(color: AppColors.textPrimary)),
              trailing: Icon(Icons.calendar_today, color: AppColors.accent),
              onTap: () async {
                final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100));
                if (picked != null) setState(() => _date = picked);
              },
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                onPressed: _save,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Save Reminder'),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0 || _category == null || _paymentMethodId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fill in all fields')));
      return;
    }
    context.read<AppState>().addReminder(ReminderModel(
          id: _uuid.v4(),
          accountId: context.read<AppState>().currentAccountId(),
          categoryId: _category!.id,
          paymentMethodId: _paymentMethodId!,
          amount: amount,
          type: _type,
          recurrence: _recurrence,
          nextDate: _date,
        ));
    Navigator.pop(context);
  }
}
