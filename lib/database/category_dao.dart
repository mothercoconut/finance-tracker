import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import 'database_helper.dart';

class CategoryDao {
  final DatabaseHelper _helper;

  CategoryDao({DatabaseHelper? helper}) : _helper = helper ?? DatabaseHelper.instance;

  Future<int> insertCategory(Category category) async {
    final db = await _helper.database;
    return db.insert(
      tableCategory,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateCategory(Category category) async {
    if (category.id == null) {
      throw ArgumentError('Cannot update a category without an id');
    }
    final db = await _helper.database;
    return db.update(
      tableCategory,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Deletes a category. Throws a [DatabaseException] (foreign key
  /// violation) if any expense still references it — callers should catch
  /// this and ask the user to reassign or delete those expenses first.
  Future<int> deleteCategory(int id) async {
    final db = await _helper.database;
    return db.delete(tableCategory, where: 'id = ?', whereArgs: [id]);
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await _helper.database;
    final rows = await db.query(
      tableCategory,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<List<Category>> getAllCategories() async {
    final db = await _helper.database;
    final rows = await db.query(tableCategory, orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<List<Category>> getCategoriesByType(CategoryType type) async {
    final db = await _helper.database;
    final rows = await db.query(
      tableCategory,
      where: 'type = ?',
      whereArgs: [type.value],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  /// True if any expense currently references [categoryId]. Handy for the
  /// categories screen to warn before attempting a delete.
  Future<bool> isCategoryInUse(int categoryId) async {
    final db = await _helper.database;
    final result = await db.rawQuery(
      'SELECT 1 FROM $tableExpense WHERE category_id = ? LIMIT 1',
      [categoryId],
    );
    return result.isNotEmpty;
  }
}
