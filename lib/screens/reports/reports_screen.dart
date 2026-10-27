import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../services/app_state.dart';
import '../../services/report_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/file_export.dart';
import '../../utils/formatters.dart';

class ReportsScreen extends StatefulWidget {
  ReportsScreen({super.key});
  @override State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _start;
  DateTime? _end;
  bool _includeAllAccounts = true;
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final start = _start ?? app.rangeStart;
    final end = _end ?? app.rangeEnd;
    final txns = _includeAllAccounts
        ? app.transactionsEveryAccountInRange(start, end)
        : app.transactionsInRange(start, end);
    final reportAccountName =
        _includeAllAccounts ? 'All Accounts' : app.currentAccount.name;
    final income = app.totalIncome(txns), expense = app.totalExpense(txns);
    final categories = {for (final c in app.allCategories) c.id: c.name};
    final accounts = {for (final account in app.accounts) account.id: account.name};
    return Scaffold(
      appBar: AppBar(title: Text('Reports')),
      body: ListView(padding: EdgeInsets.all(18), children: [
        Text('Export your student spending in a format you can submit, print or keep for records.', style: TextStyle(color: AppColors.textSecondary)),
        SizedBox(height: 12),
        Card(child: Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Report period', style: TextStyle(fontWeight: FontWeight.w700)),
         CheckboxListTile(
           contentPadding: EdgeInsets.zero,
           title: Text('Include transactions from all accounts'),
           value: _includeAllAccounts,
           onChanged: (value) =>
               setState(() => _includeAllAccounts = value ?? false),
         ),
          SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: () async { final d=await showDatePicker(context: context, initialDate: start, firstDate: DateTime(2000), lastDate: DateTime(2100)); if(d!=null)setState(()=>_start=DateTime(d.year,d.month,d.day)); }, icon: Icon(Icons.calendar_today), label: Text('From: ${Formatters.dateOnly.format(start)}')),
            OutlinedButton.icon(onPressed: () async { final d=await showDatePicker(context: context, initialDate: end, firstDate: DateTime(2000), lastDate: DateTime(2100)); if(d!=null)setState(()=>_end=DateTime(d.year,d.month,d.day,23,59,59)); }, icon: Icon(Icons.event), label: Text('To: ${Formatters.dateOnly.format(end)}')),
            OutlinedButton(onPressed: () { final now=DateTime.now(); setState(() { _start=DateTime(now.year,now.month,1); _end=DateTime(now.year,now.month+1,0,23,59,59); }); }, child: Text('This month')),
            OutlinedButton.icon(
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: start,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  helpText: 'Choose any date in the month',
                );
                if (selected != null) {
                  setState(() {
                    _start = DateTime(selected.year, selected.month, 1);
                    _end = DateTime(
                      selected.year,
                      selected.month + 1,
                      0,
                      23,
                      59,
                      59,
                    );
                  });
                }
              },
              icon: Icon(Icons.calendar_month),
              label: Text('Choose month'),
            ),
            TextButton(onPressed: () => setState(() { _start=null; _end=null; }), child: Text('Use app range')),
          ]),
          if(start.isAfter(end)) Padding(padding: EdgeInsets.only(top: 6), child: Text('Start date must be before end date.', style: TextStyle(color: AppColors.expense))),
        ]))),
        SizedBox(height: 12),
        Card(child: Padding(padding: EdgeInsets.all(18), child: Row(children: [
          Expanded(child: _stat('Income', income, AppColors.income)),
          Expanded(child: _stat('Expense', expense, AppColors.expense)),
          Expanded(child: _stat('Balance', income-expense, AppColors.accent)),
        ]))),
        SizedBox(height: 14),
        ListTile(leading: Icon(Icons.picture_as_pdf, color: AppColors.expense), title: Text('PDF report'), subtitle: Text('Preview, print or save a professional PDF report'), trailing: Icon(Icons.chevron_right), onTap: () async {
          if (start.isAfter(end)) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Choose a valid date range.'))); return; }
          await Navigator.push(context, MaterialPageRoute(builder: (_) => _PdfPreviewPage(txns: txns, accountName: reportAccountName, categories: categories)));
        }),
        ListTile(leading: Icon(Icons.table_chart, color: AppColors.income), title: Text('Excel report'), subtitle: Text('Download a .xlsx spreadsheet of the transactions'), trailing: Icon(Icons.download), onTap: () async {
          if (start.isAfter(end)) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Choose a valid date range.'))); return; }
          final bytes = ReportService.excel(
              txns, reportAccountName, categories, accounts, app.receiptLabels);
          final filename =
              'student_expense_report_${start.year}${start.month.toString().padLeft(2, '0')}${start.day.toString().padLeft(2, '0')}-${end.year}${end.month.toString().padLeft(2, '0')}${end.day.toString().padLeft(2, '0')}.xlsx';
          await exportFile(bytes, filename, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel report exported with ${txns.length} transactions.')));
        }),
        SizedBox(height: 12),
        Text('Selected range: ${Formatters.dateOnly.format(start)} – ${Formatters.dateOnly.format(end)}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]),
    );
  }
  Widget _stat(String label,double value,Color color)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:TextStyle(color:AppColors.textSecondary,fontSize:12)),SizedBox(height:4),Text(Formatters.amount(value),style:TextStyle(color:color,fontWeight:FontWeight.w800))]);
}

class _PdfPreviewPage extends StatelessWidget {
  final dynamic txns; final String accountName; final Map<String, String> categories;
  _PdfPreviewPage({required this.txns, required this.accountName, required this.categories});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('PDF Report')),body:PdfPreview(build:(format)=>ReportService.pdf(txns, accountName, categories)));
}
