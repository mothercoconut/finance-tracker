enum CategoryType { income, expense, necessary, discretionary }

class Category {
  final int? id;
  final String name;
  final CategoryType type;

  const Category({this.id, required this.name, required this.type});

  Category copyWith({int? id, String? name, CategoryType? type}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
      };

  factory Category.fromMap(Map<String, dynamic> map) {
    final raw = map['type']?.toString() ?? 'expense';
    final type = CategoryType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => CategoryType.expense,
    );
    return Category(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      type: type,
    );
  }
}
