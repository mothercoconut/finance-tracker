import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import 'database_helper.dart';

class CategoryDao {
  final Database? _providedDb;

  CategoryDao([this._providedDb]);

  Future<Database> get _db async =>
      _providedDb ?? await DatabaseHelper.instance.database;

  Future<int> insertCategory(Category category) async {
    final db = await _db;
    return db.insert('categories', category.toMap());
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Category.fromMap(rows.first);
  }

  Future<List<Category>> getAllCategories() async {
    final db = await _db;
    final rows = await db.query('categories', orderBy: 'id ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> updateCategory(Category category) async {
    if (category.id == null) {
      throw ArgumentError('Cannot update a category without an id.');
    }
    final db = await _db;
    return db.update(
      'categories',
      {'name': category.name, 'type': category.type.name},
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await _db;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isCategoryInUse(int categoryId) async {
    final db = await _db;
    final rows = await db.query(
      'expenses',
      columns: ['id'],
      where: 'category_id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
