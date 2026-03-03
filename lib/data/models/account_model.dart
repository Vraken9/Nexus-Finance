import 'package:isar/isar.dart';

part 'account_model.g.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Account – represents a wallet, bank account, card, or e-wallet.
///
/// [type]      : 'cash' | 'bank' | 'card' | 'ewallet'
/// [isDefault] : true for the 4 seed accounts — cannot be deleted.
///
/// [balance] is kept in sync by [TransactionRepository] after every
/// transaction write — never set directly from the UI.
/// ─────────────────────────────────────────────────────────────────────────
@collection
class AccountModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, unique: true)
  late String uuid;

  @Index(type: IndexType.value)
  late String name;

  late double balance;

  @Index(type: IndexType.value)
  late String type; // 'cash' | 'bank' | 'card' | 'ewallet'

  int iconCodePoint = 0xe03e; // Icons.account_balance_wallet

  bool isActive = true;

  /// Seed/default accounts cannot be deleted.
  bool isDefault = false;

  // ── Convenience ──────────────────────────────────────────────────────────

  bool get isCash => type == 'cash';
  bool get isBank => type == 'bank';
  bool get isCard => type == 'card';
  bool get isEwallet => type == 'ewallet';

  @override
  String toString() =>
      'AccountModel(uuid: $uuid, name: $name, balance: $balance, type: $type)';
}
