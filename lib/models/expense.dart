class Expense {
  final int? id;
  final double amount;
  final DateTime date;
  final int categoryId;
  final String? note;

  const Expense({
    this.id,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.note,
  });

  Expense copyWith({
    int? id,
    double? amount,
    DateTime? date,
    int? categoryId,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'note': note,
    };
  }

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      categoryId: map['category_id'] as int,
      note: map['note'] as String?,
    );
  }

  @override
  String toString() =>
      'Expense(id: $id, amount: $amount, date: $date, categoryId: $categoryId, note: $note)';
}
