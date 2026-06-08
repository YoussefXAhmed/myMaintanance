import 'enums.dart';

class Expense {
  const Expense({
    required this.id,
    required this.vehicleId,
    required this.category,
    required this.amount,
    required this.date,
    this.title = '',
    this.notes = '',
    this.createdAt,
  });

  final String id;
  final String vehicleId;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String title;
  final String notes;
  final DateTime? createdAt;

  Expense copyWith({
    ExpenseCategory? category,
    double? amount,
    DateTime? date,
    String? title,
    String? notes,
  }) =>
      Expense(
        id: id,
        vehicleId: vehicleId,
        category: category ?? this.category,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'category': category.name,
        'amount': amount,
        'date': date.toIso8601String(),
        'title': title,
        'notes': notes,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        vehicleId: j['vehicleId'] as String,
        category: enumFromName(ExpenseCategory.values, j['category'] as String?, ExpenseCategory.other),
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        date: DateTime.parse(j['date'] as String),
        title: (j['title'] as String?) ?? '',
        notes: (j['notes'] as String?) ?? '',
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'] as String) : null,
      );
}
