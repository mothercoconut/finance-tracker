import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import '../models/expense.dart';
import '../models/category.dart';
import '../database/expense_dao.dart';
import '../database/category_dao.dart';
=======
import '../database/expense_dao.dart';
import '../models/expense.dart';
>>>>>>> Stashed changes

class AddExpenseScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AddExpenseScreen({super.key, this.onSuccess});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
<<<<<<< Updated upstream
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  CategoryType _selectedType = CategoryType.necessary;
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await CategoryDao().getAllCategories();
    final forType = categories.where((c) => c.type == _selectedType).toList();
    setState(() {
      _categories = categories;
      _selectedCategory = forType.isEmpty ? null : forType.first;
      _loadingCategories = false;
    });
  }

  List<Category> get _categoriesForSelectedType =>
      _categories.where((c) => c.type == _selectedType).toList();
=======
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final ExpenseDao _expenseDao = ExpenseDao();
  int _selectedCategoryId = 1;
  bool _isSaving = false;
>>>>>>> Stashed changes

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    final titleText = _titleController.text.trim();
    final amountText = _amountController.text.trim();

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final expense = Expense(
        title: titleText.isEmpty ? 'Expense' : titleText,
        amount: amount,
        categoryId: _selectedCategoryId,
        date: DateTime.now(),
      );

      await _expenseDao.insertExpense(expense);

      if (!mounted) return;

      _titleController.clear();
      _amountController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully!')),
      );

      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesForType = _categoriesForSelectedType;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
<<<<<<< Updated upstream
      body: _loadingCategories
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount (\$)', prefixText: '\$'),
                      validator: (value) => value == null || double.tryParse(value) == null ? 'Enter a valid amount' : null,
                    ),
                    const SizedBox(height: 20),
                    const Text('Was this necessary?', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SegmentedButton<CategoryType>(
                      segments: const [
                        ButtonSegment(
                          value: CategoryType.necessary,
                          label: Text('Necessary'),
                          icon: Icon(Icons.check_circle_outline),
                        ),
                        ButtonSegment(
                          value: CategoryType.discretionary,
                          label: Text('Unnecessary'),
                          icon: Icon(Icons.shopping_bag_outlined),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _selectedType = selection.first;
                          final forType = _categoriesForSelectedType;
                          _selectedCategory = forType.isEmpty ? null : forType.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Category>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categoriesForType
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value),
                      validator: (value) => value == null ? 'Choose a category' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(labelText: 'Note / Description'),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text('Date: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate() || _selectedCategory == null) {
                          return;
                        }

                        final newExpense = Expense(
                          amount: double.parse(_amountController.text),
                          date: _selectedDate,
                          categoryId: _selectedCategory!.id!,
                          note: _noteController.text.isEmpty ? null : _noteController.text,
                        );

                        await ExpenseDao().insertExpense(newExpense);

                        if (!context.mounted) return;
                        Navigator.pop(context, true);
                      },
                      child: const Text('Save Expense'),
                    ),
                  ],
                ),
              ),
            ),
=======
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Expense Description (e.g., Groceries, Rent)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Necessary')),
                DropdownMenuItem(value: 2, child: Text('Unnecessary')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategoryId = val);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveExpense,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Expense'),
            ),
          ],
        ),
      ),
>>>>>>> Stashed changes
    );
  }
}
