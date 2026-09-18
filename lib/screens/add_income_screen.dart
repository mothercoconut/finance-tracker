import 'package:flutter/material.dart';
import '../database/income_dao.dart';
import '../models/income.dart';

class AddIncomeScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AddIncomeScreen({super.key, this.onSuccess});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  final IncomeDao _incomeDao = IncomeDao();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    final amountText = _amountController.text.trim();
    final sourceText = _sourceController.text.trim();

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
      final income = Income(
        amount: amount,
        source: sourceText.isEmpty ? 'General' : sourceText,
        date: DateTime.now(),
      );

      await _incomeDao.insertIncome(income);

      if (!mounted) return;

      _amountController.clear();
      _sourceController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income added successfully!')),
      );

      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving income: $e')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Income')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            TextField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Source (e.g., Job, Freelance)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveIncome,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
<<<<<<< Updated upstream
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final recurring = await _askRecurring();
                  if (recurring == null) return;

                  final newIncome = Income(
                    amount: double.parse(_amountController.text),
                    date: _selectedDate,
                    source: _sourceController.text,
                    recurring: recurring,
                  );

                  await IncomeDao().insertIncome(newIncome);

                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Save Income'),
              ),
            ],
          ),
=======
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Income'),
            ),
          ],
>>>>>>> Stashed changes
        ),
      ),
    );
  }

  Future<bool?> _askRecurring() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Recurring or one-time?'),
        content: const Text(
          'Does this income happen regularly (like a paycheck), or was it a one-time amount?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('One-Time'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recurring'),
          ),
        ],
      ),
    );
  }
}