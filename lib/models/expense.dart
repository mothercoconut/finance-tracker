class Expense {
  final int? id;
  final String title;
  final double amount;
  final int categoryId;
  final DateTime date;
  final String? note;

  const Expense({
    this.id,
    this.title = '',
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category_id': categoryId,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Expense.fromMap(Map<String, dynamic> map) {
    final rawCategoryId = map['category_id'] ?? map['categoryId'];
    return Expense(
      id: map['id'] as int?,
      title: map['title']?.toString() ?? map['name']?.toString() ?? '',
      amount: (map['amount'] as num).toDouble(),
      categoryId: (rawCategoryId as num).toInt(),
      date: DateTime.parse(map['date'].toString()),
      note: map['note']?.toString(),
    );
  }
}
