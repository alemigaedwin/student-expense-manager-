import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/transaction_model.dart';
import '../utils/formatters.dart';

class ReportService {
  static Future<Uint8List> pdf(
    List<TransactionModel> txns,
    String accountName, [
    Map<String, String> categories = const {},
    Map<String, String> userProfile = const {},
  ]) async {
    final doc = pw.Document();
    final income = txns
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = txns
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount);

    final name = userProfile['name'] ?? 'Student';
    final email = userProfile['email'] ?? '';
    final phone = userProfile['phone'] ?? '';
    final school = userProfile['school'] ?? '';
    final course = userProfile['course'] ?? '';

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Student Expense Manager',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text('Transaction & Financial Statement',
                    style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Generated:',
                    style: const pw.TextStyle(fontSize: 8)),
                pw.Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 1, height: 16),

        // Student Profile / Details Header
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('STUDENT PROFILE / DETAILS',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900)),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Name: $name',
                      style: const pw.TextStyle(fontSize: 9)),
                  if (email.isNotEmpty)
                    pw.Text('Email: $email',
                        style: const pw.TextStyle(fontSize: 9)),
                  if (phone.isNotEmpty)
                    pw.Text('Phone: $phone',
                        style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              if (school.isNotEmpty || course.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (school.isNotEmpty)
                      pw.Text('Institution: $school',
                          style: const pw.TextStyle(fontSize: 9)),
                    if (course.isNotEmpty)
                      pw.Text('Course: $course',
                          style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
              pw.SizedBox(height: 2),
              pw.Text('Account Book: $accountName',
                  style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
        pw.SizedBox(height: 14),

        // Financial Summary Row
        pw.Row(children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total Income', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(Formatters.amount(income), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total Expense', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(Formatters.amount(expense), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Net Balance', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(Formatters.amount(income - expense), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                ],
              ),
            ),
          ),
        ]),
        pw.SizedBox(height: 16),

        // Transactions Table
        pw.Table.fromTextArray(
          headers: ['Date', 'Type', 'Category', 'Amount', 'Notes'],
          data: txns.map((t) => [
            DateFormat('dd/MM/yyyy HH:mm').format(t.date),
            t.type.name.toUpperCase(),
            (t.categoryId == null ? 'Transfer' : (categories[t.categoryId] ?? 'Other')),
            Formatters.amount(t.amount),
            t.notes,
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
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
    Map<String, String> userProfile = const {},
  ]) {
    final book = Excel.createExcel();
    final sheet = book['Transactions'];

    final name = userProfile['name'] ?? 'Student';
    final email = userProfile['email'] ?? '';
    final phone = userProfile['phone'] ?? '';
    final school = userProfile['school'] ?? '';
    final course = userProfile['course'] ?? '';

    // Title & Header Block
    sheet.appendRow([TextCellValue('STUDENT EXPENSE MANAGER - FINANCIAL STATEMENT')]);
    sheet.appendRow([TextCellValue('STUDENT PROFILE / DETAILS')]);
    sheet.appendRow([TextCellValue('Student Name'), TextCellValue(name)]);
    if (email.isNotEmpty) sheet.appendRow([TextCellValue('Student Email'), TextCellValue(email)]);
    if (phone.isNotEmpty) sheet.appendRow([TextCellValue('Phone Number'), TextCellValue(phone)]);
    if (school.isNotEmpty) sheet.appendRow([TextCellValue('School / Institution'), TextCellValue(school)]);
    if (course.isNotEmpty) sheet.appendRow([TextCellValue('Course / Programme'), TextCellValue(course)]);
    sheet.appendRow([TextCellValue('Account Book'), TextCellValue(accountName)]);
    sheet.appendRow([TextCellValue('Generated On'), TextCellValue(DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()))]);

    final income = txns.where((t) => t.type == TransactionType.income).fold<double>(0, (s,t)=>s+t.amount);
    final expense = txns.where((t) => t.type == TransactionType.expense).fold<double>(0, (s,t)=>s+t.amount);
    sheet.appendRow([TextCellValue('Total Income'), DoubleCellValue(income)]);
    sheet.appendRow([TextCellValue('Total Expense'), DoubleCellValue(expense)]);
    sheet.appendRow([TextCellValue('Net Balance'), DoubleCellValue(income - expense)]);
    sheet.appendRow([]); // Blank separator

    // Transaction Columns Layout
    sheet.appendRow([
      TextCellValue('Date & Time'),
      TextCellValue('Transaction ID'),
      TextCellValue('Account'),
      TextCellValue('Type'),
      TextCellValue('Category'),
      TextCellValue('Amount'),
      TextCellValue('Notes'),
      TextCellValue('Item Details'),
      TextCellValue('Attachments'),
    ]);

    for (final t in txns) {
      final itemText = t.items.map((i) => '${i.name} (x${i.quantity}${i.unit.isNotEmpty ? ' ${i.unit}' : ''} @ ${i.rate})').join('; ');
      sheet.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(t.date)),
        TextCellValue(t.id),
        TextCellValue(accounts[t.accountId] ?? t.accountId),
        TextCellValue(t.type.name.toUpperCase()),
        TextCellValue(t.categoryId == null ? 'Transfer' : (categories[t.categoryId] ?? 'Other')),
        DoubleCellValue(t.amount),
        TextCellValue(t.notes),
        TextCellValue(itemText),
        TextCellValue(t.billPaths.map((p) => receiptNames[p] ?? p).join('; ')),
      ]);
    }
    return Uint8List.fromList(book.encode() ?? <int>[]);
  }
}
