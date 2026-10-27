import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../services/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import 'receipt_chips.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel t;
  final double? runningBalance;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  TransactionTile({
    super.key,
    required this.t,
    this.runningBalance,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isTransfer = t.type == TransactionType.transfer;
    final category = app.categoryById(t.categoryId);
    final paymentMethod = app.paymentMethodById(t.paymentMethodId);
    final color = isTransfer
        ? AppColors.transfer
        : t.type == TransactionType.income
            ? AppColors.income
            : AppColors.expense;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      (category?.color ?? AppColors.transfer).withOpacity(0.2),
                  child: Icon(
                      isTransfer
                          ? Icons.swap_horiz
                          : (category?.icon ?? Icons.category),
                      size: 16,
                      color: category?.color ?? AppColors.transfer),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isTransfer ? 'Transfer' : (category?.name ?? 'Other'),
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  Formatters.signedAmount(t.amount,
                      positive: t.type == TransactionType.income),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                if (paymentMethod != null)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(paymentMethod.name,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ),
                Spacer(),
                if (runningBalance != null)
                  Text('Balance ${Formatters.amount(runningBalance!)}',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
            if (t.items.isNotEmpty) ...[
              SizedBox(height: 4),
              ...t.items.map((i) => Text(i.summary,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12))),
            ],
            if (t.notes.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(t.notes,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
            if (t.billPaths.isNotEmpty) ...[
              SizedBox(height: 6),
              ReceiptChips(references: t.billPaths, compact: true),
            ],
            SizedBox(height: 4),
            Text(
              '${Formatters.dayDateMonthYear.format(t.date)}  ${Formatters.timeOnly.format(t.date)}',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
