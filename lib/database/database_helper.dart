import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/category.dart';

const String tableCategory = 'category';
const String tableIncome = 'income';
const String tableExpense = 'expense';
const String tableSettings = 'settings';

/// Opens (and lazily creates/migrates) the single local SQLite database
/// used by the whole app.
///
/// Works on Android/iOS/desktop via `sqflite`, and on Chrome/web via
/// `sqflite_common_ffi_web` (SQLite compiled to WebAssembly, persisted in
/// IndexedDB). Everything else in the app talks to the database through the
/// *Dao classes, which all go through [DatabaseHelper.instance.database].
class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

<<<<<<< Updated upstream
  /// Overridable so tests can point each test file at its own database
  /// file — `sqflite_common_ffi` resolves a fixed on-disk path by default,
  /// and `flutter test` runs test files concurrently, so sharing this name
  /// across files causes cross-test data contamination.
  static String dbName = 'finance_tracker.db';
  static const int _dbVersion = 1;
=======
  static const String _dbName = 'finance_tracker.db';
  static const int _dbVersion = 2; // Incremented for title migration
>>>>>>> Stashed changes

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final factory = kIsWeb ? databaseFactoryFfiWeb : databaseFactory;
    final path = kIsWeb ? dbName : join(await getDatabasesPath(), dbName);

    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Required so ON DELETE RESTRICT on expense.category_id is enforced.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableCategory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL CHECK (type IN ('necessary', 'discretionary'))
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableIncome (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL CHECK (amount > 0),
        date TEXT NOT NULL,
        source TEXT NOT NULL,
        recurring INTEGER NOT NULL DEFAULT 0 CHECK (recurring IN (0, 1))
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableExpense (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount REAL NOT NULL CHECK (amount > 0),
        date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY (category_id) REFERENCES $tableCategory (id)
          ON DELETE RESTRICT
      )
    ''');

    // Simple key/value store for app-level state that isn't a "table" in
    // the data model: onboarding status, starting balance, etc.
    await db.execute('''
      CREATE TABLE $tableSettings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_expense_date ON $tableExpense (date)',
    );
    await db.execute(
      'CREATE INDEX idx_expense_category ON $tableExpense (category_id)',
    );
    await db.execute('CREATE INDEX idx_income_date ON $tableIncome (date)');

    await _seedDefaultCategories(db);
  }

  /// Schema migration ladder. Add a new `if (oldVersion < N)` block (and
  /// bump [_dbVersion]) whenever the schema changes; each block should be
  /// safe to run against real user data already on disk.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $tableExpense ADD COLUMN title TEXT;');
    }
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final defaults = <Category>[
      const Category(name: 'Rent', type: CategoryType.necessary),
      const Category(name: 'Groceries', type: CategoryType.necessary),
      const Category(name: 'Utilities', type: CategoryType.necessary),
      const Category(name: 'Transportation', type: CategoryType.necessary),
      const Category(name: 'Entertainment', type: CategoryType.discretionary),
      const Category(name: 'Dining Out', type: CategoryType.discretionary),
      const Category(name: 'Shopping', type: CategoryType.discretionary),
      const Category(name: 'Other', type: CategoryType.discretionary),
    ];

    final batch = db.batch();
    for (final category in defaults) {
      batch.insert(tableCategory, category.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Closes and discards the cached database handle. Mainly useful for
  /// tests that open a fresh in-memory database per test case.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}