import 'package:isar/isar.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// AccountRepository
///
/// Manages [AccountModel] CRUD.  Balance mutation is done exclusively via
/// [TransactionRepository] to keep the ledger consistent — this repo exposes
/// only structural operations (create / update metadata / delete).
/// ─────────────────────────────────────────────────────────────────────────
class AccountRepository {
  const AccountRepository(this._isar);

  final Isar _isar;

  // ══ WRITE ══════════════════════════════════════════════════════════════════

  Future<void> createAccount(AccountModel account) async {
    await _isar.writeTxn(() => _isar.accountModels.put(account));
  }

  /// Updates non-financial metadata (name, icon, type).
  /// Never call this to change [balance] directly.
  Future<void> updateAccount(AccountModel account) async {
    await _isar.writeTxn(() => _isar.accountModels.put(account));
  }

  /// Deletes an account only if:
  ///  - it is not a default/seed account, AND
  ///  - it has no linked transactions (income/expense or transfer).
  /// Returns true if deletion succeeded, false if blocked.
  Future<bool> deleteAccount(String accountUuid) async {
    final account = await _isar.accountModels
        .filter()
        .uuidEqualTo(accountUuid)
        .findFirst();

    if (account == null) return false;
    if (account.isDefault) return false; // Seed accounts are non-deletable

    // Income/expense use AssetType enum — no account FK to check.

    // Check transfer transactions (source)
    final hasFromTxn = await _isar.transactionModels
        .filter()
        .fromAccountIdEqualTo(accountUuid)
        .count()
        .then((n) => n > 0);
    if (hasFromTxn) return false;

    // Check transfer transactions (destination)
    final hasToTxn = await _isar.transactionModels
        .filter()
        .toAccountIdEqualTo(accountUuid)
        .count()
        .then((n) => n > 0);
    if (hasToTxn) return false;

    await _isar.writeTxn(() => _isar.accountModels.delete(account.id));
    return true;
  }

  // ══ READ ═══════════════════════════════════════════════════════════════════

  List<AccountModel> getAllActive() =>
      _isar.accountModels
          .filter()
          .isActiveEqualTo(true)
          .findAllSync();

  AccountModel? getByUuid(String uuid) =>
      _isar.accountModels.filter().uuidEqualTo(uuid).findFirstSync();

  /// Total net worth: sum of all active account balances.
  double getTotalBalance() =>
      getAllActive().fold(0.0, (sum, a) => sum + a.balance);

  // ══ SEED DATA ══════════════════════════════════════════════════════════════

  /// Creates the 4 default seed accounts on first launch.
  /// Idempotent — does nothing if any active accounts already exist.
  Future<void> seedDefaultAccounts() async {
    final existing = getAllActive();
    if (existing.isNotEmpty) return;

    final defaults = [
      AccountModel()
        ..uuid = 'default-cash'
        ..name = 'Cash'
        ..type = 'cash'
        ..balance = 0.0
        ..iconCodePoint = 0xe57f // Icons.payments
        ..isActive = true
        ..isDefault = true,
      AccountModel()
        ..uuid = 'default-bank'
        ..name = 'Bank'
        ..type = 'bank'
        ..balance = 0.0
        ..iconCodePoint = 0xe1e9 // Icons.account_balance
        ..isActive = true
        ..isDefault = true,
      AccountModel()
        ..uuid = 'default-card'
        ..name = 'Kartu'
        ..type = 'card'
        ..balance = 0.0
        ..iconCodePoint = 0xe1ba // Icons.credit_card
        ..isActive = true
        ..isDefault = true,
      AccountModel()
        ..uuid = 'default-ewallet'
        ..name = 'E-Wallet'
        ..type = 'ewallet'
        ..balance = 0.0
        ..iconCodePoint = 0xe044 // Icons.account_balance_wallet
        ..isActive = true
        ..isDefault = true,
    ];

    await _isar.writeTxn(() async {
      for (final a in defaults) {
        await _isar.accountModels.put(a);
      }
    });
  }
}
