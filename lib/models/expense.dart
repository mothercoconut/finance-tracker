class Expense {
  final int? id;
  final String title;
  final double amount;
  final int categoryId;
  final DateTime date;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category_id': categoryId,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? 'Expense',
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int,
      date: DateTime.parse(map['date'] as String),
    );
  }
}