import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/enums/asset_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/models/transaction_model.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/custom_button.dart';
import '../domain/transaction_form_notifier.dart';
import './widgets/add_custom_category_dialog.dart';

/// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// AddTransactionScreen
///
/// Handles CREATE and EDIT modes for Income, Expense, and Transfer.
/// State is managed by [TransactionFormNotifier] (auto-disposed on pop).
/// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, this.editModel});

  final TransactionModel? editModel;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late final FocusNode _amountFocus;
  late final FocusNode _feeFocus;
  late final FocusNode _noteFocus;
  late final FocusNode _attachFocus;

  final _amountCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _attachCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountFocus = FocusNode();
    _feeFocus = FocusNode();
    _noteFocus = FocusNode();
    _attachFocus = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.editModel != null) {
        final notifier = ref.read(transactionFormProvider.notifier);
        notifier.initForEdit(widget.editModel!);
        _amountCtrl.text = widget.editModel!.amount.toStringAsFixed(0);
        _feeCtrl.text = widget.editModel!.transferFee.toStringAsFixed(0);
        _noteCtrl.text = widget.editModel!.note ?? '';
        _attachCtrl.text = widget.editModel!.attachmentText ?? '';
      }
      // date defaults to DateTime.now() via TransactionFormState constructor
    });
  }

  @override
  void dispose() {
    _amountFocus.dispose();
    _feeFocus.dispose();
    _noteFocus.dispose();
    _attachFocus.dispose();
    _amountCtrl.dispose();
    _feeCtrl.dispose();
    _noteCtrl.dispose();
    _attachCtrl.dispose();
    super.dispose();
  }

  void _moveFocus(FocusNode? next) {
    if (next == null) {
      FocusScope.of(context).unfocus();
    } else {
      FocusScope.of(context).requestFocus(next);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file != null && mounted) {
      ref.read(transactionFormProvider.notifier).setImagePath(file.path);
    }
  }

  void _showImageSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(AppStrings.camera),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppStrings.gallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(transactionFormProvider);
    final notifier = ref.read(transactionFormProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.editModel != null
              ? AppStrings.editTransaction
              : AppStrings.addTransaction,
          style: AppTextStyles.labelLarge,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Type selector (3 tabs) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _TypeTabBar(
              current: formState.type,
              onChanged: notifier.setType,
            ),
            const SizedBox(height: 24),

            // â”€â”€ Amount â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _FieldLabel(label: AppStrings.fieldAmount),
            TextField(
              controller: _amountCtrl,
              focusNode: _amountFocus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _moveFocus(_noteFocus),
              onChanged: notifier.setAmount,
              decoration: InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
                errorText: formState.amountError,
              ),
            ),
            const SizedBox(height: 16),

            // â”€â”€ Date & Time â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _FieldLabel(label: AppStrings.fieldDate),
            _DateTimePickerField(
              dateTime: formState.date,
              onChanged: notifier.setDate,
            ),
            const SizedBox(height: 16),

            // â”€â”€ Income / Expense fields â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (!formState.isTransfer) ...[
              _FieldLabel(label: AppStrings.fieldCategory),
              _CategoryDropdown(
                type: formState.type,
                value:
                    formState.categoryId.isEmpty ? null : formState.categoryId,
                error: formState.categoryError,
                onChanged: notifier.setCategory,
              ),
              const SizedBox(height: 16),

              _FieldLabel(label: AppStrings.fieldAsset),
              _AssetSelector(
                selected: formState.assetType.isEmpty
                    ? null
                    : AssetType.fromStorageKey(formState.assetType),
                error: formState.assetError,
                onChanged: (a) => notifier.setAsset(a.storageKey),
              ),
              const SizedBox(height: 16),
            ],

            // â”€â”€ Transfer fields â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (formState.isTransfer) ...[
              _FieldLabel(label: AppStrings.fieldFromAccount),
              _AccountDropdown(
                value: formState.fromAccountId.isEmpty
                    ? null
                    : formState.fromAccountId,
                error: formState.transferAccountError,
                excludeUuid: formState.toAccountId,
                onChanged: notifier.setFromAccount,
              ),
              const SizedBox(height: 16),

              _FieldLabel(label: AppStrings.fieldToAccount),
              _AccountDropdown(
                value: formState.toAccountId.isEmpty
                    ? null
                    : formState.toAccountId,
                error: null,
                excludeUuid: formState.fromAccountId,
                onChanged: notifier.setToAccount,
              ),
              const SizedBox(height: 16),

              _FieldLabel(label: AppStrings.fieldTransferFee),
              TextField(
                controller: _feeCtrl,
                focusNode: _feeFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _moveFocus(_noteFocus),
                onChanged: notifier.setTransferFee,
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '0',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // â”€â”€ Notes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _FieldLabel(label: AppStrings.fieldNote),
            TextField(
              controller: _noteCtrl,
              focusNode: _noteFocus,
              maxLines: 2,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _moveFocus(_attachFocus),
              onChanged: (v) => notifier.setNote(v.isEmpty ? null : v),
              decoration: const InputDecoration(hintText: 'Detail opsional...'),
            ),
            const SizedBox(height: 16),

            // â”€â”€ Attachment text â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _FieldLabel(label: AppStrings.fieldAttachment),
            TextField(
              controller: _attachCtrl,
              focusNode: _attachFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _moveFocus(null),
              onChanged: (v) =>
                  notifier.setAttachmentText(v.isEmpty ? null : v),
              decoration:
                  const InputDecoration(hintText: 'Nomor referensi, dll...'),
            ),
            const SizedBox(height: 16),

            // â”€â”€ Image attachment â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _ImagePickerSection(
              imagePath: formState.imagePath,
              onPickTap: _showImageSheet,
              onRemove: () => notifier.setImagePath(null),
            ),
            const SizedBox(height: 32),

            // â”€â”€ Save button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            PrimaryButton(
              label: widget.editModel != null
                  ? AppStrings.saveChanges
                  : AppStrings.addTransaction2,
              isLoading: formState.isSubmitting,
              onPressed: formState.isValid
                  ? () async {
                      final ok = await notifier.submit();
                      if (ok && context.mounted) Navigator.pop(context);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Field label helper
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label, style: AppTextStyles.labelSmall),
      );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// 3-segment type selector
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TypeTabBar extends StatelessWidget {
  const _TypeTabBar({required this.current, required this.onChanged});
  final String current;
  final ValueChanged<String> onChanged;

  static const _tabs = [
    (value: 'expense', label: 'Pengeluaran', color: AppColors.expense),
    (value: 'income', label: 'Pemasukan', color: AppColors.income),
    (value: 'transfer', label: 'Transfer', color: AppColors.primary),
  ];

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: _tabs.map((tab) {
            final selected = current == tab.value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(tab.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: selected ? tab.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      tab.label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Date + Time picker
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DateTimePickerField extends StatelessWidget {
  const _DateTimePickerField(
      {required this.dateTime, required this.onChanged});
  final DateTime dateTime;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: dateTime,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
              ),
              child: child!,
            ),
          );
          if (pickedDate == null || !context.mounted) return;

          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(dateTime),
          );

          final merged = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime?.hour ?? dateTime.hour,
            pickedTime?.minute ?? dateTime.minute,
          );
          onChanged(merged);
        },
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  DateHelpers.toFullDateTime(dateTime),
                  style: AppTextStyles.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.edit_outlined,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Category dropdown
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CategoryDropdown extends ConsumerWidget {
  const _CategoryDropdown({
    required this.type,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final String type;
  final String? value;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories =
        ref.watch(categoryRepositoryProvider).getAllForType(type);

    // Guard: if the stored value no longer exists in the filtered list,
    // treat it as unselected to avoid a DropdownButtonFormField assertion.
    final safeValue = value != null && categories.any((c) => c.uuid == value)
        ? value
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: safeValue,
          decoration: InputDecoration(errorText: error),
          hint: Text(AppStrings.selectCategory),
          items: categories
              .map((c) => DropdownMenuItem(value: c.uuid, child: Text(c.name)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: Text(AppStrings.addCustomCategory),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AddCustomCategoryDialog(
                type: type,
                onCategoryAdded: (uuid) {
                  ref.invalidate(categoryRepositoryProvider);
                  onChanged(uuid);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Account dropdown (reused for account, from-account, to-account)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// ─────────────────────────────────────────────────────────────────────────────
// Asset type selector (Income / Expense only)
// ─────────────────────────────────────────────────────────────────────────────

class _AssetSelector extends StatelessWidget {
  const _AssetSelector({
    required this.selected,
    required this.error,
    required this.onChanged,
  });

  final AssetType? selected;
  final String? error;
  final ValueChanged<AssetType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AssetType.values.map((asset) {
            final isSelected = selected == asset;
            return GestureDetector(
              onTap: () => onChanged(asset),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? asset.color.withOpacity(0.15)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? asset.color : AppColors.border,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      asset.icon,
                      size: 18,
                      color: isSelected
                          ? asset.color
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      asset.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected
                            ? asset.color
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account dropdown (Transfer: from-account / to-account only)
// ─────────────────────────────────────────────────────────────────────────────

class _AccountDropdown extends ConsumerWidget {
  const _AccountDropdown({
    required this.value,
    required this.error,
    required this.onChanged,
    this.excludeUuid,
  });

  final String? value;
  final String? error;
  final ValueChanged<String> onChanged;
  final String? excludeUuid; // For transfer: exclude the other selected account

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref
        .watch(accountRepositoryProvider)
        .getAllActive()
        .where((a) => excludeUuid == null || a.uuid != excludeUuid)
        .toList();

    // Guard: if the stored UUID no longer appears in the list, treat as null.
    final safeValue = value != null && accounts.any((a) => a.uuid == value)
        ? value
        : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(errorText: error),
      hint: Text(AppStrings.selectAccount),
      items: accounts
          .map((a) => DropdownMenuItem(value: a.uuid, child: Text(a.name)))
          .toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Image picker section
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ImagePickerSection extends StatelessWidget {
  const _ImagePickerSection({
    required this.imagePath,
    required this.onPickTap,
    required this.onRemove,
  });

  final String? imagePath;
  final VoidCallback onPickTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.attach_file_outlined, size: 18),
          label: Text(AppStrings.addPhoto),
          onPressed: onPickTap,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(imagePath!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(AppStrings.changePhoto),
            onPressed: onPickTap,
          ),
        ),
      ],
    );
  }
}

