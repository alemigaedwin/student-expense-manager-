import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment_method_model.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';

Future<PaymentMethodModel?> showPaymentMethodPicker(BuildContext context) {
  return showModalBottomSheet<PaymentMethodModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * .48,
      child: PaymentMethodPickerPanel(),
    ),
  );
}

class PaymentMethodPickerScreen extends StatefulWidget {
  PaymentMethodPickerScreen({super.key});

  @override
  State<PaymentMethodPickerScreen> createState() =>
      _PaymentMethodPickerScreenState();
}

class _PaymentMethodPickerScreenState extends State<PaymentMethodPickerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PaymentMethodPickerPanel(fullScreen: true),
      ),
    );
  }
}

class PaymentMethodPickerPanel extends StatefulWidget {
  final bool fullScreen;
  PaymentMethodPickerPanel({super.key, this.fullScreen = false});

  @override
  State<PaymentMethodPickerPanel> createState() =>
      _PaymentMethodPickerPanelState();
}

class _PaymentMethodPickerPanelState extends State<PaymentMethodPickerPanel> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final all = app.paymentMethods;
    final filtered = all
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Material(
      color: AppColors.surface,
      child: Column(
        children: [
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.accent,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Payment Method',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () => _showAddDialog(context),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'Add New',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(5, 5, 5, 4),
            child: SizedBox(
              height: 38,
              child: TextField(
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.accent,
                    size: 25,
                  ),
                  prefixIconConstraints:
                      BoxConstraints(minWidth: 40),
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide:
                        BorderSide(color: AppColors.textPrimary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide:
                        BorderSide(color: AppColors.accent),
                  ),
                ),
                onChanged: (v) => setState(() => query = v),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, i) {
                final p = filtered[i];
                return InkWell(
                  onTap: () => Navigator.pop(context, p),
                  child: SizedBox(
                    height: 44,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          p.name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Add Payment Method',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: 'e.g. Mobile Money'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final pm = context.read<AppState>().addPaymentMethod(name);
              Navigator.pop(ctx);
              Navigator.pop(context, pm);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}
