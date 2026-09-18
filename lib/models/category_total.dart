import 'category.dart';

class CategoryTotal {
  final int categoryId;
  final String categoryName;
  final CategoryType categoryType;
  final double total;

  const CategoryTotal({
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.total,
  });
}

class SpendingBreakdown {
  final double necessary;
  final double discretionary;

  const SpendingBreakdown({
    required this.necessary,
    required this.discretionary,
  });
}
