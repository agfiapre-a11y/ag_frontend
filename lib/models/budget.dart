class Budget {
  final String id;
  final String churchId;
  final String branchId;
  final String category; // one of ExpenseCategories, or 'Overall'
  final double allocatedAmount;
  final String period; // 'YYYY-MM'
  final String notes;
  final String createdById;
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.churchId,
    required this.branchId,
    required this.category,
    required this.allocatedAmount,
    required this.period,
    this.notes = '',
    required this.createdById,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'category': category,
        'allocatedAmount': allocatedAmount,
        'period': period,
        'notes': notes,
        'createdById': createdById,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Budget.fromMap(Map<dynamic, dynamic> map) => Budget(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: (map['branchId'] as String?) ?? '',
        category: map['category'] as String,
        allocatedAmount: (map['allocatedAmount'] as num).toDouble(),
        period: map['period'] as String,
        notes: (map['notes'] as String?) ?? '',
        createdById: (map['createdById'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Budget copyWith({
    String? category,
    double? allocatedAmount,
    String? period,
    String? notes,
  }) =>
      Budget(
        id: id,
        churchId: churchId,
        branchId: branchId,
        category: category ?? this.category,
        allocatedAmount: allocatedAmount ?? this.allocatedAmount,
        period: period ?? this.period,
        notes: notes ?? this.notes,
        createdById: createdById,
        createdAt: createdAt,
      );
}

/// Helper for month-period keys, e.g. '2026-07'.
class BudgetPeriod {
  static String key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static String label(String period) {
    final parts = period.split('-');
    if (parts.length != 2) return period;
    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 1;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month < 1 || month > 12) return period;
    return '${months[month - 1]} $year';
  }
}
