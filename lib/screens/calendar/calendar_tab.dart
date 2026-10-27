import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_tile.dart';
import '../transactions/add_transaction_screen.dart';

class CalendarTab extends StatefulWidget {
  CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final monthEnd = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final monthTxns = app.transactionsInRange(_visibleMonth, monthEnd);
    final totalIncome = app.totalIncome(monthTxns);
    final totalExpense = app.totalExpense(monthTxns);

    // Map day -> net expense total (for the red figure shown in each cell)
    final Map<int, double> dayExpense = {};
    for (final t in monthTxns.where((t) => t.type == TransactionType.expense)) {
      dayExpense[t.date.day] = (dayExpense[t.date.day] ?? 0) + t.amount;
    }

    final firstWeekday = _visibleMonth.weekday % 7; // Sun=0
    final daysInMonth = monthEnd.day;
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    List<TransactionModel> selectedDayTxns = [];
    if (_selectedDay != null) {
      selectedDayTxns = monthTxns
          .where((t) =>
              t.date.year == _selectedDay!.year &&
              t.date.month == _selectedDay!.month &&
              t.date.day == _selectedDay!.day)
          .toList();
    }

    return Stack(
      children: [
        Column(
          children: [
            DateRangeBar(
          label: Formatters.monthYear.format(_visibleMonth),
          onPrev: () => setState(() {
            _visibleMonth =
                DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
            _selectedDay = null;
          }),
          onNext: () => setState(() {
            _visibleMonth =
                DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
            _selectedDay = null;
          }),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ),
                    ))
                .toList(),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: MediaQuery.of(context).size.width >= 900 ? 2.6 : (MediaQuery.of(context).size.width >= 600 ? 1.6 : 1.05),
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
            ),
            itemCount: rows * 7,
            itemBuilder: (context, i) {
              final dayNum = i - firstWeekday + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return SizedBox();
              }
              final day = DateTime(_visibleMonth.year, _visibleMonth.month, dayNum);
              final isSelected = _selectedDay != null &&
                  _selectedDay!.day == dayNum &&
                  _selectedDay!.month == _visibleMonth.month;
              final expenseVal = dayExpense[dayNum];
              return InkWell(
                onTap: () => setState(() => _selectedDay = day),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent.withOpacity(0.25) : AppColors.surface,
                    border: Border.all(color: AppColors.border, width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: EdgeInsets.all(3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$dayNum',
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 12)),
                      if (expenseVal != null)
                        Text(Formatters.amount(expenseVal),
                            style: TextStyle(
                                color: AppColors.expense, fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectedDay != null) ...[
          Divider(color: AppColors.border, height: 1),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: AppColors.income,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddTransactionScreen(
                                  type: TransactionType.income,
                                  initialDate: _selectedDay))),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                            child: Text('Income',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600))),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: AppColors.expense,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddTransactionScreen(
                                  type: TransactionType.expense,
                                  initialDate: _selectedDay))),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                            child: Text('Expense',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600))),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Formatters.dayDateMonthYear.format(_selectedDay!),
                    style: TextStyle(color: AppColors.textPrimary)),
                Row(
                  children: [
                    Text(Formatters.amount(app.totalIncome(selectedDayTxns)),
                        style: TextStyle(color: AppColors.income)),
                    SizedBox(width: 12),
                    Text(Formatters.amount(app.totalExpense(selectedDayTxns)),
                        style: TextStyle(color: AppColors.expense)),
                  ],
                ),
              ],
            ),
          ),
          if (selectedDayTxns.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 2),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text('Category',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Text('Income',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: AppColors.income,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Expense',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: AppColors.expense,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: selectedDayTxns.isEmpty
                ? Center(
                    child: Text('No transactions this day',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    itemCount: selectedDayTxns.length,
                    itemBuilder: (context, i) => TransactionTile(
                      t: selectedDayTxns[i],
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddTransactionScreen(
                                  type: selectedDayTxns[i].type,
                                  existing: selectedDayTxns[i]))),
                    ),
                  ),
          ),
        ] else
          Expanded(child: SizedBox()),
        Container(
          color: AppColors.surface,
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(children: [
                  Text('Total Income',
                      style: TextStyle(color: AppColors.income, fontSize: 12)),
                  Text(Formatters.amount(totalIncome),
                      style: TextStyle(color: AppColors.income)),
                ]),
              ),
              Expanded(
                child: Column(children: [
                  Text('Total Expense',
                      style: TextStyle(color: AppColors.expense, fontSize: 12)),
                  Text(Formatters.amount(totalExpense),
                      style: TextStyle(color: AppColors.expense)),
                ]),
              ),
              Expanded(
                child: Column(children: [
                  Text('Balance',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                  Text(Formatters.amount(totalIncome - totalExpense),
                      style: TextStyle(color: AppColors.textPrimary)),
                ]),
              ),
            ],
          ),
        ),
      ],
        ),
      ],
    );
  }
}
