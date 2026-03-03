import 'package:intl/intl.dart';

/// Every date/time computation lives here so the rest of the app
/// stays free of raw DateTime arithmetic.
/// Configured for Indonesian locale (id_ID).
abstract final class DateHelpers {
  static final DateFormat _displayDay = DateFormat('d MMM', 'id_ID');
  static final DateFormat _displayFull = DateFormat('EEEE, d MMM yyyy', 'id_ID');
  static final DateFormat _displayMonthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _displayDayWithTime = DateFormat('d MMM, HH:mm', 'id_ID');
  static final DateFormat _displayFullWithTime = DateFormat('EEEE, d MMM yyyy, HH:mm', 'id_ID');
  // Full Indonesian date + time: "Senin, 3 Maret 2026 14:30" (per user spec)
  static final DateFormat _fullDateTime =
      DateFormat.yMMMMEEEEd('id_ID').add_Hm();
  static final DateFormat _time = DateFormat('HH:mm', 'id_ID');
  static final DateFormat _iso = DateFormat('yyyy-MM-dd');

  // ── Formatting ────────────────────────────────────────────────────────────

  /// "5 Jan"
  static String toShortDay(DateTime date) => _displayDay.format(date);

  /// "5 Jan, 14:30"
  static String toShortDayWithTime(DateTime date) => _displayDayWithTime.format(date);

  /// "Senin, 5 Jan 2025"
  static String toFullDate(DateTime date) => _displayFull.format(date);

  /// "Senin, 5 Jan 2025, 14:30"
  static String toFullDateWithTime(DateTime date) => _displayFullWithTime.format(date);

  /// "Senin, 3 Maret 2026 14:30"  — used for transaction form date field.
  static String toFullDateTime(DateTime date) => _fullDateTime.format(date);

  /// "14:30"
  static String toTime(DateTime date) => _time.format(date);

  /// "Januari 2025"
  static String toMonthYear(DateTime date) => _displayMonthYear.format(date);

  /// "2025-01-05"
  static String toIso(DateTime date) => _iso.format(date);

  // ── Boundary helpers ─────────────────────────────────────────────────────

  /// First moment of the given month.
  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  /// Last moment of the given month (inclusive).
  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1).subtract(const Duration(milliseconds: 1));

  /// First moment of today.
  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ── Grouping ─────────────────────────────────────────────────────────────

  /// Groups a list of [DateTime]s by calendar day.
  /// Returns a map: day-truncated DateTime → list of original DateTimes.
  static Map<DateTime, List<DateTime>> groupByDay(List<DateTime> dates) {
    final Map<DateTime, List<DateTime>> result = {};
    for (final d in dates) {
      final key = DateTime(d.year, d.month, d.day);
      result.putIfAbsent(key, () => []).add(d);
    }
    return result;
  }

  /// Returns all calendar days between [start] and [end] inclusive.
  static List<DateTime> daysInRange(DateTime start, DateTime end) {
    final List<DateTime> days = [];
    DateTime current = DateTime(start.year, start.month, start.day);
    final boundary = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(boundary)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  // ── Recurring helpers ─────────────────────────────────────────────────────

  /// Given a [frequency] string ('daily' | 'weekly' | 'monthly'),
  /// returns the next occurrence after [from].
  static DateTime? nextOccurrence(String frequency, DateTime from) {
    return switch (frequency) {
      'daily' => from.add(const Duration(days: 1)),
      'weekly' => from.add(const Duration(days: 7)),
      'monthly' => DateTime(from.year, from.month + 1, from.day),
      _ => null,
    };
  }
}

