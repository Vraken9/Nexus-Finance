import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// AssetType
///
/// Represents the 4 fixed payment/asset types available for Income and
/// Expense transactions.  Transfer transactions use their own
/// from/to AccountModel fields and do NOT use this enum.
///
/// Stored in Isar as [storageKey] (a stable lowercase string).
/// Never store the enum index — the key is forward-compatible if the
/// enum order ever changes.
/// ─────────────────────────────────────────────────────────────────────────
enum AssetType {
  cash,
  bankTransfer,
  eWallet,
  credit;

  // ── Isar persistence ──────────────────────────────────────────────────────

  /// Stable string stored in the database. Do not rename.
  String get storageKey => switch (this) {
        AssetType.cash => 'cash',
        AssetType.bankTransfer => 'bank_transfer',
        AssetType.eWallet => 'e_wallet',
        AssetType.credit => 'credit',
      };

  /// Reconstruct from a stored key; returns null for unknown values.
  static AssetType? fromStorageKey(String? key) => switch (key) {
        'cash' => AssetType.cash,
        'bank_transfer' => AssetType.bankTransfer,
        'e_wallet' => AssetType.eWallet,
        'credit' => AssetType.credit,
        _ => null,
      };

  // ── UI helpers ────────────────────────────────────────────────────────────

  /// Indonesian display label.
  String get label => switch (this) {
        AssetType.cash => 'Tunai',
        AssetType.bankTransfer => 'Transfer',
        AssetType.eWallet => 'E-Wallet',
        AssetType.credit => 'Kredit',
      };

  /// Material icon representing this asset type.
  IconData get icon => switch (this) {
        AssetType.cash => Icons.wallet_outlined,
        AssetType.bankTransfer => Icons.swap_horiz_rounded,
        AssetType.eWallet => Icons.phone_android_outlined,
        AssetType.credit => Icons.credit_card_outlined,
      };

  /// Accent color for the chip/icon — distinct per type for quick scanning.
  Color get color => switch (this) {
        AssetType.cash => const Color(0xFF4CAF50),        // green
        AssetType.bankTransfer => const Color(0xFF2196F3), // blue
        AssetType.eWallet => const Color(0xFF9C27B0),      // purple
        AssetType.credit => const Color(0xFFFF5722),       // deep-orange
      };
}
