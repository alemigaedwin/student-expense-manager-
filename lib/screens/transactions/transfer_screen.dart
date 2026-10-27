import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/payment_method_model.dart';
import '../../models/transaction_model.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';

const _uuid = Uuid();

class TransferScreen extends StatefulWidget {
  TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  PaymentMethodModel? _from;
  PaymentMethodModel? _to;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    _from ??= app.paymentMethods.isNotEmpty ? app.paymentMethods.first : null;
    _to ??= app.paymentMethods.length > 1
        ? app.paymentMethods[1]
        : app.paymentMethods.isNotEmpty
            ? app.paymentMethods.first
            : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Transfer'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Amount',
              hintStyle: TextStyle(color: AppColors.textMuted),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.accent)),
            ),
          ),
          SizedBox(height: 16),
          _accountDropdown(
            label: 'From: Account',
            value: _from,
            items: app.paymentMethods,
            onChanged: (v) => setState(() => _from = v),
          ),
          SizedBox(height: 16),
          _accountDropdown(
            label: 'To  Account',
            value: _to,
            items: app.paymentMethods,
            onChanged: (v) => setState(() => _to = v),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _date = DateTime(picked.year, picked.month,
                          picked.day, _date.hour, _date.minute));
                    }
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(Formatters.dateOnly.format(_date),
                            style: TextStyle(color: AppColors.textPrimary)),
                        Icon(Icons.calendar_today,
                            color: AppColors.accent, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                      context: context, initialTime: TimeOfDay.fromDateTime(_date));
                  if (picked != null) {
                    setState(() => _date = DateTime(_date.year, _date.month,
                        _date.day, picked.hour, picked.minute));
                  }
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(Formatters.timeOnly.format(_date),
                          style: TextStyle(color: AppColors.textPrimary)),
                      SizedBox(width: 6),
                      Icon(Icons.access_time,
                          color: AppColors.accent, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _notesController,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Write Notes here [Optional]',
              hintStyle: TextStyle(color: AppColors.textMuted),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.accent)),
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16)),
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'SAVING...' : 'TRANSFER'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountDropdown({
    required String label,
    required PaymentMethodModel? value,
    required List<PaymentMethodModel> items,
    required ValueChanged<PaymentMethodModel?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PaymentMethodModel>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          style: TextStyle(color: AppColors.textPrimary),
          items: items
              .map((p) =>
                  DropdownMenuItem(value: p, child: Text(p.name)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    if (_from == null || _to == null || _from!.id == _to!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Select two different accounts')));
      return;
    }
    final app = context.read<AppState>();
    setState(() => _saving = true);
    final saved = await app.saveTransaction(TransactionModel(
      id: _uuid.v4(),
      accountId: app.currentAccountId(),
      type: TransactionType.transfer,
      amount: amount,
      paymentMethodId: _from!.id,
      toPaymentMethodId: _to!.id,
      notes: _notesController.text.trim(),
      date: _date,
    ));
    if (!mounted) return;
    if (!saved) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Could not save the transfer to your account. Check the server connection.'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transfer recorded successfully.')),
    );
    Navigator.pop(context);
  }
}
