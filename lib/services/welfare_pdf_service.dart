import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/welfare_case.dart';
import '../models/welfare_finance.dart';
import '../models/welfare_statement.dart';
import '../models/member.dart';

final _currencyFmt = NumberFormat('#,##0.00');
final _dateFmt = DateFormat('MMM d, yyyy');

class WelfarePdfService {
  static Future<void> printReport({
    required String title,
    required String churchName,
    required DateTime startDate,
    required DateTime endDate,
    required List<WelfareTransaction> transactions,
    List<WelfareCase>? welfareCases,
    List<Member>? members,
  }) async {
    final doc = _buildReportPdf(
      title: title,
      churchName: churchName,
      startDate: startDate,
      endDate: endDate,
      transactions: transactions,
      welfareCases: welfareCases,
      members: members,
    );
    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  static Future<Uint8List> generateReportPdf({
    required String title,
    required String churchName,
    required DateTime startDate,
    required DateTime endDate,
    required List<WelfareTransaction> transactions,
    List<WelfareCase>? welfareCases,
    List<Member>? members,
  }) async {
    final doc = _buildReportPdf(
      title: title,
      churchName: churchName,
      startDate: startDate,
      endDate: endDate,
      transactions: transactions,
      welfareCases: welfareCases,
      members: members,
    );
    return doc.save();
  }

  static Future<void> printStatement({
    required String churchName,
    required String memberName,
    required WelfareStatement statement,
    required List<WelfareTransaction> transactions,
  }) async {
    final doc = _buildStatementPdf(
      churchName: churchName,
      memberName: memberName,
      statement: statement,
      transactions: transactions,
    );
    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  static Future<Uint8List> generateStatementPdf({
    required String churchName,
    required String memberName,
    required WelfareStatement statement,
    required List<WelfareTransaction> transactions,
  }) async {
    final doc = _buildStatementPdf(
      churchName: churchName,
      memberName: memberName,
      statement: statement,
      transactions: transactions,
    );
    return doc.save();
  }

  static Future<void> downloadPdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  // ── Report PDF ──────────────────────────────────────────────────────────────

  static pw.Document _buildReportPdf({
    required String title,
    required String churchName,
    required DateTime startDate,
    required DateTime endDate,
    required List<WelfareTransaction> transactions,
    List<WelfareCase>? welfareCases,
    List<Member>? members,
  }) {
    final doc = pw.Document();

    final contributions =
        transactions.where((t) => t.isContribution).fold<double>(0, (s, t) => s + t.amount);
    final disbursements =
        transactions.where((t) => t.isDisbursement).fold<double>(0, (s, t) => s + t.amount);
    final expenses =
        transactions.where((t) => t.isExpense).fold<double>(0, (s, t) => s + t.amount);
    final balance = contributions - disbursements - expenses;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(churchName,
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Welfare Department',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.Center(
            child: pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
                'Period: ${_dateFmt.format(startDate)} to ${_dateFmt.format(endDate)}',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey)),
          ),
          pw.SizedBox(height: 20),

          // Summary
          pw.Text('Financial Summary',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _summaryTable([
            ['Total Contributions', _currencyFmt.format(contributions)],
            ['Total Disbursements', _currencyFmt.format(disbursements)],
            ['Total Expenses', _currencyFmt.format(expenses)],
            ['Net Balance', _currencyFmt.format(balance)],
            ['Total Transactions', '${transactions.length}'],
          ]),
          pw.SizedBox(height: 20),

          // Transaction list
          pw.Text('Transaction Details',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (transactions.isEmpty)
            pw.Text('No transactions in this period',
                style: const pw.TextStyle(color: PdfColors.grey))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(80),
                1: const pw.FixedColumnWidth(80),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FixedColumnWidth(80),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.green50),
                  children: [
                    _headerCell('Date'),
                    _headerCell('Type'),
                    _headerCell('Description'),
                    _headerCell('Member'),
                    _headerCell('Amount'),
                  ],
                ),
                ...transactions.map((t) {
                  final member = members?.where((m) => m.id == t.memberId).firstOrNull;
                  return pw.TableRow(
                    children: [
                      _cell(_dateFmt.format(t.date)),
                      _cell(WelfareTxnType.label(t.type)),
                      _cell(t.description.isNotEmpty ? t.description : t.category),
                      _cell(member?.name ?? 'N/A'),
                      _cell(_currencyFmt.format(t.amount),
                          alignment: pw.Alignment.centerRight),
                    ],
                  );
                }),
              ],
            ),

          // Welfare cases section
          if (welfareCases != null && welfareCases.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('Welfare Cases',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(80),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FixedColumnWidth(70),
                3: const pw.FixedColumnWidth(80),
                4: const pw.FixedColumnWidth(80),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                  children: [
                    _headerCell('Date'),
                    _headerCell('Type'),
                    _headerCell('Status'),
                    _headerCell('Requested'),
                    _headerCell('Disbursed'),
                  ],
                ),
                ...welfareCases.map((w) => pw.TableRow(
                      children: [
                        _cell(_dateFmt.format(w.dateRequested)),
                        _cell(WelfareType.label(w.type)),
                        _cell(WelfareStatus.label(w.status)),
                        _cell(_currencyFmt.format(w.amountRequested),
                            alignment: pw.Alignment.centerRight),
                        _cell(_currencyFmt.format(w.amountDisbursed),
                            alignment: pw.Alignment.centerRight),
                      ],
                    )),
              ],
            ),
          ],

          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
              'Generated on ${_dateFmt.format(DateTime.now())} by Paradise AG Welfare System',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
        ],
      ),
    );

    return doc;
  }

  // ── Statement PDF ───────────────────────────────────────────────────────────

  static pw.Document _buildStatementPdf({
    required String churchName,
    required String memberName,
    required WelfareStatement statement,
    required List<WelfareTransaction> transactions,
  }) {
    final doc = pw.Document();

    final contributions =
        transactions.where((t) => t.isContribution).fold<double>(0, (s, t) => s + t.amount);
    final disbursements =
        transactions.where((t) => t.isDisbursement).fold<double>(0, (s, t) => s + t.amount);
    final expenses =
        transactions.where((t) => t.isExpense).fold<double>(0, (s, t) => s + t.amount);
    final balance = contributions - disbursements - expenses;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(churchName,
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Welfare Department - Statement of Account',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 10),

          // Member info
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Member: $memberName',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(
                    'Statement Type: ${StatementType.label(statement.statementType)}'),
                pw.SizedBox(height: 4),
                pw.Text(
                    'Period: ${_dateFmt.format(statement.startDate)} to ${_dateFmt.format(statement.endDate)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Summary
          pw.Text('Account Summary',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _summaryTable([
            ['Total Contributions', _currencyFmt.format(contributions)],
            ['Total Disbursements', _currencyFmt.format(disbursements)],
            ['Total Expenses', _currencyFmt.format(expenses)],
            ['Account Balance', _currencyFmt.format(balance)],
            ['Number of Transactions', '${transactions.length}'],
          ]),
          pw.SizedBox(height: 20),

          // Transaction list
          pw.Text('Transaction History',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (transactions.isEmpty)
            pw.Text('No transactions in this period',
                style: const pw.TextStyle(color: PdfColors.grey))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(80),
                1: const pw.FixedColumnWidth(80),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FixedColumnWidth(80),
                4: const pw.FixedColumnWidth(80),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.green50),
                  children: [
                    _headerCell('Date'),
                    _headerCell('Type'),
                    _headerCell('Description'),
                    _headerCell('Method'),
                    _headerCell('Amount'),
                  ],
                ),
                ...transactions.map((t) => pw.TableRow(
                      children: [
                        _cell(_dateFmt.format(t.date)),
                        _cell(WelfareTxnType.label(t.type)),
                        _cell(t.description.isNotEmpty ? t.description : t.category),
                        _cell(WelfarePaymentMethod.label(t.paymentMethod)),
                        _cell(_currencyFmt.format(t.amount),
                            alignment: pw.Alignment.centerRight),
                      ],
                    )),
              ],
            ),

          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
              'This is a computer-generated statement from Paradise AG Welfare System',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          pw.Text('Generated on ${_dateFmt.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
        ],
      ),
    );

    return doc;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static pw.Widget _summaryTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows.map((r) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(r[0],
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(r[1],
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right),
              ),
            ],
          )).toList(),
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 10, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _cell(String text, {pw.Alignment? alignment}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          style: const pw.TextStyle(fontSize: 9),
          textAlign: alignment == pw.Alignment.centerRight
              ? pw.TextAlign.right
              : pw.TextAlign.left),
    );
  }
}
