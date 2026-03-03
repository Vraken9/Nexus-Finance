import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/enums/asset_type.dart';
import '../../../data/models/transaction_model.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../dashboard/domain/dashboard_notifier.dart';
import 'grouped_transactions_provider.dart';
import 'transaction_form_state.dart';
import 'transaction_list_notifier.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// TransactionFormNotifier
///
/// Handles all state mutations for the Add / Edit transaction form.
/// Supports three transaction types: income, expense, transfer.
/// ─────────────────────────────────────────────────────────────────────────
class TransactionFormNotifier extends AutoDisposeNotifier<TransactionFormState> {
  @override
  TransactionFormState build() => TransactionFormState(); // date defaults to now

  // ── Field setters ──────────────────────────────────────────────────────────

  void setAmount(String value) =>
      state = state.copyWith(amountText: value, clearAmountError: true);

  void setType(String type) {
    // When switching types, keep amount/date/note but clear type-specific fields.
    state = state.copyWith(
      type: type,
      categoryId: '',
      assetType: '',
      fromAccountId: '',
      toAccountId: '',
      transferFeeText: '0',
      clearAmountError: true,
      clearCategoryError: true,
      clearAssetError: true,
      clearTransferAccountError: true,
    );
  }

  void setCategory(String categoryId) =>
      state = state.copyWith(categoryId: categoryId, clearCategoryError: true);

  /// [assetKey] is [AssetType.storageKey] — e.g. 'cash', 'bank_transfer'.
  void setAsset(String assetKey) =>
      state = state.copyWith(assetType: assetKey, clearAssetError: true);

  void setFromAccount(String accountId) {
    state = state.copyWith(
      fromAccountId: accountId,
      clearTransferAccountError: true,
    );
  }

  void setToAccount(String accountId) {
    state = state.copyWith(
      toAccountId: accountId,
      clearTransferAccountError: true,
    );
  }

  void setTransferFee(String value) =>
      state = state.copyWith(transferFeeText: value);

  void setDate(DateTime date) => state = state.copyWith(date: date);

  void setNote(String? note) => state = state.copyWith(
        note: note,
        clearNote: note == null || note.isEmpty,
      );

  void setAttachmentText(String? text) => state = state.copyWith(
        attachmentText: text,
        clearAttachmentText: text == null || text.isEmpty,
      );

  void setImagePath(String? path) => state = state.copyWith(
        imagePath: path,
        clearImagePath: path == null,
      );

  void initForEdit(TransactionModel model) =>
      state = TransactionFormState.fromModel(model);

  // ── Submit ─────────────────────────────────────────────────────────────────

  /// Returns true if submission succeeded; false if validation failed.
  Future<bool> submit() async {
    if (!_validate()) return false;

    state = state.copyWith(isSubmitting: true);

    final txRepo = ref.read(transactionRepositoryProvider);

    final tx = TransactionModel()
      ..amount = state.parsedAmount!
      ..type = state.type
      ..date = state.date
      ..note = state.note?.trim().isEmpty == true ? null : state.note?.trim()
      ..attachmentText = state.attachmentText?.trim().isEmpty == true
          ? null
          : state.attachmentText?.trim()
      ..imagePath = state.imagePath;

    if (state.isTransfer) {
      tx
        ..fromAccountId = state.fromAccountId
        ..toAccountId = state.toAccountId
        ..transferFee = state.parsedTransferFee;
    } else {
      tx
        ..categoryId = state.categoryId
        ..assetType = state.assetType;
    }

    if (state.isEditing) {
      final existing = txRepo.getById(state.editingId!);
      if (existing == null) {
        state = state.copyWith(isSubmitting: false);
        return false;
      }
      tx.id = existing.id;
      await txRepo.updateTransaction(updated: tx, previous: existing);
    } else {
      await txRepo.addTransaction(tx);
    }

    ref.invalidate(dashboardNotifierProvider);
    ref.invalidate(transactionListProvider);
    ref.invalidate(groupedTransactionsProvider);

    state = state.copyWith(isSubmitting: false);
    return true;
  }

  // ── Private validation ─────────────────────────────────────────────────────

  bool _validate() {
    String? amountErr;
    String? catErr;
    String? assetErr;
    String? transferErr;

    final parsed = state.parsedAmount;
    if (state.amountText.trim().isEmpty) {
      amountErr = AppStrings.validationRequired;
    } else if (parsed == null) {
      amountErr = AppStrings.validationAmountNaN;
    }

    if (state.isTransfer) {
      if (state.fromAccountId.isEmpty || state.toAccountId.isEmpty) {
        transferErr = AppStrings.validationRequired;
      } else if (state.fromAccountId == state.toAccountId) {
        transferErr = AppStrings.validationSameAccount;
      }
    } else {
      if (state.categoryId.isEmpty) catErr = AppStrings.validationRequired;
      if (state.assetType.isEmpty) assetErr = AppStrings.validationRequired;
    }

    state = state.copyWith(
      amountError: amountErr,
      categoryError: catErr,
      assetError: assetErr,
      transferAccountError: transferErr,
    );

    return amountErr == null && catErr == null && assetErr == null && transferErr == null;
  }
}

final transactionFormProvider =
    AutoDisposeNotifierProvider<TransactionFormNotifier, TransactionFormState>(
  TransactionFormNotifier.new,
);
