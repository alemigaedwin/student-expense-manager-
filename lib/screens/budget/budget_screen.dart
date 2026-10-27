import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../category/category_picker_screen.dart';

class BudgetScreen extends StatefulWidget {
  BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _periodStart = DateTime(DateTime.now().year, DateTime.now().month, 1);

  BudgetPeriod get _period => BudgetPeriod.values[_tabController.index];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime get _periodEnd {
    switch (_period) {
      case BudgetPeriod.monthly:
        return DateTime(_periodStart.year, _periodStart.month + 1, 0, 23, 59, 59);
      case BudgetPeriod.weekly:
        return _periodStart.add(Duration(days: 6, hours: 23, minutes: 59));
      case BudgetPeriod.yearly:
        return DateTime(_periodStart.year, 12, 31, 23, 59, 59);
    }
  }

  void _shiftPeriod(int dir) {
    setState(() {
      switch (_period) {
        case BudgetPeriod.monthly:
          _periodStart =
              DateTime(_periodStart.year, _periodStart.month + dir, 1);
          break;
        case BudgetPeriod.weekly:
          _periodStart = _periodStart.add(Duration(days: 7 * dir));
          break;
        case BudgetPeriod.yearly:
          _periodStart = DateTime(_periodStart.year + dir, 1, 1);
          break;
      }
    });
  }

  int _daysInPeriod() {
    switch (_period) {
      case BudgetPeriod.monthly:
        return DateTime(_periodStart.year, _periodStart.month + 1, 0).day;
      case BudgetPeriod.weekly:
        return 7;
      case BudgetPeriod.yearly:
        return DateTime(_periodStart.year, 12, 31).difference(DateTime(_periodStart.year, 1, 1)).inDays + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final budgets = app.budgetsFor(_period, _periodStart);
    final txns = app.transactionsInRange(_periodStart, _periodEnd);
    final expenseByCat = app.expenseByCategory(txns);
    final overall = app.overallBudgetFor(_period, _periodStart);
    final totalBudget = overall?.amount ??
        budgets.fold<double>(
          0.0,
              (double s, b) => s + (b.amount ?? 0.0),
        );
    final totalExpense = app.totalExpense(txns);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Budget'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _showReportSheet(context),
          ),
          IconButton(
            icon: Icon(Icons.description_outlined),
            onPressed: () => _showBudgetOptionsSheet(context, app),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [Tab(text: 'MONTHLY'), Tab(text: 'WEEKLY'), Tab(text: 'YEARLY')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () => _addCategoryBudget(context, app),
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          DateRangeRow(
            label:
                '${Formatters.dateOnly.format(_periodStart)} -> ${Formatters.dateOnly.format(_periodEnd)}',
            onPrev: () => _shiftPeriod(-1),
            onNext: () => _shiftPeriod(1),
          ),
          Expanded(
            child: budgets.isEmpty
                ? Center(
                    child: Text('No category budgets yet. Tap + to add one.',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: budgets.length,
                    itemBuilder: (context, i) {
                      final b = budgets[i];
                      final cat = app.categoryById(b.categoryId);
                      final spent = expenseByCat[cat?.name ?? ''] ?? 0;
                      final remaining = b.amount - spent;
                      final perDay = remaining / _daysInPeriod();
                      final progress =
                          b.amount == 0 ? 0.0 : (spent / b.amount).clamp(0, 1);
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  (cat?.color ?? AppColors.accent).withOpacity(0.2),
                              child: Icon(cat?.icon ?? Icons.category,
                                  color: cat?.color ?? AppColors.accent),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(cat?.name ?? '-',
                                          style: TextStyle(
                                              color: AppColors.textPrimary)),
                                      Text(Formatters.amount(b.amount),
                                          style: TextStyle(
                                              color: AppColors.accent)),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress.toDouble(),
                                      minHeight: 6,
                                      backgroundColor: AppColors.border,
                                      color: progress >= 1
                                          ? AppColors.expense
                                          : AppColors.accent,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Expense ${Formatters.amount(spent)}',
                                          style: TextStyle(
                                              color: AppColors.expense,
                                              fontSize: 12)),
                                      Text('Remaining ${Formatters.amount(remaining)}',
                                          style: TextStyle(
                                              color: AppColors.income,
                                              fontSize: 12)),
                                    ],
                                  ),
                                  Text('Per day ${Formatters.amount(perDay)}',
                                      style: TextStyle(
                                          color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              color: AppColors.surface,
                              icon: Icon(Icons.more_vert,
                                  color: AppColors.textMuted),
                              onSelected: (v) {
                                if (v == 'edit') {
                                  _editBudgetAmount(context, app, b);
                                } else if (v == 'remove') {
                                  app.removeBudget(b.id);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit',
                                        style: TextStyle(color: AppColors.textPrimary))),
                                PopupMenuItem(
                                    value: 'remove',
                                    child: Text('Remove',
                                        style: TextStyle(color: AppColors.textPrimary))),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(children: [
                    Text('Budget',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(Formatters.amount(totalBudget),
                        style: TextStyle(color: AppColors.textPrimary)),
                  ]),
                ),
                Expanded(
                  child: Column(children: [
                    Text('Expense',
                        style: TextStyle(color: AppColors.expense, fontSize: 12)),
                    Text(Formatters.amount(totalExpense),
                        style: TextStyle(color: AppColors.expense)),
                  ]),
                ),
                Expanded(
                  child: Column(children: [
                    Text('Remaining',
                        style: TextStyle(color: AppColors.income, fontSize: 12)),
                    Text(Formatters.amount(totalBudget - totalExpense),
                        style: TextStyle(color: AppColors.income)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategoryBudget(BuildContext context, AppState app) async {
    final cat = await Navigator.push<CategoryModel>(
        context,
        MaterialPageRoute(
            builder: (_) => CategoryPickerScreen(kind: CategoryKind.expense)));
    if (cat == null || !context.mounted) return;
    final amount = await _promptAmount(context, title: 'Budget for ${cat.name}');
    if (amount != null) {
      app.setBudget(
          categoryId: cat.id,
          amount: amount,
          period: _period,
          periodStart: _periodStart);
    }
  }

  Future<void> _editBudgetAmount(
      BuildContext context, AppState app, BudgetModel b) async {
    final cat = app.categoryById(b.categoryId);
    final amount =
        await _promptAmount(context, title: 'Budget for ${cat?.name ?? ''}', initial: b.amount);
    if (amount != null) {
      app.setBudget(
          categoryId: b.categoryId,
          amount: amount,
          period: _period,
          periodStart: _periodStart);
    }
  }

  Future<double?> _promptAmount(BuildContext context,
      {required String title, double? initial}) {
    final controller =
        TextEditingController(text: initial != null ? initial.toString() : '');
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: 'Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL')),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(controller.text.trim())),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBudgetOptionsSheet(BuildContext context, AppState app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Set Monthly Budget',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () async {
                Navigator.pop(ctx);
                final overall = app.overallBudgetFor(_period, _periodStart);
                final amount = await _promptAmount(context,
                    title: 'Set Monthly Budget', initial: overall?.amount ?? 0);
                if (amount != null) {
                  app.setOverallBudget(_period, _periodStart, amount);
                }
              },
            ),
            ListTile(
              title: Text('Import from last month',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: Text('Import from last month',
                        style: TextStyle(color: AppColors.textPrimary)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dctx),
                          child: Text('CANCEL')),
                      TextButton(
                        onPressed: () {
                          app.importBudgetsFromLastMonth(_period, _periodStart);
                          Navigator.pop(dctx);
                        },
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(12),
              child: Text('Report', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text('PDF', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                Share.share('Budget report (PDF export placeholder)');
              },
            ),
            ListTile(
              leading: Icon(Icons.grid_on, color: Colors.green),
              title: Text('Excel', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                Share.share('Budget report (Excel export placeholder)');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DateRangeRow extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  DateRangeRow(
      {super.key, required this.label, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                style: TextStyle(color: AppColors.textPrimary)),
          ),
          IconButton(
              icon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
              onPressed: onNext),
        ],
      ),
    );
  }
}
