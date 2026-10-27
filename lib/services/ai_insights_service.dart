import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import 'app_state.dart';

enum InsightLevel { good, tip, warning }

class Insight {
  final IconData icon;
  final InsightLevel level;
  final String title;
  final String message;
  const Insight({
    required this.icon,
    required this.level,
    required this.title,
    required this.message,
  });

  Color get color {
    switch (level) {
      case InsightLevel.good:
        return AppColors.income;
      case InsightLevel.warning:
        return AppColors.expense;
      case InsightLevel.tip:
        return AppColors.accent;
    }
  }
}

/// A small on-device "AI money coach". It never leaves the device or calls
/// the network - every insight and answer is computed straight from the
/// student's own transactions, budgets and categories, so it works fully
/// offline and privately.
class AiInsightsService {
  AiInsightsService(this.app);
  final AppState app;

  DateTime get _now => DateTime.now();
  DateTime get _monthStart => DateTime(_now.year, _now.month, 1);
  DateTime get _monthEnd => DateTime(_now.year, _now.month + 1, 0, 23, 59, 59);
  DateTime get _prevMonthStart => DateTime(_now.year, _now.month - 1, 1);
  DateTime get _prevMonthEnd => DateTime(_now.year, _now.month, 0, 23, 59, 59);

  List<Insight> generate() {
    final insights = <Insight>[];
    final thisMonth = app.transactionsInRange(_monthStart, _monthEnd);
    final lastMonth = app.transactionsInRange(_prevMonthStart, _prevMonthEnd);

    final income = app.totalIncome(thisMonth);
    final expense = app.totalExpense(thisMonth);
    final lastExpense = app.totalExpense(lastMonth);

    if (thisMonth.isEmpty && lastMonth.isEmpty) {
      insights.add(Insight(
        icon: Icons.emoji_objects_outlined,
        level: InsightLevel.tip,
        title: 'Welcome!',
        message:
            'Log a few days of income and expenses and your AI money coach '
            'will start spotting trends, budget risks and saving tips here.',
      ));
      return insights;
    }

    // Spending trend vs last month.
    if (lastExpense > 0) {
      final change = ((expense - lastExpense) / lastExpense) * 100;
      if (change >= 15) {
        insights.add(Insight(
          icon: Icons.trending_up,
          level: InsightLevel.warning,
          title: 'Spending is up this month',
          message:
              "You've spent ${change.toStringAsFixed(0)}% more than last month "
              '(${Formatters.amount(expense)} vs ${Formatters.amount(lastExpense)}). '
              'Check your top categories below and see what crept up.',
        ));
      } else if (change <= -15) {
        insights.add(Insight(
          icon: Icons.trending_down,
          level: InsightLevel.good,
          title: 'Nice, you cut back',
          message:
              "Spending is down ${change.abs().toStringAsFixed(0)}% versus last "
              'month. Keep it up!',
        ));
      }
    }

    // Savings rate.
    if (income > 0) {
      final savingsRate = ((income - expense) / income) * 100;
      if (savingsRate < 0) {
        insights.add(Insight(
          icon: Icons.warning_amber_rounded,
          level: InsightLevel.warning,
          title: "You're spending more than you earn",
          message:
              'This month you spent ${Formatters.amount(expense - income)} more '
              'than your income. Consider trimming non-essential categories '
              'before the month ends.',
        ));
      } else if (savingsRate >= 20) {
        insights.add(Insight(
          icon: Icons.savings_outlined,
          level: InsightLevel.good,
          title: 'Great savings rate',
          message:
              "You've saved about ${savingsRate.toStringAsFixed(0)}% of your "
              'income this month (${Formatters.amount(income - expense)}). '
              'That\'s a healthy student budget habit.',
        ));
      } else {
        insights.add(Insight(
          icon: Icons.pie_chart_outline,
          level: InsightLevel.tip,
          title: 'Savings check-in',
          message:
              "You've saved about ${savingsRate.toStringAsFixed(0)}% of your "
              'income so far this month. Try the 50/30/20 rule: 50% needs, '
              '30% wants, 20% savings.',
        ));
      }
    }

    // Top spending category.
    final byCategory = app.expenseByCategory(thisMonth);
    if (byCategory.isNotEmpty) {
      final sorted = byCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      final share = expense > 0 ? (top.value / expense) * 100 : 0;
      insights.add(Insight(
        icon: Icons.local_fire_department_outlined,
        level: InsightLevel.tip,
        title: 'Top spending: ${top.key}',
        message:
            '${top.key} makes up ${share.toStringAsFixed(0)}% of your spending '
            'this month (${Formatters.amount(top.value)}). Worth a look if it '
            "wasn't planned.",
      ));
    }

    // Budget alerts (per-category, monthly).
    final budgets = app.budgetsFor(BudgetPeriod.monthly, _monthStart);
    for (final b in budgets) {
      final catName = app.categoryById(b.categoryId)?.name ?? 'Category';
      final spent = byCategory[catName] ?? 0;
      if (b.amount <= 0) continue;
      final pct = (spent / b.amount) * 100;
      if (pct >= 100) {
        insights.add(Insight(
          icon: Icons.error_outline,
          level: InsightLevel.warning,
          title: '$catName budget exceeded',
          message:
              "You've spent ${Formatters.amount(spent)} of your "
              '${Formatters.amount(b.amount)} $catName budget '
              '(${pct.toStringAsFixed(0)}%).',
        ));
      } else if (pct >= 80) {
        insights.add(Insight(
          icon: Icons.hourglass_bottom,
          level: InsightLevel.warning,
          title: '$catName budget almost used up',
          message:
              "You've used ${pct.toStringAsFixed(0)}% of your $catName budget "
              'for this month (${Formatters.amount(spent)} of '
              '${Formatters.amount(b.amount)}).',
        ));
      }
    }

    // Overall budget.
    final overall = app.overallBudgetFor(BudgetPeriod.monthly, _monthStart);
    if (overall != null && overall.amount > 0) {
      final pct = (expense / overall.amount) * 100;
      final daysLeft = _monthEnd.difference(_now).inDays + 1;
      if (pct >= 100) {
        insights.add(Insight(
          icon: Icons.report_gmailerrorred,
          level: InsightLevel.warning,
          title: 'Monthly budget exceeded',
          message:
              "You've gone over your overall monthly budget of "
              '${Formatters.amount(overall.amount)} with $daysLeft day(s) left '
              'in the month.',
        ));
      } else {
        final remaining = overall.amount - expense;
        insights.add(Insight(
          icon: Icons.account_balance_wallet_outlined,
          level: InsightLevel.tip,
          title: 'Budget remaining',
          message:
              'You have ${Formatters.amount(remaining)} left of your monthly '
              'budget with $daysLeft day(s) to go '
              '(about ${(remaining / (daysLeft == 0 ? 1 : daysLeft)).abs().toStringAsFixed(0)}/day if you want to pace it out).',
        ));
      }
    }

    // No-spend / consistency nudge.
    final daysWithExpense = thisMonth
        .where((t) => t.type == TransactionType.expense)
        .map((t) => t.date.day)
        .toSet()
        .length;
    if (daysWithExpense >= 5) {
      final avgPerActiveDay = expense / daysWithExpense;
      insights.add(Insight(
        icon: Icons.calendar_month_outlined,
        level: InsightLevel.tip,
        title: 'Daily average',
        message:
            "On days you spend, you're averaging "
            '${Formatters.amount(avgPerActiveDay)}/day across $daysWithExpense '
            'day(s) this month.',
      ));
    }

    if (insights.isEmpty) {
      insights.add(Insight(
        icon: Icons.check_circle_outline,
        level: InsightLevel.good,
        title: "You're on track",
        message:
            'Nothing unusual to flag right now. Keep logging your income and '
            'expenses to get sharper insights.',
      ));
    }

    return insights;
  }

  /// Simple rule-based Q&A over the user's own data - no network required.
  String answer(String rawQuestion) {
    final q = rawQuestion.toLowerCase().trim();
    if (q.isEmpty) return "Ask me something like \"how much did I spend this month?\"";

    final all = app.transactionsAllTime;
    DateTime start = _monthStart;
    DateTime end = _monthEnd;
    String periodLabel = 'this month';

    if (q.contains('today')) {
      start = DateTime(_now.year, _now.month, _now.day);
      end = DateTime(_now.year, _now.month, _now.day, 23, 59, 59);
      periodLabel = 'today';
    } else if (q.contains('this week') || q.contains('week')) {
      final weekday = _now.weekday % 7;
      start = DateTime(_now.year, _now.month, _now.day)
          .subtract(Duration(days: weekday));
      end = start.add(Duration(days: 6, hours: 23, minutes: 59));
      periodLabel = 'this week';
    } else if (q.contains('last month')) {
      start = _prevMonthStart;
      end = _prevMonthEnd;
      periodLabel = 'last month';
    } else if (q.contains('year')) {
      start = DateTime(_now.year, 1, 1);
      end = DateTime(_now.year, 12, 31, 23, 59, 59);
      periodLabel = 'this year';
    }

    final range = app.transactionsInRange(start, end);

    // Category-specific spend, e.g. "how much on food this month".
    final categoryMatch = _matchCategory(q);
    if (categoryMatch != null) {
      final spent = range
          .where((t) =>
              t.type == TransactionType.expense &&
              t.categoryId == categoryMatch.id)
          .fold(0.0, (s, t) => s + t.amount);
      return "You've spent ${Formatters.amount(spent)} on ${categoryMatch.name} "
          '$periodLabel.';
    }

    if (q.contains('top') || q.contains('most') || q.contains('biggest')) {
      final byCategory = app.expenseByCategory(range);
      if (byCategory.isEmpty) {
        return "No expenses recorded $periodLabel yet.";
      }
      final sorted = byCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      return 'Your biggest expense category $periodLabel is ${top.key} at '
          '${Formatters.amount(top.value)}.';
    }

    if (q.contains('save') || q.contains('saving')) {
      final income = app.totalIncome(range);
      final expense = app.totalExpense(range);
      final saved = income - expense;
      if (income <= 0) {
        return 'No income recorded $periodLabel, so I can\'t work out a savings '
            'rate yet.';
      }
      final rate = (saved / income) * 100;
      return "You've saved ${Formatters.amount(saved)} (${rate.toStringAsFixed(0)}% "
          'of income) $periodLabel.';
    }

    if (q.contains('income') && !q.contains('expense')) {
      final income = app.totalIncome(range);
      return 'Your income $periodLabel is ${Formatters.amount(income)}.';
    }

    if (q.contains('balance')) {
      final income = app.totalIncome(all);
      final expense = app.totalExpense(all);
      return 'Your overall balance across all recorded transactions is '
          '${Formatters.amount(income - expense)}.';
    }

    if (q.contains('budget')) {
      final overall = app.overallBudgetFor(BudgetPeriod.monthly, _monthStart);
      final expense = app.totalExpense(app.transactionsInRange(_monthStart, _monthEnd));
      if (overall == null) {
        return "You haven't set an overall monthly budget yet. You can add one "
            'from the drawer under Budget.';
      }
      final remaining = overall.amount - expense;
      return remaining >= 0
          ? 'You have ${Formatters.amount(remaining)} left of your '
              '${Formatters.amount(overall.amount)} monthly budget.'
          : "You've gone ${Formatters.amount(remaining.abs())} over your "
              '${Formatters.amount(overall.amount)} monthly budget.';
    }

    // Default: spend / expense summary for the detected period.
    final income = app.totalIncome(range);
    final expense = app.totalExpense(range);
    if (q.contains('spend') || q.contains('spent') || q.contains('expense')) {
      return 'You spent ${Formatters.amount(expense)} $periodLabel across '
          '${range.where((t) => t.type == TransactionType.expense).length} '
          'transaction(s).';
    }

    return 'Income $periodLabel: ${Formatters.amount(income)}. '
        'Expense $periodLabel: ${Formatters.amount(expense)}. '
        'Net: ${Formatters.amount(income - expense)}.\n'
        'Try asking about a category, "top expense", "savings", or "budget".';
  }

  CategoryModel? _matchCategory(String q) {
    final all = [
      ...app.categoriesFor(CategoryKind.income),
      ...app.categoriesFor(CategoryKind.expense),
    ];
    for (final c in all) {
      if (q.contains(c.name.toLowerCase())) return c;
    }
    return null;
  }
}
