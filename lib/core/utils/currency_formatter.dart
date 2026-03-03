import 'package:intl/intl.dart';

/// Pure-function currency & number helpers.
/// Configured for Indonesian Rupiah (IDR).
abstract final class CurrencyFormatter {
  // ── Formatters (lazy-initialised singletons) ────────────────────────────
  static final NumberFormat _compact = NumberFormat.compact(locale: 'id_ID');
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0, // IDR typically has no decimal places
  );
  static final NumberFormat _plain = NumberFormat('#,##0', 'id_ID');

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Full currency string (IDR):  1234.5  → "Rp 1.234"
  static String format(double amount) => _currency.format(amount);

  /// Compact IDR with SI suffix:  1234567 → "Rp 1,2 Jt"  |  12345 → "Rp 12 Rb"
  static String formatCompact(double amount) =>
      'Rp\u00A0${_compact.format(amount)}'; // \u00A0 = non-breaking space

  /// Plain with commas, no symbol (IDR):  1234.5  → "1.234"
  static String formatPlain(double amount) => _plain.format(amount);

  /// Parses a user-entered string to [double].
  /// Strips whitespace and commas/periods before parsing.
  /// Returns [null] if the input is not a valid number.
  static double? tryParse(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '').trim();
    return double.tryParse(cleaned);
  }

  /// Returns a signed, colour-aware label (IDR).
  /// [isExpense] = true  →  "- Rp 1.234"
  /// [isExpense] = false →  "+ Rp 1.234"
  static String formatSigned(double amount, {required bool isExpense}) =>
      '${isExpense ? '- ' : '+ '}${format(amount)}';
}
