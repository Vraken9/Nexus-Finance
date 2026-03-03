import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/asset_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/models/transaction_model.dart';
import '../../../shared/providers/repository_providers.dart';
import '../domain/grouped_transactions_provider.dart';
import '../domain/transaction_list_notifier.dart';
import 'add_transaction_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// TransactionDetailScreen
///
/// A modal bottom sheet that displays full details of a [TransactionModel]
/// and provides Edit / Delete actions.
///
/// Usage:
///   showModalBottomSheet(
///     context: context,
///     isScrollControlled: true,
///     builder: (_) => TransactionDetailScreen(transaction: tx),
///   );
/// ─────────────────────────────────────────────────────────────────────────
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = transaction;
    final catRepo = ref.watch(categoryRepositoryProvider);
    final acRepo = ref.watch(accountRepositoryProvider);

    // ── Resolve type-specific data ─────────────────────────────────────────
    final Color accentColor;
    final IconData iconData;
    final String typeLabel;
    final String? categoryName;
    final String? assetLabel;
    final String? fromAccountName;
    final String? toAccountName;

    if (tx.isTransfer) {
      accentColor = AppColors.transfer;
      iconData = Icons.swap_horiz_rounded;
      typeLabel = 'Transfer';
      categoryName = null;
      assetLabel = null;
      fromAccountName =
          tx.fromAccountId != null ? acRepo.getByUuid(tx.fromAccountId!)?.name : null;
      toAccountName =
          tx.toAccountId != null ? acRepo.getByUuid(tx.toAccountId!)?.name : null;
    } else {
      final category =
          tx.categoryId != null ? catRepo.getByUuid(tx.categoryId!) : null;
      final colorHex = category?.colorHex;
      accentColor = colorHex != null
          ? Color(int.parse('FF$colorHex', radix: 16))
          : (tx.isExpense ? AppColors.expense : AppColors.income);
      iconData = category != null
          ? IconData(category.iconCodePoint, fontFamily: 'MaterialIcons')
          : (tx.isExpense
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded);
      typeLabel = tx.isIncome ? 'Pemasukan' : 'Pengeluaran';
      categoryName = category?.name;
      assetLabel = AssetType.fromStorageKey(tx.assetType)?.label;
      fromAccountName = null;
      toAccountName = null;
    }

    final amountColor = tx.isTransfer
        ? AppColors.transfer
        : (tx.isExpense ? AppColors.expense : AppColors.income);

    final amountText = tx.isTransfer
        ? CurrencyFormatter.format(tx.amount)
        : CurrencyFormatter.formatSigned(tx.amount, isExpense: tx.isExpense);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ───────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ── Hero section: icon + amount ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(iconData, color: accentColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          typeLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Amount
                      Text(
                        amountText,
                        style: AppTextStyles.amountLarge.copyWith(
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Divider ────────────────────────────────────────────────────
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.borderDark
                : AppColors.border,
          ),

          // ── Detail rows ────────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                children: [
                  // Date & Time
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tanggal',
                    value: DateHelpers.toShortDay(tx.date),
                  ),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Waktu',
                    value: DateHelpers.toTime(tx.date),
                  ),

                  // Category (income / expense only)
                  if (categoryName != null)
                    _DetailRow(
                      icon: Icons.label_outline_rounded,
                      label: 'Kategori',
                      value: categoryName,
                      valueColor: accentColor,
                    ),

                  // Asset type (income / expense only)
                  if (assetLabel != null && assetLabel.isNotEmpty)
                    _DetailRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Metode',
                      value: assetLabel,
                    ),

                  // Transfer accounts
                  if (fromAccountName != null)
                    _DetailRow(
                      icon: Icons.logout_rounded,
                      label: 'Dari Akun',
                      value: fromAccountName,
                    ),
                  if (toAccountName != null)
                    _DetailRow(
                      icon: Icons.login_rounded,
                      label: 'Ke Akun',
                      value: toAccountName,
                    ),

                  // Transfer fee
                  if (tx.isTransfer && tx.transferFee > 0)
                    _DetailRow(
                      icon: Icons.info_outline_rounded,
                      label: 'Biaya Transfer',
                      value: CurrencyFormatter.format(tx.transferFee),
                      valueColor: AppColors.expense,
                    ),

                  // Note
                  if (tx.note != null && tx.note!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Catatan',
                      value: tx.note!,
                    ),

                  // Attachment text
                  if (tx.attachmentText != null &&
                      tx.attachmentText!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.attach_file_rounded,
                      label: 'Lampiran',
                      value: tx.attachmentText!,
                    ),

                  // Photo attachment
                  if (tx.imagePath != null && tx.imagePath!.isNotEmpty)
                    _ImageDetailSection(imagePath: tx.imagePath!),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Actions ────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
                24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: Row(
              children: [
                // Delete button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, ref),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Hapus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.expense,
                      side: const BorderSide(color: AppColors.expense),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Edit button
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openEdit(context),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _openEdit(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(editModel: transaction),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Transaksi'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref
        .read(transactionListProvider.notifier)
        .deleteTransaction(transaction);
    ref.invalidate(groupedTransactionsProvider);
    if (context.mounted) Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail row widget
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final labelColor = isDark ? AppColors.textDisabledDark : AppColors.textDisabled;
    final valueCol = valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: labelColor, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTextStyles.labelMedium.copyWith(
                        color: valueCol, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image detail section
// ─────────────────────────────────────────────────────────────────────────────

class _ImageDetailSection extends StatelessWidget {
  const _ImageDetailSection({required this.imagePath});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    if (!file.existsSync()) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image_outlined,
                    size: 17, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 14),
              Text(
                'Foto',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textDisabled, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showFullImage(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                file,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Foto Transaksi'),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(imagePath)),
            ),
          ),
        ),
      ),
    );
  }
}

