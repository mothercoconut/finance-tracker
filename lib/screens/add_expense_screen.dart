import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../database/expense_dao.dart';
import '../database/category_dao.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
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

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesForType = _categoriesForSelectedType;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
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
    );
  }
}
