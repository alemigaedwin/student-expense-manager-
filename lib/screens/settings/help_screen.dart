import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const List<List<String>> _items = [
    ['Add Income / Add Expense',
        'Tap the green or red tile on Home, fill in the amount, choose a category and payment method, optionally break the amount into items or attach a bill photo/PDF, then Save.'],
    ['Transfer',
        'Move money between your payment methods (e.g. Cash to Bank) without it counting as income or expense.'],
    ['Transactions',
        'Browse every transaction, filter by day/week/month/year, sort, search, or export a report.'],
    ['Calendar',
        'See a month at a glance with each day\'s expense total. Tap a day to see its transactions.'],
    ['Notebook',
        'Keep quick to‑do notes and reminders that are not necessarily transactions.'],
    ['Budget',
        'Set a spending cap per category (or an overall cap) for the month, week or year, and track what is left.'],
    ['Reminders',
        'Schedule recurring transactions (e.g. monthly tuition) so you never forget to log them.'],
    ['Account',
        'Keep separate books, e.g. one for personal spending and one for a students\' club.'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('How to use the app?'),
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => Divider(color: AppColors.border),
        itemBuilder: (context, i) {
          final item = _items[i];
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item[0],
                    style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                SizedBox(height: 4),
                Text(item[1],
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        },
      ),
    );
  }
}
