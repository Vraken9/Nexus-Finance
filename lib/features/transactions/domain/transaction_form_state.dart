import '../../../data/models/transaction_model.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// TransactionFormState
///
/// Immutable form state for the Add / Edit Transaction screen.
/// date is always non-null and defaults to DateTime.now().
/// Validation errors are nullable strings — null means valid.
/// ─────────────────────────────────────────────────────────────────────────
class TransactionFormState {
  TransactionFormState({
    this.amountText = '',
    this.type = 'expense',
    this.categoryId = '',
    this.assetType = '',    // AssetType.storageKey; '' means not selected
    this.fromAccountId = '',
    this.toAccountId = '',
    this.transferFeeText = '0',
    DateTime? date,
    this.note,
    this.attachmentText,
    this.imagePath,
    this.isSubmitting = false,
    this.amountError,
    this.categoryError,
    this.assetError,
    this.transferAccountError,
    this.editingId,
  }) : date = date ?? DateTime.now();

  // ── Core ───────────────────────────────────────────────────────────────────
  final String amountText;
  final String type; // 'income' | 'expense' | 'transfer'
  final DateTime date; // always non-null; auto-populated from device clock

  // ── Income / Expense ───────────────────────────────────────────────────────
  final String categoryId;
  final String assetType; // AssetType.storageKey; empty = not selected

  // ── Transfer ───────────────────────────────────────────────────────────────
  final String fromAccountId;
  final String toAccountId;
  final String transferFeeText;

  // ── Shared optional ────────────────────────────────────────────────────────
  final String? note;
  final String? attachmentText;
  final String? imagePath;

  // ── Submission state ───────────────────────────────────────────────────────
  final bool isSubmitting;
  final int? editingId;

  // ── Validation errors ──────────────────────────────────────────────────────
  final String? amountError;
  final String? categoryError;
  final String? assetError;           // null = no asset selected (income/expense)
  final String? transferAccountError; // from == to error

  // ── Computed ───────────────────────────────────────────────────────────────

  bool get isEditing => editingId != null;
  bool get isTransfer => type == 'transfer';

  /// Parses [amountText] to a positive double; null if unparseable or ≤ 0.
  double? get parsedAmount {
    final cleaned = amountText.replaceAll(RegExp(r'[^\d.]'), '').trim();
    final v = double.tryParse(cleaned);
    return (v != null && v > 0) ? v : null;
  }

  double get parsedTransferFee {
    final cleaned = transferFeeText.replaceAll(RegExp(r'[^\d.]'), '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Returns true when the form has enough valid data to submit.
  bool get isValid {
    if (parsedAmount == null) return false;
    if (isTransfer) {
      return fromAccountId.isNotEmpty &&
          toAccountId.isNotEmpty &&
          fromAccountId != toAccountId;
    }
    return categoryId.isNotEmpty && assetType.isNotEmpty;
  }

  // ── Factory ────────────────────────────────────────────────────────────────

  factory TransactionFormState.fromModel(TransactionModel model) =>
      TransactionFormState(
        amountText: model.amount.toStringAsFixed(0),
        type: model.type,
        categoryId: model.categoryId ?? '',
        assetType: model.assetType ?? '',
        fromAccountId: model.fromAccountId ?? '',
        toAccountId: model.toAccountId ?? '',
        transferFeeText: model.transferFee.toStringAsFixed(0),
        date: model.date,
        note: model.note,
        attachmentText: model.attachmentText,
        imagePath: model.imagePath,
        editingId: model.id,
      );

  TransactionFormState copyWith({
    String? amountText,
    String? type,
    String? categoryId,
    String? assetType,
    String? fromAccountId,
    String? toAccountId,
    String? transferFeeText,
    DateTime? date,
    String? note,
    bool clearNote = false,
    String? attachmentText,
    bool clearAttachmentText = false,
    String? imagePath,
    bool clearImagePath = false,
    bool isSubmitting = false,
    String? amountError,
    bool clearAmountError = false,
    String? categoryError,
    bool clearCategoryError = false,
    String? assetError,
    bool clearAssetError = false,
    String? transferAccountError,
    bool clearTransferAccountError = false,
    int? editingId,
  }) =>
      TransactionFormState(
        amountText: amountText ?? this.amountText,
        type: type ?? this.type,
        categoryId: categoryId ?? this.categoryId,
        assetType: assetType ?? this.assetType,
        fromAccountId: fromAccountId ?? this.fromAccountId,
        toAccountId: toAccountId ?? this.toAccountId,
        transferFeeText: transferFeeText ?? this.transferFeeText,
        date: date ?? this.date,
        note: clearNote ? null : (note ?? this.note),
        attachmentText: clearAttachmentText ? null : (attachmentText ?? this.attachmentText),
        imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
        isSubmitting: isSubmitting,
        amountError: clearAmountError ? null : (amountError ?? this.amountError),
        categoryError: clearCategoryError ? null : (categoryError ?? this.categoryError),
        assetError: clearAssetError ? null : (assetError ?? this.assetError),
        transferAccountError: clearTransferAccountError
            ? null
            : (transferAccountError ?? this.transferAccountError),
        editingId: editingId ?? this.editingId,
      );
}
