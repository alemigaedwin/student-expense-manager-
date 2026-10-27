import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';

/// Combined screen for the drawer entries: Account Summary, Summary,
/// Category Chart, Trend and Payment Method Chart. Which section(s) are
/// emphasised is controlled by the constructor flags; all are available
/// via the tabs regardless, so nothing is ever a dead end.
class SummaryScreen extends StatefulWidget {
  final bool showChart;
  final bool showTrend;
  final bool showPaymentChart;
  SummaryScreen({
    super.key,
    this.showChart = false,
    this.showTrend = false,
    this.showPaymentChart = false,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final txns = app.transactionsInSelectedRange;
    final categoryTotals = app.expenseByCategory(txns);
    final pmBalances = app.balanceByPaymentMethod();
    final totalIncome = app.totalIncome(txns);
    final totalExpense = app.totalExpense(txns);

    final colors = [
      AppColors.income,
      Color(0xFFFFC107),
      AppColors.expense,
      AppColors.accent,
      AppColors.transfer,
      Color(0xFF9C27B0),
      Color(0xFF00BCD4),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Summary'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _statCard('Income', totalIncome, AppColors.income),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _statCard('Expense', totalExpense, AppColors.expense),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text('Category Chart',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          if (categoryTotals.isEmpty)
            Text('No expense data for this period',
                style: TextStyle(color: AppColors.textSecondary))
          else
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          for (int i = 0; i < categoryTotals.length; i++)
                            PieChartSectionData(
                              value: categoryTotals.values.elementAt(i),
                              color: colors[i % colors.length],
                              radius: 60,
                              showTitle: false,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (int i = 0; i < categoryTotals.length; i++)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(
                                    width: 10,
                                    height: 10,
                                    color: colors[i % colors.length]),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                      categoryTotals.keys.elementAt(i),
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 24),
          Text('Payment Method Chart',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          ...pmBalances.entries.map((e) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: TextStyle(color: AppColors.textPrimary)),
                    Text(Formatters.amount(e.value),
                        style: TextStyle(
                            color: e.value >= 0
                                ? AppColors.textPrimary
                                : AppColors.expense)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _statCard(String label, double value, Color color) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text(Formatters.amount(value),
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
