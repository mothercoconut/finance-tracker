import '../models/category.dart';
import 'database_helper.dart';
import 'income_dao.dart';
import 'expense_dao.dart';
import 'settings_dao.dart';

/// Total spent in one category for the bar graph.
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

class ReportsDao {
  final ExpenseDao _expenseDao = ExpenseDao();
  final IncomeDao _incomeDao = IncomeDao();

  Future<double> getTotalIncomeInRange(DateTime start, DateTime end) async {
    final incomeList = await _incomeDao.getIncomeInRange(start, end);
    return incomeList.fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<double> getTotalExpensesInRange(DateTime start, DateTime end) async {
    final expenses = await _expenseDao.getExpensesWithCategoryInRange(start, end);
    return expenses.fold(0.0, (sum, item) => sum + item.expense.amount);
  }
}