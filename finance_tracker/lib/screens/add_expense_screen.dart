import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../database/expense_dao.dart';

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
  final int _selectedCategoryId = 1; // Default fallback category ID

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Padding(
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
                  if (_formKey.currentState!.validate()) {
                    final newExpense = Expense(
                      amount: double.parse(_amountController.text),
                      date: _selectedDate,
                      categoryId: _selectedCategoryId,
                      note: _noteController.text.isEmpty ? null : _noteController.text,
                    );

                    await ExpenseDao().insertExpense(newExpense);

                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  }
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