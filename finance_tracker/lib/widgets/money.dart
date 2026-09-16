import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Formatting helpers plus the two small form fields that both "add" screens
// share. They live together because they all answer the same question: how
// does a number the user typed become a row in the database, and back again.

/// One currency formatter for the whole app.
///
/// The locale is pinned to en_US rather than taken from the device, because
/// the assignment specifies USD: an unpinned formatter would render different
/// symbols and separators depending on which machine the demo runs on.
final NumberFormat _currency = NumberFormat.currency(locale: 'en_US', symbol: r'$');

/// Renders a stored amount for display, e.g. `1234.5` -> `$1,234.50`.
String formatMoney(double amount) => _currency.format(amount);

/// Dates are pinned to the same locale, for the same reason.
final DateFormat _dateFormat = DateFormat.yMMMd('en_US');

/// Renders a stored date for display, e.g. `Jan 5, 2026`.
String formatDate(DateTime date) => _dateFormat.format(date);

/// A validated money input.
///
/// The schema declares `CHECK (amount > 0)` on both income and expense, so an
/// unvalidated field would let a zero or a stray letter reach SQLite and come
/// back as a raw DatabaseException. Validating here keeps the error message in
/// the user's language instead.
///
/// [minimum] exists because onboarding's starting balance is legitimately
/// allowed to be zero, while a transaction amount is not.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.label,
    this.minimum = 0.01,
  });

  final TextEditingController controller;
  final String label;
  final double minimum;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: r'$ ',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final amount = double.tryParse((value ?? '').trim());
        if (amount == null) {
          return 'Enter an amount';
        }
        if (amount < minimum) {
          return 'Must be at least ${formatMoney(minimum)}';
        }
        return null;
      },
    );
  }
}

/// A read-only field that opens the Material date picker when tapped.
///
/// Shared by both "add" screens so the date rules — defaults to today, never
/// blank — are written once rather than duplicated per screen.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.date,
    required this.onChanged,
    this.label = 'Date',
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        // Nothing here touches `context` after the await, so there is no
        // stale-context hazard: the caller owns the rebuild.
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(formatDate(date)),
      ),
    );
  }
}
