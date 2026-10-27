import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/category_model.dart';
import '../../models/receipt_model.dart';
import '../../models/transaction_model.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/receipt_chips.dart';
import '../category/category_picker_screen.dart';
import '../payment_method/payment_method_picker_screen.dart';
import 'add_items_dialog.dart';
import 'bill_attachment_picker.dart';
import 'calculator_dialog.dart';
import '../../utils/category_icon.dart';

const _uuid = Uuid();

class AddTransactionScreen extends StatefulWidget {
  final TransactionType type;
  final TransactionModel? existing;
  final DateTime? initialDate;

  AddTransactionScreen({
    super.key,
    required this.type,
    this.existing,
    this.initialDate,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  CategoryModel? _category;
  String? _paymentMethodId;
  String? _paymentMethodName;
  DateTime _date = DateTime.now();
  List<ItemEntry> _items = [];
  List<String> _bills = [];
  bool _saving = false;
  bool _uploading = false;
  bool _savedOk = false;
  late final AppState _app;
  // Receipts uploaded on this screen that are not attached to a saved
  // transaction yet. They are deleted again if the user leaves without saving.
  final Set<String> _newReceiptIds = <String>{};
  static const int _maxReceipts = 5;
  static const int _maxReceiptBytes = 4 * 1024 * 1024;

  bool get isIncome => widget.type == TransactionType.income;
  Color get accent => isIncome ? AppColors.income : AppColors.expense;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _app = app;

    if (widget.existing != null) {
      final t = widget.existing!;
      _amountController.text = t.amount == t.amount.roundToDouble()
          ? t.amount.toInt().toString()
          : t.amount.toString();
      _notesController.text = t.notes;
      _category = app.categoryById(t.categoryId);
      _paymentMethodId = t.paymentMethodId;
      _paymentMethodName = app.paymentMethodById(t.paymentMethodId)?.name;
      _date = t.date;
      _items = List.of(t.items);
      _bills = List.of(t.billPaths);
    } else {
      final defaults = app.categoriesFor(
        isIncome ? CategoryKind.income : CategoryKind.expense,
      );
      if (defaults.isNotEmpty) _category = defaults.first;

      if (app.paymentMethods.isNotEmpty) {
        _paymentMethodId = app.paymentMethods.first.id;
        _paymentMethodName = app.paymentMethods.first.name;
      }

      if (widget.initialDate != null) {
        final now = DateTime.now();
        final d = widget.initialDate!;
        _date = DateTime(d.year, d.month, d.day, now.hour, now.minute);
      }
    }
  }

  @override
  void dispose() {
    if (!_savedOk) {
      for (final id in _newReceiptIds) {
        unawaited(_app.discardReceipt(id));
      }
    }
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () => _showTypeSwitcher(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isIncome ? 'Add Income' : 'Add Expense',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Icon(Icons.keyboard_arrow_down, size: 23),
            ],
          ),
        ),
      ),
      body: Container(
        color: AppColors.surface,
        margin: EdgeInsets.fromLTRB(6, 0, 6, 0),
        child: ListView(
          padding: EdgeInsets.fromLTRB(18, 26, 18, 24),
          children: [
            _amountField(),
            SizedBox(height: 16),
            _categoryField(),
            SizedBox(height: 16),
            _paymentField(),
            SizedBox(height: 16),
            _notesField(),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _billButton()),
                SizedBox(width: 10),
                Expanded(child: _itemsButton()),
              ],
            ),
            if (_bills.isNotEmpty) ...[
              SizedBox(height: 10),
              ReceiptChips(references: _bills, onRemove: _removeReceipt),
            ],
            SizedBox(height: 16),
            _dateTimeRow(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              Expanded(
                child: _bottomBarButton(
                  'Payment Method',
                  _pickPaymentMethod,
                ),
              ),
              Expanded(
                child: _bottomBarButton(
                  'Category',
                  _pickCategory,
                ),
              ),
              Expanded(
                child: Material(
                  color: AppColors.accent,
                  child: InkWell(
                    onTap: _saving ? null : _save,
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountField() {
    return SizedBox(
      height: 80,
      child: TextField(
        controller: _amountController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          color: accent,
          fontSize: 19,
          fontStyle: FontStyle.italic,
        ),
        decoration: InputDecoration(
          labelText: isIncome ? 'Income' : 'Expense',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(
            color: accent,
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.calculate_outlined, color: AppColors.accent),
            onPressed: _openCalculator,
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: AppColors.accent, width: 1.3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: AppColors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _categoryField() {
    return _selectionField(
      label: 'Category',
      value: _category?.name ?? 'Select category',
      leading: _category == null
          ? null
          : CategoryIcon(category: _category!, size: 32),
      trailing: Icon(
        Icons.category,
        color: AppColors.accent,
        size: 26,
      ),
      onTap: _pickCategory,
    );
  }

  Widget _paymentField() {
    return _selectionField(
      label: 'Payment Method',
      value: _paymentMethodName ?? 'Select payment method',
      trailing: Icon(
        Icons.account_balance_wallet,
        color: AppColors.accent,
        size: 26,
      ),
      onTap: _pickPaymentMethod,
    );
  }

  Widget _selectionField({
    required String label,
    required String value,
    required Widget trailing,
    Widget? leading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 68,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
            suffixIcon: trailing,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide:
                  BorderSide(color: AppColors.textSecondary, width: .9),
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading,
                SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notesField() {
    return SizedBox(
      height: 76,
      child: TextField(
        controller: _notesController,
        maxLines: 1,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontStyle: FontStyle.italic,
        ),
        decoration: InputDecoration(
          hintText: 'Notes',
          hintStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontStyle: FontStyle.italic,
          ),
          prefixIcon:
              Icon(Icons.mic_none, color: AppColors.textSecondary),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide:
                BorderSide(color: AppColors.textSecondary, width: .9),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: AppColors.accent),
          ),
        ),
      ),
    );
  }

  Widget _billButton() {
    return Builder(
      builder: (anchorContext) => OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(52),
          side: BorderSide(color: AppColors.textSecondary, width: .8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          padding: EdgeInsets.symmetric(horizontal: 8),
        ),
        icon: Icon(Icons.add_a_photo_outlined,
            color: AppColors.accent, size: 27),
        label: Text(
          _uploading
              ? 'Uploading...'
              : (_bills.isEmpty ? 'Add Bills' : '${_bills.length} Bills'),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontStyle: FontStyle.italic,
          ),
        ),
        onPressed: _uploading ? null : () => _attachReceipt(anchorContext),
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _attachReceipt(BuildContext anchorContext) async {
    if (_bills.length >= _maxReceipts) {
      _toast('You can attach up to $_maxReceipts receipts to one transaction.');
      return;
    }
    PickedReceipt? picked;
    try {
      picked = await showBillAttachmentPicker(anchorContext);
    } catch (_) {
      _toast('Could not open the camera or gallery. Check the app permissions in your phone settings.');
      return;
    }
    if (picked == null || !mounted) return;
    if (picked.bytes.length > _maxReceiptBytes) {
      _toast('That file is larger than 4 MB. Choose a smaller photo or PDF.');
      return;
    }
    setState(() => _uploading = true);
    try {
      final info = await _app.uploadReceipt(picked.bytes, picked.fileName);
      if (!mounted) {
        // Screen was closed mid-upload: do not leave an orphan in the database.
        unawaited(_app.discardReceipt(info.id));
        return;
      }
      setState(() {
        _bills.add(info.reference);
        _newReceiptIds.add(info.id);
      });
      _toast('Receipt uploaded successfully.');
    } catch (e) {
      _toast('Receipt upload failed. ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removeReceipt(String reference) {
    setState(() => _bills.remove(reference));
    final id = ReceiptInfo.idFromReference(reference);
    // A receipt uploaded on this screen can be deleted right away. A receipt
    // that belongs to an already saved transaction is deleted when the user
    // saves the change, so Cancel keeps it.
    if (id != null && _newReceiptIds.remove(id)) {
      unawaited(_app.discardReceipt(id));
    }
    _toast('Receipt removed.');
  }

  Widget _itemsButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(52),
        side: BorderSide(color: AppColors.textSecondary, width: .8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        padding: EdgeInsets.symmetric(horizontal: 8),
      ),
      icon: Icon(Icons.list, color: AppColors.accent, size: 27),
      label: Text(
        _items.isEmpty ? 'Add Items' : '${_items.length} Items',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontStyle: FontStyle.italic,
        ),
      ),
      onPressed: () async {
        final result = await showDialog<List<ItemEntry>>(
          context: context,
          builder: (_) => AddItemsDialog(initialItems: _items),
        );
        if (result != null) {
          setState(() {
            _items = result;
            final total = _items.fold(0.0, (s, i) => s + i.total);
            if (total > 0) {
              _amountController.text = total == total.roundToDouble()
                  ? total.toInt().toString()
                  : total.toString();
            }
          });
        }
      },
    );
  }

  Widget _dateTimeRow() {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: InkWell(
            onTap: _pickDate,
            child: Container(
              height: 58,
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.textSecondary, width: .8),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    icon: Icon(Icons.chevron_left,
                        color: AppColors.textPrimary, size: 27),
                    onPressed: () => setState(
                        () => _date = _date.subtract(Duration(days: 1))),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        Formatters.dateOnly.format(_date),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    icon: Icon(Icons.chevron_right,
                        color: AppColors.textPrimary, size: 27),
                    onPressed: () => setState(
                        () => _date = _date.add(Duration(days: 1))),
                  ),
                  SizedBox(width: 7),
                  Icon(Icons.calendar_today,
                      color: AppColors.accent, size: 26),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 7),
        Expanded(
          flex: 4,
          child: InkWell(
            onTap: _pickTime,
            child: Container(
              height: 58,
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.textSecondary, width: .8),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Formatters.timeOnly.format(_date),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.access_time,
                      color: AppColors.accent, size: 26),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBarButton(String label, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.textSecondary, width: .6),
              left: BorderSide(color: AppColors.textSecondary, width: .6),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCategory() async {
    final selected = await showCategoryPicker(
      context,
      kind: isIncome ? CategoryKind.income : CategoryKind.expense,
    );
    if (selected != null) setState(() => _category = selected);
  }

  Future<void> _pickPaymentMethod() async {
    final selected = await showPaymentMethodPicker(context);
    if (selected != null) {
      setState(() {
        _paymentMethodId = selected.id;
        _paymentMethodName = selected.name;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = DateTime(
          picked.year, picked.month, picked.day, _date.hour, _date.minute));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = DateTime(
          _date.year, _date.month, _date.day, picked.hour, picked.minute));
    }
  }

  Future<void> _openCalculator() async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) =>
          CalculatorDialog(initialExpression: _amountController.text.trim()),
    );
    if (result != null) {
      setState(() {
        _amountController.text = result == result.roundToDouble()
            ? result.toInt().toString()
            : result.toString();
      });
    }
  }

  Future<void> _showTypeSwitcher(BuildContext anchorContext) async {
    final choice = await showMenu<TransactionType>(
      context: anchorContext,
      position: RelativeRect.fromLTRB(60, 65, 0, 0),
      items: [
        PopupMenuItem(
          value: TransactionType.income,
          child: Text('Add Income'),
        ),
        PopupMenuItem(
          value: TransactionType.expense,
          child: Text('Add Expense'),
        ),
      ],
    );
    if (choice == null || choice == widget.type || !mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          type: choice,
          initialDate: _date,
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Select a category')),
      );
      return;
    }

    final app = context.read<AppState>();
    final t = TransactionModel(
      id: widget.existing?.id ?? _uuid.v4(),
      accountId: app.currentAccountId(),
      type: widget.type,
      amount: amount,
      categoryId: _category!.id,
      paymentMethodId: _paymentMethodId,
      notes: _notesController.text.trim(),
      items: _items,
      billPaths: _bills,
      date: _date,
    );

    setState(() => _saving = true);
    final saved = await app.saveTransaction(t);
    if (!mounted) return;
    if (!saved) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save this transaction to your account. ${app.syncError ?? 'Check your connection and try again.'}',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
    _savedOk = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.existing != null
              ? 'Transaction updated successfully.'
              : isIncome
                  ? 'Income added successfully.'
                  : 'Expense added successfully.',
        ),
      ),
    );
    Navigator.pop(context);
  }
}
