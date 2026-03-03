import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/grouped_transactions_provider.dart';
import '../domain/transaction_list_notifier.dart';
import 'add_transaction_screen.dart';
import 'category_pie_chart_screen.dart';
import 'transaction_detail_screen.dart';
import 'widgets/transaction_tile.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// TransactionsScreen
///
/// Date-grouped transaction history.
/// Each group shows a date badge header with daily income/expense subtotals,
/// followed by a white card containing the transactions for that day.
///
/// Color coding: Emerald (income) · Rose (expense) · Slate-blue (transfer)
/// ─────────────────────────────────────────────────────────────────────────
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  void _openAddTransaction(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupedTransactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Riwayat Transaksi', style: AppTextStyles.labelLarge),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart_outline_rounded),
            tooltip: 'Analisis Kategori',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryPieChartScreen(
                  selectedMonth: DateTime(
                      DateTime.now().year, DateTime.now().month),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTransaction(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Tambah',
          style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
        ),
      ),
      body: groups.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'Belum ada transaksi.',
              subtitle: 'Ketuk + untuk menambahkan entri pertama.',
              actionLabel: 'Tambah Transaksi',
              onAction: () => _openAddTransaction(context),
            )
          : _GroupedList(groups: groups),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grouped list
// ─────────────────────────────────────────────────────────────────────────────

class _GroupedList extends ConsumerStatefulWidget {
  const _GroupedList({required this.groups});
  final List<TransactionGroup> groups;

  @override
  ConsumerState<_GroupedList> createState() => _GroupedListState();
}

class _GroupedListState extends ConsumerState<_GroupedList> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 4)),
        for (final group in widget.groups) ...[
          // ── Date badge header ─────────────────────────────────────────
          SliverToBoxAdapter(child: _DateHeader(group: group)),

          // ── Transaction card ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            sliver: SliverToBoxAdapter(
              child: _TransactionGroupCard(
                group: group,
                onTap: (tx) => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => TransactionDetailScreen(transaction: tx),
                ),
                onDelete: (tx) async {
                  final confirmed = await _confirmDelete(context);
                  if (confirmed != true) return;
                  await ref
                      .read(transactionListProvider.notifier)
                      .deleteTransaction(tx);
                  ref.invalidate(groupedTransactionsProvider);
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Hapus Transaksi'),
          content: const Text('Tindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Hapus', style: TextStyle(color: AppColors.expense)),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Date header — pill badge + daily subtotals
// ─────────────────────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.group});
  final TransactionGroup group;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          // Date badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              group.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          const Spacer(),
          // Income subtotal
          if (group.totalIncome > 0) ...[
            Text(
              '+${CurrencyFormatter.formatCompact(group.totalIncome)}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.income,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
          ],
          // Expense subtotal
          if (group.totalExpense > 0)
            Text(
              '-${CurrencyFormatter.formatCompact(group.totalExpense)}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.expense,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// White card containing all tiles for a single day
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionGroupCard extends StatelessWidget {
  const _TransactionGroupCard({
    required this.group,
    required this.onTap,
    required this.onDelete,
  });

  final TransactionGroup group;
  final void Function(dynamic tx) onTap;
  final Future<void> Function(dynamic tx) onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          for (int i = 0; i < group.transactions.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: borderColor,
                indent: 76,
                endIndent: 16,
              ),
            Dismissible(
              key: ValueKey(group.transactions[i].id),
              direction: DismissDirection.endToStart,
              background: _DeleteBackground(),
              confirmDismiss: (_) async {
                await onDelete(group.transactions[i]);
                return false;
              },
              child: TransactionTile(
                transaction: group.transactions[i],
                onTap: () => onTap(group.transactions[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipe delete background
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.expense,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      );
}
