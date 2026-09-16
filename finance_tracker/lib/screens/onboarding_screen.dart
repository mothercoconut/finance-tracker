import 'package:flutter/material.dart';

import '../database/settings_dao.dart';
import '../widgets/money.dart';

/// First-launch setup: collects the two numbers the dashboard needs before it
/// can show anything meaningful.
///
/// The DAO arrives by constructor injection so a widget test can hand in one
/// backed by a throwaway test database. [onComplete] is called after the write
/// succeeds; the caller (the startup gate) decides what to show next, because
/// this screen should not need to know it is being gated.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.settingsDao,
    required this.onComplete,
  });

  final SettingsDao settingsDao;
  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startingBalanceController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();

  /// Guards against a double tap starting two writes.
  bool _saving = false;

  @override
  void dispose() {
    _startingBalanceController.dispose();
    _monthlyIncomeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);

    // completeOnboarding writes both answers and the "done" flag in a single
    // batch, so the app can never come back up half-onboarded — either all
    // three settings are there or none are.
    await widget.settingsDao.completeOnboarding(
      startingBalance: double.parse(_startingBalanceController.text.trim()),
      monthlyIncome: double.parse(_monthlyIncomeController.text.trim()),
    );

    if (!mounted) {
      return;
    }
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Set up your tracker',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Two numbers to start with. Your balance is worked out from '
                'these plus everything you record from now on.',
              ),
              const SizedBox(height: 24),
              AmountField(
                controller: _startingBalanceController,
                label: 'Starting balance',
                // Zero is a legitimate answer here, unlike a transaction.
                minimum: 0,
              ),
              const SizedBox(height: 16),
              AmountField(
                controller: _monthlyIncomeController,
                label: 'Expected monthly income',
                minimum: 0,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Get started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
