import 'package:isar/isar.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../../core/utils/date_helpers.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// TransactionRepository
///
/// Encapsulates every Isar query related to [TransactionModel].
/// All public methods are type-safe; no raw dynamic is ever returned.
///
/// Design:
///  • CRUD operations run in Isar write transactions.
///  • Read queries are synchronous (Isar 3.x is synchronous on the main
///    thread) and exposed as methods that return typed results.
///  • Complex aggregation (chart data) lives here — the notifier only
///    transforms the final typed output.
/// ─────────────────────────────────────────────────────────────────────────
class TransactionRepository {
  const TransactionRepository(this._isar);

  final Isar _isar;

  // ══ WRITE ══════════════════════════════════════════════════════════════════

  /// Inserts a new [TransactionModel] and adjusts account balance(s) atomically.
  ///
  /// • income/expense: adjusts [accountId] balance  
  /// • transfer: subtracts (amount + fee) from [fromAccountId],
  ///             adds amount to [toAccountId]
  Future<void> addTransaction(TransactionModel tx) async {
    AccountModel? fromAccount;
    AccountModel? toAccount;

    if (tx.isTransfer) {
      fromAccount = await _isar.accountModels
          .filter().uuidEqualTo(tx.fromAccountId ?? '').findFirst();
      toAccount = await _isar.accountModels
          .filter().uuidEqualTo(tx.toAccountId ?? '').findFirst();
    }
    // Income/expense use assetType (enum) — no AccountModel balance to update.

    await _isar.writeTxn(() async {
      await _isar.transactionModels.put(tx);
      if (tx.isTransfer) {
        if (fromAccount != null) {
          fromAccount.balance -= (tx.amount + tx.transferFee);
          await _isar.accountModels.put(fromAccount);
        }
        if (toAccount != null) {
          toAccount.balance += tx.amount;
          await _isar.accountModels.put(toAccount);
        }
      }
    });
  }

  /// Reverts [previous] then applies [updated], across all account types.
  Future<void> updateTransaction({
    required TransactionModel updated,
    required TransactionModel previous,
  }) async {
    // Collect every UUID we might need (transfer accounts only).
    final Set<String> uuids = {};
    if (previous.isTransfer) {
      if (previous.fromAccountId != null) uuids.add(previous.fromAccountId!);
      if (previous.toAccountId != null) uuids.add(previous.toAccountId!);
    }
    if (updated.isTransfer) {
      if (updated.fromAccountId != null) uuids.add(updated.fromAccountId!);
      if (updated.toAccountId != null) uuids.add(updated.toAccountId!);
    }

    // Pre-read all accounts (avoids async-inside-writeTxn deadlock).
    final Map<String, AccountModel> accounts = {};
    for (final uuid in uuids) {
      final a = await _isar.accountModels.filter().uuidEqualTo(uuid).findFirst();
      if (a != null) accounts[uuid] = a;
    }

    await _isar.writeTxn(() async {
      // 1. Revert old transaction's balance effect.
      if (previous.isTransfer) {
        final from = accounts[previous.fromAccountId];
        if (from != null) {
          from.balance += previous.amount + previous.transferFee;
          await _isar.accountModels.put(from);
        }
        final to = accounts[previous.toAccountId];
        if (to != null) {
          to.balance -= previous.amount;
          await _isar.accountModels.put(to);
        }
      }
      // Income/expense reverts nothing — assetType is metadata only.

      // 2. Apply new transaction's balance effect.
      if (updated.isTransfer) {
        final from = accounts[updated.fromAccountId];
        if (from != null) {
          from.balance -= (updated.amount + updated.transferFee);
          await _isar.accountModels.put(from);
        }
        final to = accounts[updated.toAccountId];
        if (to != null) {
          to.balance += updated.amount;
          await _isar.accountModels.put(to);
        }
      }
      // Income/expense applies nothing — assetType is metadata only.

      await _isar.transactionModels.put(updated);
    });
  }

  /// Deletes a transaction and reverts its balance effect.
  Future<void> deleteTransaction(TransactionModel tx) async {
    AccountModel? fromAccount;
    AccountModel? toAccount;

    if (tx.isTransfer) {
      fromAccount = await _isar.accountModels
          .filter().uuidEqualTo(tx.fromAccountId ?? '').findFirst();
      toAccount = await _isar.accountModels
          .filter().uuidEqualTo(tx.toAccountId ?? '').findFirst();
    }
    // Income/expense use assetType — no AccountModel balance to revert.

    await _isar.writeTxn(() async {
      await _isar.transactionModels.delete(tx.id);
      if (tx.isTransfer) {
        if (fromAccount != null) {
          fromAccount.balance += tx.amount + tx.transferFee; // revert: give back
          await _isar.accountModels.put(fromAccount);
        }
        if (toAccount != null) {
          toAccount.balance -= tx.amount; // revert: take back
          await _isar.accountModels.put(toAccount);
        }
      }
    });
  }

  // ══ READ – single / list ═══════════════════════════════════════════════════

  /// Returns all transactions sorted by date descending.
  List<TransactionModel> getAllSortedByDate() => _isar.transactionModels
      .where()
      .sortByDateDesc()
      .findAllSync();

  /// Direct O(1) primary-key lookup. Returns null if not found.
  TransactionModel? getById(int id) => _isar.transactionModels.getSync(id);

  /// Paginated transaction list — [page] is 0-indexed, [pageSize] defaults to 20.
  List<TransactionModel> getPagedByDate({int page = 0, int pageSize = 20}) =>
      _isar.transactionModels
          .where()
          .sortByDateDesc()
          .offset(page * pageSize)
          .limit(pageSize)
          .findAllSync();

  /// All transactions within the given [month] (date range inclusive).
  List<TransactionModel> getByMonth(DateTime month) {
    final start = DateHelpers.startOfMonth(month);
    final end = DateHelpers.endOfMonth(month);
    return _isar.transactionModels
        .filter()
        .dateBetween(start, end)
        .sortByDateDesc()
        .findAllSync();
  }

  /// Transactions involving a specific transfer account (from or to).
  List<TransactionModel> getByAccount(String accountId) {
    final fromTransfer = _isar.transactionModels
        .filter()
        .fromAccountIdEqualTo(accountId)
        .findAllSync();
    final toTransfer = _isar.transactionModels
        .filter()
        .toAccountIdEqualTo(accountId)
        .findAllSync();
    final all = {...fromTransfer, ...toTransfer}.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  /// Income/expense transactions filtered by [AssetType.storageKey].
  List<TransactionModel> getByAssetType(String assetKey) =>
      _isar.transactionModels
          .filter()
          .assetTypeEqualTo(assetKey)
          .sortByDateDesc()
          .findAllSync();

  /// Transactions for a specific category.
  List<TransactionModel> getByCategory(String categoryId) =>
      _isar.transactionModels
          .filter()
          .categoryIdEqualTo(categoryId)
          .sortByDateDesc()
          .findAllSync();

  // ══ AGGREGATION – chart & analytics ══════════════════════════════════════

  /// Returns a [Map<DateTime, double>] that sums expense amounts per calendar
  /// day for [month].  Missing days are included with value 0.0 so the chart
  /// always renders a full month's x-axis.
  ///
  /// Used by [DashboardNotifier] to build [FlSpot] data points.
  Map<DateTime, double> getDailyExpenseTotals(List<TransactionModel> monthTxns, DateTime month) {
    final txns = monthTxns.where((t) => t.isExpense).toList();
    final allDays = DateHelpers.daysInRange(
      DateHelpers.startOfMonth(month),
      DateHelpers.endOfMonth(month),
    );

    // Seed map with 0.0 for each day to guarantee contiguous x-axis data.
    final Map<DateTime, double> totals = {for (final d in allDays) d: 0.0};

    for (final tx in txns) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      totals[day] = (totals[day] ?? 0.0) + tx.amount;
    }
    return totals;
  }

  /// Monthly income total computed from an already-fetched list.
  double getMonthlyIncomeFromList(List<TransactionModel> monthTxns) =>
      monthTxns.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

  /// Monthly expense total computed from an already-fetched list.
  double getMonthlyExpensesFromList(List<TransactionModel> monthTxns) =>
      monthTxns.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);

  /// Monthly income total for [month].
  double getMonthlyIncome(DateTime month) =>
      getMonthlyIncomeFromList(getByMonth(month));

  /// Monthly expense total for [month].
  double getMonthlyExpenses(DateTime month) =>
      getMonthlyExpensesFromList(getByMonth(month));

  /// Returns a [Map<String, double>] of categoryId → total expense for [month].
  Map<String, double> getExpensesByCategory(DateTime month) {
    final txns = getByMonth(month).where((t) => t.isExpense);
    final Map<String, double> result = {};
    for (final tx in txns) {
      if (tx.categoryId == null) continue;
      result[tx.categoryId!] = (result[tx.categoryId!] ?? 0.0) + tx.amount;
    }
    return result;
  }

  // ══ PRIVATE ════════════════════════════════════════════════════════════════
  // Pre-read logic lives inline in each write method to keep the
  // async-inside-writeTxn deadlock pattern clear.
}
