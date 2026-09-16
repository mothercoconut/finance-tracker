import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' show DatabaseException;

import '../database/income_dao.dart';
import '../models/income.dart';
import '../widgets/money.dart';

/// Records one income entry.
///
/// Mirrors [AddExpenseScreen]: pops with `true` when something was saved so
/// the dashboard knows to re-read the balance from the database.
class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key, required this.incomeDao});

  final IncomeDao incomeDao;

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();

  DateTime _date = DateTime.now();

  /// The `recurring` column is NOT NULL with a default of 0, so the switch
  /// starts off rather than indeterminate.
  bool _recurring = false;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _saving = true);

    try {
      await widget.incomeDao.insertIncome(
        Income(
          amount: double.parse(_amountController.text.trim()),
          date: _date,
          source: _sourceController.text.trim(),
          recurring: _recurring,
        ),
      );
    } on DatabaseException catch (error) {
      if (mounted) {
        setState(() => _saving = false);
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save this income: $error')),
      );
      return;
    }

    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Income')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AmountField(controller: _amountController, label: 'Amount'),
              const SizedBox(height: 16),
              // `source` is NOT NULL in the schema, so it is required here.
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(
                  labelText: 'Source',
                  hintText: 'Paycheck, refund, gift...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter where it came from' : null,
              ),
              const SizedBox(height: 16),
              DateField(
                date: _date,
                onChanged: (picked) => setState(() => _date = picked),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Recurring'),
                subtitle: const Text('Repeats every month'),
                value: _recurring,
                onChanged: (value) => setState(() => _recurring = value),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Save income'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
