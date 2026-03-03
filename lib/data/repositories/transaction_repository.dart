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

  /// All-time net balance: total income − total expense (transfers excluded).
  /// This is the correct "Total Saldo" because income/expense transactions
  /// use [assetType] metadata — AccountModel.balance only updates for transfers.
  double getAllTimeBalance() {
    final all = getAllSortedByDate();
    final income = all.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final expense = all.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
    return income - expense;
  }

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

  /// Seeds demo transactions for February 2026 if the month is empty.
  /// Idempotent: returns immediately when any Feb 2026 transaction already exists.
  Future<void> seedFebruary2026Demo() async {
    final existing = getByMonth(DateTime(2026, 2, 1));
    if (existing.isNotEmpty) return;

    // Income/expense use assetType; transfers use account UUIDs.
    const cash = 'cash';
    const bank = 'bank_transfer';
    const wallet = 'e_wallet';
    const credit = 'credit';

    final txns = <TransactionModel>[
      // Income
      TransactionModel()
        ..amount = 20000000
        ..date = DateTime(2026, 2, 1, 9, 0)
        ..type = 'income'
        ..categoryId = 'cat-salary'
        ..assetType = bank
        ..note = 'Gaji Februari',
      TransactionModel()
        ..amount = 5500000
        ..date = DateTime(2026, 2, 10, 18, 0)
        ..type = 'income'
        ..categoryId = 'cat-freelance'
        ..assetType = bank
        ..note = 'Project desain',

      // Expense — one per day with stable range 350k–850k
      TransactionModel()..amount = 650000..date = DateTime(2026, 2, 1, 8, 45)..type = 'expense'..categoryId = 'cat-food'..assetType = wallet..note = 'Sarapan & kopi',
      TransactionModel()..amount = 520000..date = DateTime(2026, 2, 2, 12, 30)..type = 'expense'..categoryId = 'cat-food'..assetType = wallet..note = 'Makan siang tim',
      TransactionModel()..amount = 480000..date = DateTime(2026, 2, 3, 8, 0)..type = 'expense'..categoryId = 'cat-transport'..assetType = cash..note = 'BBM & parkir',
      TransactionModel()..amount = 720000..date = DateTime(2026, 2, 4, 19, 45)..type = 'expense'..categoryId = 'cat-entertainment'..assetType = credit..note = 'Nonton & makan',
      TransactionModel()..amount = 550000..date = DateTime(2026, 2, 5, 19, 30)..type = 'expense'..categoryId = 'cat-food'..assetType = wallet..note = 'Makan malam keluarga',
      TransactionModel()..amount = 430000..date = DateTime(2026, 2, 6, 14, 15)..type = 'expense'..categoryId = 'cat-food'..assetType = wallet..note = 'Ngopi & snack',
      TransactionModel()..amount = 620000..date = DateTime(2026, 2, 7, 10, 0)..type = 'expense'..categoryId = 'cat-shopping'..assetType = bank..note = 'Peralatan rumah tangga',
      TransactionModel()..amount = 580000..date = DateTime(2026, 2, 8, 15, 0)..type = 'expense'..categoryId = 'cat-health'..assetType = bank..note = 'Check-up ringan',
      TransactionModel()..amount = 470000..date = DateTime(2026, 2, 9, 18, 20)..type = 'expense'..categoryId = 'cat-food'..assetType = cash..note = 'Jajanan malam',
      TransactionModel()..amount = 520000..date = DateTime(2026, 2, 10, 12, 15)..type = 'expense'..categoryId = 'cat-transport'..assetType = bank..note = 'Taksi meeting',
      TransactionModel()..amount = 450000..date = DateTime(2026, 2, 11, 9, 30)..type = 'expense'..categoryId = 'cat-food'..assetType = wallet..note = 'Sarapan kantor',
      TransactionModel()..amount = 610000..date = DateTime(2026, 2, 12, 13, 0)..type = 'expense'..categoryId = 'cat-bills'..assetType = bank..note = 'Tagihan internet',
      TransactionModel()..amount = 530000..date = DateTime(2026, 2, 13, 17, 45)..type = 'expense'..categoryId = 'cat-entertainment'..assetType = credit..note = 'Sewa film',
      TransactionModel()..amount = 680000..date = DateTime(2026, 2, 14, 21, 0)..type = 'expense'..categoryId = 'cat-entertainment'..assetType = credit..note = 'Makan malam & bioskop',
      TransactionModel()..amount = 540000..date = DateTime(2026, 2, 15, 13, 10)..type = 'expense'..categoryId = 'cat-food'..assetType = wallet..note = 'Makan siang luar',
      TransactionModel()..amount = 470000..date = DateTime(2026, 2, 16, 8, 20)..type = 'expense'..categoryId = 'cat-transport'..assetType = cash..note = 'Ojek ke klien',
      TransactionModel()..amount = 720000..date = DateTime(2026, 2, 17, 11, 0)..type = 'expense'..categoryId = 'cat-shopping'..assetType = bank..note = 'Belanja bulanan ringan',
      TransactionModel()..amount = 430000..date = DateTime(2026, 2, 18, 19, 0)..type = 'expense'..categoryId = 'cat-food'..assetType = wallet..note = 'Cemilan malam',
      TransactionModel()..amount = 510000..date = DateTime(2026, 2, 19, 12, 40)..type = 'expense'..categoryId = 'cat-shopping'..assetType = bank..note = 'Alat tulis',
      TransactionModel()..amount = 620000..date = DateTime(2026, 2, 20, 7, 30)..type = 'expense'..categoryId = 'cat-transport'..assetType = cash..note = 'Transport mingguan',
      TransactionModel()..amount = 490000..date = DateTime(2026, 2, 21, 15, 30)..type = 'expense'..categoryId = 'cat-entertainment'..assetType = wallet..note = 'Ngopi & boardgame',
      TransactionModel()..amount = 600000..date = DateTime(2026, 2, 22, 16, 0)..type = 'expense'..categoryId = 'cat-health'..assetType = wallet..note = 'Vitamin & periksa',
      TransactionModel()..amount = 420000..date = DateTime(2026, 2, 23, 10, 0)..type = 'expense'..categoryId = 'cat-food'..assetType = cash..note = 'Sarapan luar',
      TransactionModel()..amount = 550000..date = DateTime(2026, 2, 24, 12, 0)..type = 'expense'..categoryId = 'cat-food'..assetType = cash..note = 'Makan siang',
      TransactionModel()..amount = 450000..date = DateTime(2026, 2, 25, 18, 10)..type = 'expense'..categoryId = 'cat-entertainment'..assetType = credit..note = 'Beli buku digital',
      TransactionModel()..amount = 520000..date = DateTime(2026, 2, 26, 19, 0)..type = 'expense'..categoryId = 'cat-entertainment'..assetType = wallet..note = 'Langganan streaming',
      TransactionModel()..amount = 480000..date = DateTime(2026, 2, 27, 18, 0)..type = 'expense'..categoryId = 'cat-bills'..assetType = bank..note = 'Listrik & air',
      TransactionModel()..amount = 560000..date = DateTime(2026, 2, 28, 12, 25)..type = 'expense'..categoryId = 'cat-food'..assetType = wallet..note = 'Makan siang akhir bulan',

      // Transfers (adjust account balances)
      TransactionModel()
        ..amount = 3000000
        ..date = DateTime(2026, 2, 6, 9, 0)
        ..type = 'transfer'
        ..fromAccountId = 'default-bank'
        ..toAccountId = 'default-card'
        ..transferFee = 0,
      TransactionModel()
        ..amount = 1500000
        ..date = DateTime(2026, 2, 15, 9, 30)
        ..type = 'transfer'
        ..fromAccountId = 'default-bank'
        ..toAccountId = 'default-ewallet'
        ..transferFee = 15000,
    ];

    await _isar.writeTxn(() async {
      for (final tx in txns) {
        await _isar.transactionModels.put(tx);
        if (tx.isTransfer) {
          // Adjust balances for transfers only.
          final from = await _isar.accountModels
              .filter()
              .uuidEqualTo(tx.fromAccountId ?? '')
              .findFirst();
          final to = await _isar.accountModels
              .filter()
              .uuidEqualTo(tx.toAccountId ?? '')
              .findFirst();
          if (from != null) {
            from.balance -= (tx.amount + tx.transferFee);
            await _isar.accountModels.put(from);
          }
          if (to != null) {
            to.balance += tx.amount;
            await _isar.accountModels.put(to);
          }
        }
      }
    });
  }

  // ══ PRIVATE ════════════════════════════════════════════════════════════════
  // Pre-read logic lives inline in each write method to keep the
  // async-inside-writeTxn deadlock pattern clear.
}
