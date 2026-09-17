import 'package:intl/intl.dart';

// Currency formatting shared by any screen that renders a stored amount.
//
// Ported alongside the categories screen, which is currently the only caller.
// Only the formatter came across: the form fields that lived beside it on the
// screens branch belong to the "add" screens, and those already exist here
// with their own inputs — importing a second set would be a duplicate
// mechanism beside a working one, not a port.

/// One currency formatter for the whole app.
///
/// The locale is pinned to en_US rather than taken from the device, because
/// the assignment specifies USD: an unpinned formatter would render different
/// symbols and separators depending on which machine the demo runs on.
final NumberFormat _currency = NumberFormat.currency(locale: 'en_US', symbol: r'$');

/// Renders a stored amount for display, e.g. `1234.5` -> `$1,234.50`.
String formatMoney(double amount) => _currency.format(amount);
