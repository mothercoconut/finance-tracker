import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' show DatabaseException;

import '../database/category_dao.dart';
import '../database/expense_dao.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../widgets/money.dart';

/// Records one expense.
///
/// Pops with `true` when something was saved. The dashboard uses that as its
/// cue to re-read the balance rather than adjusting a number it holds locally,
/// so the database stays the only place a balance is computed.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.expenseDao,
    required this.categoryDao,
  });

  final ExpenseDao expenseDao;
  final CategoryDao categoryDao;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  /// Kicked off once, in a field initialiser, rather than inside build —
  /// otherwise every rebuild (each keystroke) would issue a fresh query.
  late final Future<List<Category>> _categories =
      widget.categoryDao.getAllCategories();

  /// Defaults to today, as required. Keeping the time-of-day means two
  /// expenses entered on the same day still sort in the order they were added.
  DateTime _date = DateTime.now();

  int? _categoryId;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    // Captured before the await: using `context` afterwards would be reading a
    // BuildContext that may no longer be mounted.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _saving = true);

    final note = _noteController.text.trim();
    try {
      await widget.expenseDao.insertExpense(
        Expense(
          amount: double.parse(_amountController.text.trim()),
          date: _date,
          categoryId: _categoryId!,
          // The column is nullable; an empty box should store NULL, not "".
          note: note.isEmpty ? null : note,
        ),
      );
    } on DatabaseException catch (error) {
      if (mounted) {
        setState(() => _saving = false);
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save this expense: $error')),
      );
      return;
    }

    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: FutureBuilder<List<Category>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Could not load categories: ${snapshot.error}'));
          }

          final categories = snapshot.data ?? const <Category>[];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AmountField(
                    controller: _amountController,
                    label: 'Amount',
                  ),
                  const SizedBox(height: 16),
                  // Required, per the spec: an expense with no category would
                  // be invisible to every report the database layer offers.
                  // The foreign key is NOT NULL as well, so this validator is
                  // the friendly half of a rule the schema also enforces.
                  DropdownButtonFormField<int>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final category in categories)
                        DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                    validator: (value) =>
                        value == null ? 'Choose a category' : null,
                  ),
                  const SizedBox(height: 16),
                  DateField(
                    date: _date,
                    onChanged: (picked) => setState(() => _date = picked),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('Save expense'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
