import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/transaction_model.dart';
import '../utils/formatters.dart';

class ReportService {
  static Future<Uint8List> pdf(List<TransactionModel> txns, String accountName, [Map<String, String> categories = const {}]) async {
    final doc = pw.Document();
    final income = txns.where((t) => t.type == TransactionType.income).fold<double>(0, (s,t)=>s+t.amount);
    final expense = txns.where((t) => t.type == TransactionType.expense).fold<double>(0, (s,t)=>s+t.amount);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => [
        pw.Text('Student Expense Manager', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('Transaction report • $accountName'),
        pw.Text('Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9)),
        pw.Text('Reporting period: ${txns.isEmpty ? 'No transactions' : DateFormat('dd MMM yyyy').format(txns.map((t) => t.date).reduce((a,b) => a.isBefore(b) ? a : b))} – ${txns.isEmpty ? 'No transactions' : DateFormat('dd MMM yyyy').format(txns.map((t) => t.date).reduce((a,b) => a.isAfter(b) ? a : b))}', style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 18),
        pw.Row(children: [
          pw.Expanded(child: pw.Container(padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(border: pw.Border.all()), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children:[pw.Text('Income'), pw.Text(Formatters.amount(income), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]))),
          pw.SizedBox(width: 10),
          pw.Expanded(child: pw.Container(padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(border: pw.Border.all()), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children:[pw.Text('Expense'), pw.Text(Formatters.amount(expense), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]))),
          pw.SizedBox(width: 10),
          pw.Expanded(child: pw.Container(padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(border: pw.Border.all()), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children:[pw.Text('Balance'), pw.Text(Formatters.amount(income-expense), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]))),
        ]),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: ['Date','Type','Category','Amount','Notes'],
          data: txns.map((t)=>[
            DateFormat('dd/MM/yyyy').format(t.date),
            t.type.name.toUpperCase(),
            (t.categoryId == null ? 'Transfer' : (categories[t.categoryId] ?? 'Other')),
            Formatters.amount(t.amount),
            t.notes,
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellPadding: const pw.EdgeInsets.all(5),
        ),
      ],
    ));
    return doc.save();
  }

  static Uint8List excel(
    List<TransactionModel> txns,
    String accountName, [
    Map<String, String> categories = const {},
    Map<String, String> accounts = const {},
    Map<String, String> receiptNames = const {},
  ]) {
    final book = Excel.createExcel();
    final sheet = book['Transactions'];
    sheet.appendRow([TextCellValue('Student Expense Manager')]);
    sheet.appendRow([TextCellValue('Account'), TextCellValue(accountName)]);
    sheet.appendRow([TextCellValue('Generated'), TextCellValue(DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()))]);
    sheet.appendRow([TextCellValue('Reporting period'), TextCellValue(txns.isEmpty ? 'No transactions' : '${DateFormat('dd MMM yyyy').format(txns.map((t) => t.date).reduce((a,b) => a.isBefore(b) ? a : b))} - ${DateFormat('dd MMM yyyy').format(txns.map((t) => t.date).reduce((a,b) => a.isAfter(b) ? a : b))}')]);
    final income = txns.where((t) => t.type == TransactionType.income).fold<double>(0, (s,t)=>s+t.amount);
    final expense = txns.where((t) => t.type == TransactionType.expense).fold<double>(0, (s,t)=>s+t.amount);
    sheet.appendRow([TextCellValue('Income total'), DoubleCellValue(income)]);
    sheet.appendRow([TextCellValue('Expense total'), DoubleCellValue(expense)]);
    sheet.appendRow([TextCellValue('Net balance'), DoubleCellValue(income-expense)]);
    sheet.appendRow([TextCellValue('Date'), TextCellValue('Transaction ID'), TextCellValue('Account'), TextCellValue('Type'), TextCellValue('Category'), TextCellValue('Amount'), TextCellValue('Notes'), TextCellValue('Items'), TextCellValue('Receipt attachments')]);
    for (final t in txns) {
      final itemText = t.items.map((i) => '${i.name} x${i.quantity} ${i.unit} @ ${i.rate}').join('; ');
      sheet.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(t.date)),
        TextCellValue(t.id),
        TextCellValue(accounts[t.accountId] ?? t.accountId),
        TextCellValue(t.type.name.toUpperCase()),
        TextCellValue(t.categoryId == null ? 'Transfer' : (categories[t.categoryId] ?? 'Other')),
        DoubleCellValue(t.amount),
        TextCellValue(t.notes),
        TextCellValue(itemText),
        TextCellValue(t.billPaths.map((p) => receiptNames[p] ?? 'Receipt (file not available)').join('; ')),
      ]);
    }
    return Uint8List.fromList(book.encode() ?? <int>[]);
  }
}
