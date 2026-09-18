import 'category.dart';
import 'expense.dart';

class ExpenseWithCategory {
  final Expense expense;
  final Category category;

  const ExpenseWithCategory({
    required this.expense,
    required this.category,
  });

  String get categoryName => category.name;
  CategoryType get categoryType => category.type;
}
