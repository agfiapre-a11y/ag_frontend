class FinanceTransaction {
  final String id;
  final String churchId;
  final String branchId;
  final String type; // 'income' | 'expense'
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final String recordedById;
  final DateTime createdAt;
  final bool isRecurring;
  final String recurrenceInterval;
  final String? receiptPath;
  final String? lastModifiedById;
  final DateTime? lastModifiedAt;

  const FinanceTransaction({
    required this.id,
    required this.churchId,
    required this.branchId,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.recordedById,
    required this.createdAt,
    this.isRecurring = false,
    this.recurrenceInterval = '',
    this.receiptPath,
    this.lastModifiedById,
    this.lastModifiedAt,
  });

  bool get isIncome => type == TransactionType.income;

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'type': type,
        'category': category,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
        'recordedById': recordedById,
        'createdAt': createdAt.toIso8601String(),
        'isRecurring': isRecurring,
        'recurrenceInterval': recurrenceInterval,
        'receiptPath': receiptPath,
        'lastModifiedById': lastModifiedById,
        'lastModifiedAt': lastModifiedAt?.toIso8601String(),
      };

  factory FinanceTransaction.fromMap(Map<dynamic, dynamic> map) =>
      FinanceTransaction(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: map['branchId'] as String,
        type: map['type'] as String,
        category: map['category'] as String,
        amount: (map['amount'] as num).toDouble(),
        description: (map['description'] as String?) ?? '',
        date: DateTime.parse(map['date'] as String),
        recordedById: map['recordedById'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        isRecurring: (map['isRecurring'] as bool?) ?? false,
        recurrenceInterval: (map['recurrenceInterval'] as String?) ?? '',
        receiptPath: map['receiptPath'] as String?,
        lastModifiedById: map['lastModifiedById'] as String?,
        lastModifiedAt: map['lastModifiedAt'] != null
            ? DateTime.parse(map['lastModifiedAt'] as String)
            : null,
      );
}

class RecurrenceInterval {
  static const monthly = 'monthly';
  static const weekly = 'weekly';
  static const quarterly = 'quarterly';
  static const yearly = 'yearly';

  static const all = [monthly, weekly, quarterly, yearly];

  static String label(String interval) {
    switch (interval) {
      case monthly:
        return 'Monthly';
      case weekly:
        return 'Weekly';
      case quarterly:
        return 'Quarterly';
      case yearly:
        return 'Yearly';
      default:
        return interval;
    }
  }
}

class TransactionType {
  static const income = 'income';
  static const expense = 'expense';
}

class IncomeCategories {
  static const tithe = 'Tithe';
  static const offering = 'Offering';
  static const donation = 'Donation';
  static const fundraising = 'Fundraising';
  static const other = 'Other Income';

  static const all = [tithe, offering, donation, fundraising, other];
}

class ExpenseCategories {
  static const salary = 'Salary';
  static const utilities = 'Utilities';
  static const rent = 'Rent';
  static const maintenance = 'Maintenance';
  static const events = 'Events';
  static const welfare = 'Welfare';
  static const missions = 'Missions';
  static const other = 'Other Expense';

  static const all = [
    salary,
    utilities,
    rent,
    maintenance,
    events,
    welfare,
    missions,
    other,
  ];
}
