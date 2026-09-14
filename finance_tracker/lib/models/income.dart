class Income {
  final int? id;
  final double amount;
  final DateTime date;
  final String source;
  final bool recurring;

  const Income({
    this.id,
    required this.amount,
    required this.date,
    required this.source,
    this.recurring = false,
  });

  Income copyWith({
    int? id,
    double? amount,
    DateTime? date,
    String? source,
    bool? recurring,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      source: source ?? this.source,
      recurring: recurring ?? this.recurring,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'source': source,
      'recurring': recurring ? 1 : 0,
    };
  }

  factory Income.fromMap(Map<String, Object?> map) {
    return Income(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      source: map['source'] as String,
      recurring: (map['recurring'] as int) == 1,
    );
  }

  @override
  String toString() =>
      'Income(id: $id, amount: $amount, date: $date, source: $source, recurring: $recurring)';
}
