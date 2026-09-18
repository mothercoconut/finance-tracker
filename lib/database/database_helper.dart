import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const String tableCategory = 'categories';
const String tableExpense = 'expenses';
const String tableIncome = 'income';
const String tableSettings = 'settings';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static String? _customDbName;

  DatabaseHelper._init();

  static set dbName(String name) {
    _customDbName = name;
    _database = null;
  }

  static String get dbName => _customDbName ?? 'finance_tracker.db';

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDB(dbName);
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final base = await getDatabasesPath();
    final path = join(base, fileName);

    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableCategory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableExpense (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL DEFAULT '',
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (category_id) REFERENCES $tableCategory(id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableIncome (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        source TEXT NOT NULL,
        date TEXT NOT NULL,
        recurring INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSettings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT NOT NULL
      )
    ''');

    const defaults = [
      {'name': 'Rent', 'type': 'necessary'},
      {'name': 'Groceries', 'type': 'necessary'},
      {'name': 'Utilities', 'type': 'necessary'},
      {'name': 'Transportation', 'type': 'necessary'},
      {'name': 'Healthcare', 'type': 'necessary'},
      {'name': 'Entertainment', 'type': 'discretionary'},
      {'name': 'Dining Out', 'type': 'discretionary'},
      {'name': 'Shopping', 'type': 'discretionary'},
    ];

    for (final category in defaults) {
      await db.insert(tableCategory, category);
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Older versions of this project used categoryId instead of category_id.
    // A fresh install uses the correct schema above. If an old database is
    // opened, add the canonical column and copy values when possible.
    if (oldVersion < 2) {
      final columns = await db.rawQuery('PRAGMA table_info($tableExpense)');
      final hasCanonical =
          columns.any((row) => row['name']?.toString() == 'category_id');
      final hasOld =
          columns.any((row) => row['name']?.toString() == 'categoryId');

      if (!hasCanonical) {
        await db.execute(
          'ALTER TABLE $tableExpense ADD COLUMN category_id INTEGER',
        );
      }
      if (hasOld) {
        await db.execute(
          'UPDATE $tableExpense SET category_id = categoryId WHERE category_id IS NULL',
        );
      }
    }
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}
