class Income {
  final int? id;
  final double amount;
  final String source;
  final DateTime date;
  final bool recurring;

  const Income({
    this.id,
    required this.amount,
    required this.source,
    required this.date,
    this.recurring = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'source': source,
        'date': date.toIso8601String(),
        'recurring': recurring ? 1 : 0,
      };

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      source: map['source']?.toString() ?? '',
      date: DateTime.parse(map['date'].toString()),
      recurring: map['recurring'] == 1 || map['recurring'] == true,
    );
  }
}
