import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../services/ai_insights_service.dart';
import '../../widgets/action_button.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_tile.dart';
import '../ai/ai_insights_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transactions_screen.dart';
import '../transactions/transfer_screen.dart';
import '../budget/budget_screen.dart';

class HomeTab extends StatelessWidget {
  HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final txns = app.transactionsInSelectedRange;
    final income = app.totalIncome(txns);
    final expense = app.totalExpense(txns);
    final prevBalance = app.previousBalance(app.rangeStart);
    final recent = app.transactionsAllTime.take(5).toList();
    final pmBalances = app.balanceByPaymentMethod();
    final categoryTotals = app.expenseByCategory(txns);
    final topInsight = AiInsightsService(app).generate().first;

    return RefreshIndicator(
      onRefresh: () async => app.load(),
      child: ListView(
        padding: EdgeInsets.only(top: 8, bottom: 90),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AiInsightsScreen())),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: topInsight.color.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: topInsight.color.withOpacity(0.15),
                      child: Icon(topInsight.icon,
                          color: topInsight.color, size: 18),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Insight',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                          Text(topInsight.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: [
                HomeActionButton(
                  icon: Icons.add_circle_outline,
                  color: AppColors.income,
                  label: 'Add Income',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddTransactionScreen(
                              type: TransactionType.income))),
                ),
                HomeActionButton(
                  icon: Icons.remove_circle_outline,
                  color: AppColors.expense,
                  label: 'Add Expense',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddTransactionScreen(
                              type: TransactionType.expense))),
                ),
                HomeActionButton(
                  icon: Icons.swap_horiz,
                  color: AppColors.transfer,
                  label: 'Transfer',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => TransferScreen())),
                ),
                HomeActionButton(
                  icon: Icons.list_alt,
                  color: AppColors.accent,
                  label: 'Transactions',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TransactionsScreen())),
                ),
              ],
            ),
          ),
          DateRangeBar(
            label:
                '${Formatters.dateOnly.format(app.rangeStart)} -> ${Formatters.dateOnly.format(app.rangeEnd)}',
            onPrev: () => app.shiftRange(-1),
            onNext: () => app.shiftRange(1),
          ),
          SummaryStrip(
              income: income, expense: expense, previousBalance: prevBalance),
          if (app.showRecentTransactions)
            SectionCard(
              title: 'Recent Transactions',
              onMore: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => TransactionsScreen())),
              child: recent.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No transactions yet',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : Column(
                      children: recent
                          .map((t) => Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: _MiniTxnRow(t: t),
                              ))
                          .toList(),
                    ),
            ),
          if (app.showPaymentMethod)
            SectionCard(
              title: 'Payment Method',
              onMore: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TransactionsScreen())),
              child: Column(
                children: pmBalances.entries
                    .map((e) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key,
                                  style: TextStyle(
                                      color: AppColors.textPrimary)),
                              Text(Formatters.signedAmount(e.value,
                                  positive: e.value >= 0),
                                  style: TextStyle(
                                      color: e.value >= 0
                                          ? AppColors.textPrimary
                                          : AppColors.expense)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          if (app.showCategoryChart && categoryTotals.isNotEmpty)
            SectionCard(
              title: 'Monthly Expense',
              onMore: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TransactionsScreen())),
              child: SizedBox(
                height: 220,
                child: _ExpenseBarChart(data: categoryTotals),
              ),
            ),
          if (app.showBudget)
            SectionCard(
              title: 'Budget',
              onMore: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => BudgetScreen())),
              child: Text('Tap "More" to manage your budgets',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          if (app.showTrend)
            SectionCard(
              title: 'Trend',
              child: SizedBox(
                height: 200,
                child: _TrendChart(),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniTxnRow extends StatelessWidget {
  final TransactionModel t;
  _MiniTxnRow({required this.t});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final isTransfer = t.type == TransactionType.transfer;
    final category = app.categoryById(t.categoryId);
    final pm = app.paymentMethodById(t.paymentMethodId);
    final color = isTransfer
        ? AppColors.transfer
        : t.type == TransactionType.income
            ? AppColors.income
            : AppColors.expense;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(Formatters.dayDateMonthYear.format(t.date),
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
            SizedBox(width: 8),
            Expanded(
              child: Text(isTransfer ? 'Transfer' : (category?.name ?? '-'),
                  style: TextStyle(color: AppColors.textPrimary)),
            ),
            Text(
                Formatters.signedAmount(t.amount,
                    positive: t.type == TransactionType.income),
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        if (pm != null)
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('[${pm.name}]',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
        if (t.items.isNotEmpty)
          Text(t.items.first.summary,
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Divider(color: AppColors.border, height: 14),
      ],
    );
  }
}

class _ExpenseBarChart extends StatelessWidget {
  final Map<String, double> data;
  _ExpenseBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();
    final maxVal = top.isEmpty
        ? 1.0
        : top.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final colors = [
      AppColors.income,
      Color(0xFFFFC107),
      AppColors.expense,
      AppColors.accent,
      AppColors.transfer,
      Color(0xFF9C27B0),
    ];
    return BarChart(
      BarChartData(
        maxY: maxVal * 1.25,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (v, meta) => Text(
                      Formatters.amount(v),
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 10)))),
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= top.length) return SizedBox();
                final label = top[idx].key;
                return Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    label.length > 8 ? '${label.substring(0, 8)}…' : label,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (int i = 0; i < top.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: top[i].value,
                color: colors[i % colors.length],
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final now = app.rangeStart;
    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i, 1));
    final spots = <FlSpot>[];
    for (int i = 0; i < months.length; i++) {
      final start = months[i];
      final end = DateTime(start.year, start.month + 1, 0, 23, 59, 59);
      final list = app.transactionsInRange(start, end);
      final exp = app.totalExpense(list);
      spots.add(FlSpot(i.toDouble(), exp));
    }
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (v, meta) => Text(Formatters.amount(v),
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 10)))),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= months.length) return SizedBox();
                return Text(
                    Formatters.monthYear.format(months[idx]).substring(0, 3),
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 10));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.accent,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
                show: true, color: AppColors.accent.withOpacity(0.15)),
          ),
        ],
      ),
    );
  }
}
