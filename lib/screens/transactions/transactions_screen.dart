import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/transaction_model.dart';
import '../../services/app_state.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import '../reports/reports_screen.dart';
import 'package:printing/printing.dart';
import '../../services/report_service.dart';
import '../settings/settings_screen.dart';

enum _SortOption {
  category,
  subcategory,
  paymentMethod,
  transfer,
  income,
  expense,
  dateAsc,
  dateDesc,
  categoryAsc,
  amountAsc,
  amountDesc,
}

class TransactionsScreen extends StatefulWidget {
  final bool allAccounts;
  TransactionsScreen({super.key, this.allAccounts = false});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _rangeFilter = 'All';
  _SortOption? _sort;
  TransactionType? _typeFilter;
  String? _categoryFilterId;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _notesOnly = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    List<TransactionModel> list = widget.allAccounts
        ? app.transactionsEveryAccount
        : app.transactionsAllTime;

    // date range chip filter
    final now = DateTime.now();
    if (_rangeFilter == 'Daily') {
      list = list
          .where((t) =>
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day)
          .toList();
    } else if (_rangeFilter == 'Weekly') {
      final weekAgo = now.subtract(Duration(days: 7));
      list = list.where((t) => t.date.isAfter(weekAgo)).toList();
    } else if (_rangeFilter == 'Monthly') {
      list = list
          .where((t) => t.date.year == now.year && t.date.month == now.month)
          .toList();
    } else if (_rangeFilter == 'Yearly') {
      list = list.where((t) => t.date.year == now.year).toList();
    } else if (_rangeFilter == 'Custom' &&
        _customStart != null &&
        _customEnd != null) {
      final endExclusive = DateTime(
        _customEnd!.year,
        _customEnd!.month,
        _customEnd!.day + 1,
      );
      list = list
          .where((t) =>
              !t.date.isBefore(_customStart!) &&
              t.date.isBefore(endExclusive))
          .toList();
    }

    if (_categoryFilterId != null) {
      list = list.where((t) => t.categoryId == _categoryFilterId).toList();
    }
    if (_notesOnly) {
      list = list.where((t) => t.notes.trim().isNotEmpty).toList();
    }
    if (_typeFilter != null) {
      list = list.where((t) => t.type == _typeFilter).toList();
    }

    switch (_sort) {
      case _SortOption.dateAsc:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case _SortOption.dateDesc:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _SortOption.amountAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case _SortOption.amountDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case _SortOption.categoryAsc:
      case _SortOption.category:
        list.sort((a, b) => (app.categoryById(a.categoryId)?.name ?? '')
            .compareTo(app.categoryById(b.categoryId)?.name ?? ''));
        break;
      case _SortOption.paymentMethod:
        list.sort((a, b) => (app.paymentMethodById(a.paymentMethodId)?.name ?? '')
            .compareTo(app.paymentMethodById(b.paymentMethodId)?.name ?? ''));
        break;
      case _SortOption.subcategory:
        list.sort((a, b) {
          final aCategory = app.categoryById(a.categoryId);
          final bCategory = app.categoryById(b.categoryId);
          final aParent = app.categoryById(aCategory?.parentId)?.name ?? '';
          final bParent = app.categoryById(bCategory?.parentId)?.name ?? '';
          final parentOrder = aParent.compareTo(bParent);
          if (parentOrder != 0) return parentOrder;
          return (aCategory?.name ?? '').compareTo(bCategory?.name ?? '');
        });
        break;
      case _SortOption.transfer:
        list = list.where((t) => t.type == TransactionType.transfer).toList();
        break;
      case _SortOption.income:
        list = list.where((t) => t.type == TransactionType.income).toList();
        break;
      case _SortOption.expense:
        list = list.where((t) => t.type == TransactionType.expense).toList();
        break;
      case null:
        break;
    }

    final totalIncome = app.totalIncome(list);
    final totalExpense = app.totalExpense(list);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(widget.allAccounts ? 'Transaction - All Accounts' : 'Transactions'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => showSearch(
                context: context, delegate: _TxnSearchDelegate(list, app)),
          ),
          PopupMenuButton<_SortOption>(
            icon: Icon(Icons.menu),
            color: AppColors.surface,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (context) => [
              PopupMenuItem(value: _SortOption.category, child: Text('Category', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: _SortOption.subcategory, child: Text('Subcategory', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: _SortOption.paymentMethod, child: Text('Payment Method', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: _SortOption.transfer, child: Text('Transfer', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: _SortOption.income, child: Text('Income', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: _SortOption.expense, child: Text('Expense', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: _SortOption.dateAsc, child: Text('Date Ascending', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: _SortOption.dateDesc, child: Text('Date Descending', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: _SortOption.categoryAsc, child: Text('Category Ascending', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: _SortOption.amountAsc, child: Text('Amount Ascending', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: _SortOption.amountDesc, child: Text('Amount Descending', style: TextStyle(color: AppColors.textPrimary))),
            ],
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            color: AppColors.surface,
            onSelected: (v) => _handleMenu(context, v, list),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'date', child: Text('Date', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: 'range', child: Text('Select Date Range', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: 'notes', child: Text('Notes', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: 'amount', child: Text('Amount', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: 'share', child: Text('Share', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: 'print', child: Text('Print', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: 'report', child: Text('Report', style: TextStyle(color: AppColors.textPrimary))),
              PopupMenuItem(value: 'profile', child: Text('Your Name and Address', style: TextStyle(color: AppColors.textPrimary))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
            Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['All', 'Daily', 'Weekly', 'Monthly', 'Yearly', if (_rangeFilter == 'Custom') 'Custom']
                    .map((f) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: _rangeFilter == f,
                            selectedColor: AppColors.accent,
                            backgroundColor: AppColors.surfaceLight,
                            labelStyle: TextStyle(
                                color: _rangeFilter == f
                                    ? Colors.white
                                    : AppColors.textSecondary),
                            onSelected: (_) => setState(() => _rangeFilter = f),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TransactionType?>(
                    value: _typeFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem<TransactionType?>(
                          value: null, child: Text('All types')),
                      DropdownMenuItem<TransactionType?>(
                          value: TransactionType.income,
                          child: Text('Income')),
                      DropdownMenuItem<TransactionType?>(
                          value: TransactionType.expense,
                          child: Text('Expense')),
                      DropdownMenuItem<TransactionType?>(
                          value: TransactionType.transfer,
                          child: Text('Transfer')),
                    ],
                    onChanged: (value) =>
                        setState(() => _typeFilter = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _categoryFilterId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('All categories')),
                      ...app.allCategories.map((category) =>
                          DropdownMenuItem<String?>(
                            value: category.id,
                            child: Text(category.name,
                                overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (value) =>
                        setState(() => _categoryFilterId = value),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text('No transactions',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: 12),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final t = list[i];
                      return TransactionTile(
                        t: t,
                        onTap: t.type == TransactionType.transfer
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => AddTransactionScreen(
                                        type: t.type, existing: t))),
                        onDelete: () => _confirmDelete(context, t),
                      );
                    },
                  ),
          ),
          Row(children: [
            Expanded(child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionScreen(type: TransactionType.income))),
              child: Container(color: AppColors.income, padding: EdgeInsets.symmetric(vertical: 14), child: Center(child: Text('Income', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
            )),
            Expanded(child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionScreen(type: TransactionType.expense))),
              child: Container(color: AppColors.expense, padding: EdgeInsets.symmetric(vertical: 14), child: Center(child: Text('Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
            )),
          ]),
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
    );
  }

  void _confirmDelete(BuildContext context, TransactionModel t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete transaction?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('It will be moved to Deleted Transactions.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final saved =
                  await context.read<AppState>().softDeleteTransaction(t.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(saved
                      ? 'Transaction moved to Deleted Transactions.'
                      : 'Could not delete the transaction on the server.'),
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  void _handleMenu(BuildContext context, String value, List<TransactionModel> list) {
    switch (value) {
      case 'date':
        setState(() => _sort = _SortOption.dateDesc);
        break;
      case 'range':
        _selectDateRange();
        break;
      case 'notes':
        setState(() => _notesOnly = !_notesOnly);
        break;
      case 'amount':
        setState(() => _sort = _sort == _SortOption.amountDesc
            ? _SortOption.amountAsc
            : _SortOption.amountDesc);
        break;
      case 'share':
        final buffer = StringBuffer('Student Expense Manager Report\n\n');
        for (final t in list) {
          buffer.writeln('${Formatters.dateOnly.format(t.date)} | ${t.type.name} | ${Formatters.amount(t.amount)}');
        }
        Share.share(buffer.toString());
        break;
      case 'report':
        Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen()));
        break;
      case 'print':
        final app = context.read<AppState>();
        final categories = {for (final c in app.allCategories) c.id: c.name};
        Printing.layoutPdf(
          onLayout: (_) => ReportService.pdf(list, app.currentAccount.name, categories),
        );
        break;
      case 'profile':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => SettingsScreen()));
        break;
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final initial = _customStart != null && _customEnd != null
        ? DateTimeRange(start: _customStart!, end: _customEnd!)
        : DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day),
          );
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initial,
      helpText: 'Filter transactions by date',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _rangeFilter = 'Custom';
      _customStart = DateTime(
        selected.start.year,
        selected.start.month,
        selected.start.day,
      );
      _customEnd = DateTime(
        selected.end.year,
        selected.end.month,
        selected.end.day,
      );
    });
  }
}

class _TxnSearchDelegate extends SearchDelegate {
  final List<TransactionModel> source;
  final AppState app;
  _TxnSearchDelegate(this.source, this.app);

  @override
  List<Widget>? buildActions(BuildContext context) =>
      [IconButton(icon: Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = source.where((t) {
      final cat = app.categoryById(t.categoryId)?.name ?? '';
      return cat.toLowerCase().contains(query.toLowerCase()) ||
          t.notes.toLowerCase().contains(query.toLowerCase());
    }).toList();
    return ListView(children: results.map((t) => TransactionTile(t: t)).toList());
  }
}
