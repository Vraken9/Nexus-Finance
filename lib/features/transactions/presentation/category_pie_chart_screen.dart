import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/providers/repository_providers.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// CategoryChartData – computed pie slice entry.
/// ─────────────────────────────────────────────────────────────────────────
class _ChartEntry {
  const _ChartEntry({
    required this.label,
    required this.amount,
    required this.color,
    required this.percent,
  });
  final String label;
  final double amount;
  final Color color;
  final double percent;
}

/// ─────────────────────────────────────────────────────────────────────────
/// CategoryPieChartScreen
///
/// Full-screen view showing income vs expense distribution by category
/// for the currently selected month. Togglable between Income / Expense.
/// ─────────────────────────────────────────────────────────────────────────
class CategoryPieChartScreen extends ConsumerStatefulWidget {
  const CategoryPieChartScreen({super.key, required this.selectedMonth});

  final DateTime selectedMonth;

  @override
  ConsumerState<CategoryPieChartScreen> createState() =>
      _CategoryPieChartScreenState();
}

class _CategoryPieChartScreenState
    extends ConsumerState<CategoryPieChartScreen> {
  String _type = 'expense'; // 'expense' | 'income'
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final txRepo = ref.watch(transactionRepositoryProvider);
    final catRepo = ref.watch(categoryRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final entries = _buildEntries(txRepo, catRepo);
    final total = entries.fold(0.0, (s, e) => s + e.amount);

    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Analisis Kategori',
          style: AppTextStyles.labelLarge.copyWith(color: textPrimary),
        ),
      ),
      body: Column(
        children: [
          // ── Type toggle ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _TypeTab(
                    label: 'Pengeluaran',
                    selected: _type == 'expense',
                    color: AppColors.expense,
                    onTap: () => setState(() {
                      _type = 'expense';
                      _touchedIndex = -1;
                    }),
                  ),
                  _TypeTab(
                    label: 'Pemasukan',
                    selected: _type == 'income',
                    color: AppColors.income,
                    onTap: () => setState(() {
                      _type = 'income';
                      _touchedIndex = -1;
                    }),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pie_chart_outline,
                            size: 64,
                            color: isDark
                                ? AppColors.textDisabledDark
                                : AppColors.textDisabled),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada data untuk bulan ini.',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: textSecondary),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      children: [
                        // ── Pie chart ────────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderColor),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 220,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        pieTouchData: PieTouchData(
                                          touchCallback: (event, response) {
                                            setState(() {
                                              if (!event.isInterestedForInteractions ||
                                                  response == null ||
                                                  response.touchedSection ==
                                                      null) {
                                                _touchedIndex = -1;
                                                return;
                                              }
                                              _touchedIndex = response
                                                  .touchedSection!
                                                  .touchedSectionIndex;
                                            });
                                          },
                                        ),
                                        borderData: FlBorderData(show: false),
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 60,
                                        sections: entries
                                            .asMap()
                                            .entries
                                            .map((e) => _buildSection(
                                                e.key, e.value))
                                            .toList(),
                                      ),
                                    ),
                                    // Center total label
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _touchedIndex >= 0 &&
                                                  _touchedIndex <
                                                      entries.length
                                              ? entries[_touchedIndex]
                                                  .percent
                                                  .toStringAsFixed(1)
                                              : '100',
                                          style: AppTextStyles.amountLarge
                                              .copyWith(
                                            color: _touchedIndex >= 0 &&
                                                    _touchedIndex <
                                                        entries.length
                                                ? entries[_touchedIndex].color
                                                : textPrimary,
                                            fontSize: 22,
                                          ),
                                        ),
                                        Text(
                                          '%',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(color: textSecondary),
                                        ),
                                        if (_touchedIndex >= 0 &&
                                            _touchedIndex < entries.length)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 2),
                                            child: Text(
                                              entries[_touchedIndex].label,
                                              style: AppTextStyles.labelSmall
                                                  .copyWith(
                                                color: textSecondary,
                                                fontSize: 10,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Total
                              Text(
                                'Total: ${CurrencyFormatter.format(total)}',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: textSecondary),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Legend / breakdown list ───────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderColor),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              thickness: 1,
                              color: borderColor,
                              indent: 60,
                              endIndent: 16,
                            ),
                            itemBuilder: (_, i) {
                              final e = entries[i];
                              final isSelected = i == _touchedIndex;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _touchedIndex =
                                      _touchedIndex == i ? -1 : i;
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  color: isSelected
                                      ? e.color.withAlpha(18)
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: e.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          e.label,
                                          style: AppTextStyles.labelMedium
                                              .copyWith(color: textPrimary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            CurrencyFormatter.formatCompact(
                                                e.amount),
                                            style: AppTextStyles.amountMedium
                                                .copyWith(
                                              color: e.color,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            '${e.percent.toStringAsFixed(1)}%',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                    color: textSecondary,
                                                    fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildSection(int index, _ChartEntry entry) {
    final isTouched = index == _touchedIndex;
    return PieChartSectionData(
      color: entry.color,
      value: entry.amount,
      title: isTouched ? '${entry.percent.toStringAsFixed(1)}%' : '',
      radius: isTouched ? 56 : 46,
      titleStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  List<_ChartEntry> _buildEntries(
    TransactionRepository txRepo,
    CategoryRepository catRepo,
  ) {
    final txns = txRepo
        .getByMonth(widget.selectedMonth)
        .where((t) => t.type == _type)
        .toList();

    if (txns.isEmpty) return [];

    final Map<String, double> byCategory = {};
    double uncategorized = 0;

    for (final tx in txns) {
      if (tx.categoryId != null && tx.categoryId!.isNotEmpty) {
        byCategory[tx.categoryId!] =
            (byCategory[tx.categoryId!] ?? 0) + tx.amount;
      } else {
        uncategorized += tx.amount;
      }
    }

    final total =
        byCategory.values.fold(0.0, (s, v) => s + v) + uncategorized;
    if (total == 0) return [];

    final List<_ChartEntry> entries = [];

    // Palette for categories
    const palette = [
      Color(0xFF6366F1),
      Color(0xFF06B6D4),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFFF43F5E),
      Color(0xFF3B82F6),
      Color(0xFFEC4899),
      Color(0xFF14B8A6),
      Color(0xFFEF4444),
    ];

    int colorIdx = 0;
    for (final kv in byCategory.entries) {
      final category = catRepo.getByUuid(kv.key);
      final colorHex = category?.colorHex;
      final color = colorHex != null
          ? Color(int.parse('FF$colorHex', radix: 16))
          : palette[colorIdx % palette.length];
      colorIdx++;
      entries.add(_ChartEntry(
        label: category?.name ?? 'Lainnya',
        amount: kv.value,
        color: color,
        percent: (kv.value / total) * 100,
      ));
    }

    if (uncategorized > 0) {
      entries.add(_ChartEntry(
        label: 'Tanpa Kategori',
        amount: uncategorized,
        color: AppColors.textDisabled,
        percent: (uncategorized / total) * 100,
      ));
    }

    // Sort by amount descending
    entries.sort((a, b) => b.amount.compareTo(a.amount));
    return entries;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Type tab button
// ─────────────────────────────────────────────────────────────────────────────

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: selected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
}

