import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';

class PaymentMethodManageScreen extends StatelessWidget {
  PaymentMethodManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final balances = app.balanceByPaymentMethod();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Payment Method'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () {
          final controller = TextEditingController();
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Add Payment Method',
                  style: TextStyle(color: AppColors.textPrimary)),
              content: TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: AppColors.textPrimary),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel')),
                TextButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;
                    app.addPaymentMethod(controller.text.trim());
                    Navigator.pop(ctx);
                  },
                  child: Text('Add'),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(8),
        itemCount: app.paymentMethods.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, i) {
          final pm = app.paymentMethods[i];
          final bal = balances[pm.name] ?? 0;
          return ListTile(
            leading: Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.accent),
            title:
                Text(pm.name, style: TextStyle(color: AppColors.textPrimary)),
            trailing: Text(Formatters.amount(bal),
                style: TextStyle(
                    color: bal >= 0 ? AppColors.textPrimary : AppColors.expense,
                    fontWeight: FontWeight.w600)),
          );
        },
      ),
    );
  }
}
