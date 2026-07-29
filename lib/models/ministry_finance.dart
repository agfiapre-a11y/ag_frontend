import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'member.dart';

final _currencyFmt = NumberFormat('#,##0.00');
final _dateFmt = DateFormat('MMM d, yyyy');

class MinistryFinance {
  final String id;
  final String churchId;
  final String branchId;
  final String ministryType;
  final String type; // 'income' | 'expense'
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final String recordedById;
  final DateTime createdAt;

  // Hierarchical fields
  final String? organizationId;
  final String? regionId;
  final String? districtId;
  final String? areaId;

  const MinistryFinance({
    required this.id,
    required this.churchId,
    required this.branchId,
    required this.ministryType,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.recordedById,
    required this.createdAt,
    this.organizationId,
    this.regionId,
    this.districtId,
    this.areaId,
  });

  bool get isIncome => type == 'income';

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'ministryType': ministryType,
        'type': type,
        'category': category,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
        'recordedById': recordedById,
        'createdAt': createdAt.toIso8601String(),
        'organizationId': organizationId,
        'regionId': regionId,
        'districtId': districtId,
        'areaId': areaId,
      };

  factory MinistryFinance.fromMap(Map<dynamic, dynamic> map) => MinistryFinance(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: (map['branchId'] as String?) ?? '',
        ministryType: (map['ministryType'] as String?) ?? '',
        type: map['type'] as String,
        category: (map['category'] as String?) ?? '',
        amount: (map['amount'] as num).toDouble(),
        description: (map['description'] as String?) ?? '',
        date: DateTime.parse(map['date'] as String),
        recordedById: (map['recordedById'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
        organizationId: map['organizationId'] as String?,
        regionId: map['regionId'] as String?,
        districtId: map['districtId'] as String?,
        areaId: map['areaId'] as String?,
      );
}

class MinistryAnnouncement {
  final String id;
  final String churchId;
  final String branchId;
  final String ministryType;
  final String title;
  final String message;
  final String fromId;
  final String fromName;
  final DateTime createdAt;
  final List<String> targetMemberIds;
  final bool isBroadcast;

  // Hierarchical fields
  final String? organizationId;
  final String? regionId;
  final String? districtId;
  final String? areaId;

  const MinistryAnnouncement({
    required this.id,
    required this.churchId,
    required this.branchId,
    required this.ministryType,
    required this.title,
    required this.message,
    required this.fromId,
    required this.fromName,
    required this.createdAt,
    this.targetMemberIds = const [],
    this.isBroadcast = false,
    this.organizationId,
    this.regionId,
    this.districtId,
    this.areaId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'ministryType': ministryType,
        'title': title,
        'message': message,
        'fromId': fromId,
        'fromName': fromName,
        'createdAt': createdAt.toIso8601String(),
        'targetMemberIds': targetMemberIds,
        'isBroadcast': isBroadcast,
        'organizationId': organizationId,
        'regionId': regionId,
        'districtId': districtId,
        'areaId': areaId,
      };

  factory MinistryAnnouncement.fromMap(Map<dynamic, dynamic> map) =>
      MinistryAnnouncement(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: (map['branchId'] as String?) ?? '',
        ministryType: (map['ministryType'] as String?) ?? '',
        title: (map['title'] as String?) ?? '',
        message: (map['message'] as String?) ?? '',
        fromId: (map['fromId'] as String?) ?? '',
        fromName: (map['fromName'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
        targetMemberIds:
            (map['targetMemberIds'] as List?)?.cast<String>() ?? [],
        isBroadcast: (map['isBroadcast'] as bool?) ?? false,
        organizationId: map['organizationId'] as String?,
        regionId: map['regionId'] as String?,
        districtId: map['districtId'] as String?,
        areaId: map['areaId'] as String?,
      );
}

class MinistryPdfService {
  static Future<Uint8List> generateFinanceReport({
    required String title,
    required String ministryName,
    required String churchName,
    required DateTime startDate,
    required DateTime endDate,
    required List<MinistryFinance> transactions,
  }) async {
    final doc = pw.Document();

    final incomeTx = transactions.where((t) => t.isIncome).toList();
    final expenseTx = transactions.where((t) => !t.isIncome).toList();
    final totalIncome = incomeTx.fold(0.0, (s, t) => s + t.amount);
    final totalExpense = expenseTx.fold(0.0, (s, t) => s + t.amount);
    final balance = totalIncome - totalExpense;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(churchName,
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('$ministryName - Finance Report',
                style: pw.TextStyle(
                    fontSize: 14, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(
                'Period: ${_dateFmt.format(startDate)} - ${_dateFmt.format(endDate)}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.Divider(),
          ],
        ),
        build: (ctx) => [
          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _summaryBox('Income', totalIncome, PdfColors.green),
                _summaryBox('Expense', totalExpense, PdfColors.red),
                _summaryBox('Balance', balance,
                    balance >= 0 ? PdfColors.blue : PdfColors.red),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          // Income table
          pw.Text('Income Transactions',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _transactionTable(incomeTx),
          pw.SizedBox(height: 20),
          // Expense table
          pw.Text('Expense Transactions',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _transactionTable(expenseTx),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> generateMemberReport({
    required String ministryName,
    required String churchName,
    required List<Member> members,
    required String ministryType,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(churchName,
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('$ministryName - Member Report',
                style: pw.TextStyle(
                    fontSize: 14, color: PdfColors.grey700)),
            pw.Divider(),
          ],
        ),
        build: (ctx) => [
          pw.Text('Total Members: ${members.length}',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Gender', 'Phone', 'Email', 'DOB'],
            data: members.map((m) {
              final age = m.dateOfBirth != null
                  ? '${DateTime.now().difference(m.dateOfBirth!).inDays ~/ 365} yrs'
                  : 'N/A';
              return [
                m.name,
                m.gender,
                m.phone,
                m.email,
                m.dateOfBirth != null
                    ? '${_dateFmt.format(m.dateOfBirth!)} ($age)'
                    : 'N/A',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(
                color: PdfColors.green100),
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _summaryBox(
      String label, double value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(_currencyFmt.format(value),
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.Widget _transactionTable(List<MinistryFinance> txs) {
    if (txs.isEmpty) {
      return pw.Text('No transactions',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500));
    }
    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Category', 'Description', 'Amount'],
      data: txs.map((t) {
        return [
          _dateFmt.format(t.date),
          t.category,
          t.description,
          _currencyFmt.format(t.amount),
        ];
      }).toList(),
      headerStyle:
          pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(5),
    );
  }
}
