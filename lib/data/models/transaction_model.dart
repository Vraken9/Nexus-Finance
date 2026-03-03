import 'package:isar/isar.dart';

part 'transaction_model.g.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Transaction – the core ledger entry.
///
/// [type]          : 'income' | 'expense' | 'transfer'
/// [categoryId]    : UUID FK to CategoryModel   (income/expense only)
/// [assetType]     : AssetType.storageKey        (income/expense only)
///                   one of 'cash' | 'bank_transfer' | 'e_wallet' | 'credit'
/// [fromAccountId] : UUID FK to AccountModel    (transfer: source)
/// [toAccountId]   : UUID FK to AccountModel    (transfer: destination)
/// [transferFee]   : Extra fee deducted from fromAccount on top of amount
/// ─────────────────────────────────────────────────────────────────────────
@collection
class TransactionModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late double amount;

  @Index(type: IndexType.value)
  late DateTime date;

  @Index(type: IndexType.value)
  late String type; // 'income' | 'expense' | 'transfer'

  // ── Income / Expense ──────────────────────────────────────────────────────

  @Index(type: IndexType.value)
  String? categoryId; // UUID FK to CategoryModel

  /// Stores [AssetType.storageKey] — 'cash' | 'bank_transfer' | 'e_wallet' | 'credit'
  @Index(type: IndexType.value)
  String? assetType; // income/expense only; null for transfers

  // ── Transfer ──────────────────────────────────────────────────────────────

  @Index(type: IndexType.value)
  String? fromAccountId; // UUID FK to AccountModel (source)

  @Index(type: IndexType.value)
  String? toAccountId; // UUID FK to AccountModel (destination)

  double transferFee = 0.0; // Additional fee deducted from fromAccount

  // ── Shared optional ───────────────────────────────────────────────────────

  String? note;
  String? attachmentText;
  String? imagePath;

  // ── Computed ──────────────────────────────────────────────────────────────

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
  bool get isTransfer => type == 'transfer';

  @override
  String toString() =>
      'TransactionModel(id: $id, amount: $amount, type: $type, date: $date)';
}
