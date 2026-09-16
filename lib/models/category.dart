/// Whether a spending category is a "need" or a "want".
///
/// Stored in SQLite as the lowercase [name] (see [CategoryType.value] /
/// [CategoryType.fromValue]) so the column stays human-readable.
enum CategoryType {
  necessary,
  discretionary;

  String get value => name;

  static CategoryType fromValue(String value) {
    return CategoryType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => throw ArgumentError('Unknown category type: $value'),
    );
  }
}

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

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type.value,
    };
  }

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: CategoryType.fromValue(map['type'] as String),
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name, type: $type)';
}
