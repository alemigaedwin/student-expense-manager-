import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';

class AddItemsDialog extends StatefulWidget {
  final List<ItemEntry> initialItems;
  AddItemsDialog({super.key, this.initialItems = const []});

  @override
  State<AddItemsDialog> createState() => _AddItemsDialogState();
}

class _AddItemsDialogState extends State<AddItemsDialog> {
  final _itemCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  late List<ItemEntry> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.initialItems);
  }

  double get _total => _items.fold(0, (sum, i) => sum + i.total);

  void _addItem() {
    final name = _itemCtrl.text.trim();
    final qty = double.tryParse(_qtyCtrl.text.trim());
    final rate = double.tryParse(_rateCtrl.text.trim());
    if (name.isEmpty || qty == null || rate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Enter item name, quantity and rate')));
      return;
    }
    setState(() {
      _items.add(ItemEntry(
          name: name, quantity: qty, unit: _unitCtrl.text.trim(), rate: rate));
      _itemCtrl.clear();
      _qtyCtrl.clear();
      _unitCtrl.clear();
      _rateCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Items',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 16),
            _field(_itemCtrl, 'Item'),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _field(_qtyCtrl, 'Quantity', numeric: true)),
                SizedBox(width: 8),
                Expanded(child: _field(_unitCtrl, 'Unit')),
                SizedBox(width: 8),
                Expanded(child: _field(_rateCtrl, 'Rate', numeric: true)),
              ],
            ),
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _addItem,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white),
                child: Text('Add', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
            SizedBox(height: 8),
            if (_items.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final it = _items[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(it.name,
                          style: TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text(
                          '${Formatters.amount(it.quantity)} ${it.unit} @ ${Formatters.amount(it.rate)}',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(Formatters.amount(it.total),
                              style:
                                  TextStyle(color: AppColors.textPrimary)),
                          IconButton(
                            icon: Icon(Icons.close,
                                size: 16, color: AppColors.expense),
                            onPressed: () => setState(() => _items.removeAt(i)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Item', style: TextStyle(color: AppColors.textPrimary)),
                Text('Total ${Formatters.amount(_total)}',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('CANCEL')),
                TextButton(
                  onPressed: () => Navigator.pop(context, _items),
                  child: Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool numeric = false}) {
    return TextField(
      controller: c,
      keyboardType: numeric
          ? TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: AppColors.accent)),
      ),
    );
  }
}
