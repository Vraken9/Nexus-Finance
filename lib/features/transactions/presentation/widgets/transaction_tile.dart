import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/asset_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../shared/providers/repository_providers.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// TransactionTile
///
/// Redesigned list tile for a single [TransactionModel].
///
/// Layout:
///   [Icon]  [Label / Subtitle]  [Amount / Time]
///
/// Income / Expense:
///   Label   = Category name (or generic fallback)
///   Subtitle = Asset type label (e.g., "Tunai", "Transfer")
///
/// Transfer:
///   Label    = "Transfer"
///   Subtitle = "Dari: FromAccount"
///   Sub-line = "Ke:    ToAccount"
///   (time shown right-aligned below amount as always)
///
/// Amount color: emerald (income) · rose (expense) · slate-blue (transfer)
/// ─────────────────────────────────────────────────────────────────────────
class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    /// When [showDate] is true, the subtitle shows the short date instead of
    /// asset/account info — used on the Dashboard's recent-transactions list.
    this.showDate = false,
  });

  final TransactionModel transaction;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = transaction;
    final catRepo = ref.watch(categoryRepositoryProvider);
    final acRepo = ref.watch(accountRepositoryProvider);

    // ── Resolve icon, accent, label, subtitle(s) ──────────────────────────
    final String label;
    final String subtitle;
    final String? subtitle2; // only for transfer: the "Ke: …" line
    final Color accentColor;
    final IconData iconData;

    if (tx.isTransfer) {
      final fromAccount =
          tx.fromAccountId != null ? acRepo.getByUuid(tx.fromAccountId!) : null;
      final toAccount =
          tx.toAccountId != null ? acRepo.getByUuid(tx.toAccountId!) : null;

      label = 'Transfer';
      if (showDate) {
        subtitle = DateHelpers.toShortDay(tx.date);
        subtitle2 = null;
      } else {
        subtitle = 'Dari: ${fromAccount?.name ?? '–'}';
        subtitle2 = 'Ke:    ${toAccount?.name ?? '–'}';
      }
      accentColor = AppColors.transfer;
      iconData = Icons.swap_horiz_rounded;
    } else {
      final category =
          tx.categoryId != null ? catRepo.getByUuid(tx.categoryId!) : null;
      label = category?.name ?? (tx.isIncome ? 'Pemasukan' : 'Pengeluaran');

      subtitle = showDate
          ? DateHelpers.toShortDay(tx.date)
          : (AssetType.fromStorageKey(tx.assetType)?.label ?? '');
      subtitle2 = null;

      final colorHex = category?.colorHex;
      accentColor = colorHex != null
          ? Color(int.parse('FF$colorHex', radix: 16))
          : (tx.isExpense ? AppColors.expense : AppColors.income);
      iconData = category != null
          ? IconData(category.iconCodePoint, fontFamily: 'MaterialIcons')
          : (tx.isExpense
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded);
    }

    // ── Amount ───────────────────────────────────────────────────────────────
    final amountText = tx.isTransfer
        ? CurrencyFormatter.format(tx.amount)
        : CurrencyFormatter.formatSigned(tx.amount, isExpense: tx.isExpense);

    final Color amountColor;
    if (tx.isTransfer) {
      amountColor = AppColors.transfer;
    } else if (tx.isExpense) {
      amountColor = AppColors.expense;
    } else {
      amountColor = AppColors.income;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Icon ──────────────────────────────────────────────────────
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accentColor.withAlpha(26),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(iconData, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),

            // ── Label + subtitles ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (subtitle2 != null && subtitle2.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle2,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // ── Amount + time ─────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  amountText,
                  style: AppTextStyles.amountMedium.copyWith(
                    color: amountColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateHelpers.toTime(tx.date),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textDisabled, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
