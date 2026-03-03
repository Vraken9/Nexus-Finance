import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/models/transaction_model.dart';
import '../../../shared/providers/repository_providers.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// TransactionGroup
///
/// A single day bucket holding a human-readable [label] ("Hari ini",
/// "Kemarin", or a short date like "5 Jan 2025") and the [transactions]
/// that occurred on that calendar day (sorted descending by time).
/// ─────────────────────────────────────────────────────────────────────────
class TransactionGroup {
  const TransactionGroup({
    required this.date,
    required this.label,
    required this.transactions,
  });

  /// Truncated to midnight (no time component).
  final DateTime date;

  /// Human-readable day header label (Indonesian locale).
  final String label;

  final List<TransactionModel> transactions;

  /// Total income for this day.
  double get totalIncome => transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  /// Total expense for this day.
  double get totalExpense => transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Returns all transactions grouped by calendar day, newest group first.
/// Each transaction inside a group is also sorted descending by time.
///
/// This is a synchronous [Provider] — no async loading state needed because
/// Isar 3.x reads are synchronous.
final groupedTransactionsProvider = Provider<List<TransactionGroup>>((ref) {
  final txRepo = ref.watch(transactionRepositoryProvider);
  final all = txRepo.getAllSortedByDate(); // already sorted desc by date

  if (all.isEmpty) return const [];

  final today = DateHelpers.today;
  final yesterday = today.subtract(const Duration(days: 1));

  // Group by truncated day key.
  final Map<DateTime, List<TransactionModel>> buckets = {};
  for (final tx in all) {
    final dayKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
    buckets.putIfAbsent(dayKey, () => []).add(tx);
  }

  // Sort bucket keys descending (newest day first).
  final sortedDays = buckets.keys.toList()
    ..sort((a, b) => b.compareTo(a));

  String dayLabel(DateTime day) {
    if (day.isAtSameMomentAs(today)) return 'Hari ini';
    if (day.isAtSameMomentAs(yesterday)) return 'Kemarin';
    return DateHelpers.toShortDay(day);
  }

  return sortedDays.map((day) {
    final txs = buckets[day]!;
    // Ensure descending time order within the group.
    txs.sort((a, b) => b.date.compareTo(a.date));
    return TransactionGroup(
      date: day,
      label: dayLabel(day),
      transactions: txs,
    );
  }).toList();
});
