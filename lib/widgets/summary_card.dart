import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';

/// The Income / Expense / Balance + Previous Balance summary block
/// shown on Home, Calendar, Transactions and Notebook screens.
class SummaryStrip extends StatelessWidget {
  final double income;
  final double expense;
  final double previousBalance;
  SummaryStrip({
    super.key,
    required this.income,
    required this.expense,
    this.previousBalance = 0,
  });

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;
    final overall = balance + previousBalance;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                _col('Income', Formatters.amount(income), AppColors.income),
                _divider(),
                _col('Expense', Formatters.amount(expense), AppColors.expense),
                _divider(),
                _col('Balance', Formatters.signedAmount(balance, positive: balance >= 0),
                    balance >= 0 ? AppColors.textPrimary : AppColors.expense),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          _kv('Previous Balance', Formatters.amount(previousBalance)),
          Divider(height: 1, color: AppColors.border),
          _kv('Balance', Formatters.signedAmount(overall, positive: overall >= 0),
              valueColor: overall >= 0 ? AppColors.textPrimary : AppColors.expense),
        ],
      ),
    );
  }

  Widget _col(String label, String value, Color color) => Expanded(
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _divider() => Container(width: 1, height: 32, color: AppColors.border);

  Widget _kv(String k, String v, {Color? valueColor}) =>
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: TextStyle(color: AppColors.textPrimary)),
            Text(v,
                style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

/// Header bar with left/right chevrons and the current date-range label.
class DateRangeBar extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  DateRangeBar(
      {super.key,
      required this.label,
      required this.onPrev,
      required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
              icon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
              onPressed: onPrev),
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ),
          IconButton(
              icon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
              onPressed: onNext),
        ],
      ),
    );
  }
}
