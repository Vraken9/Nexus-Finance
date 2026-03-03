import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// SummaryCard
///
/// Displays a single KPI (income, expenses, or balance) inside a rounded
/// container with a colour-coded left accent bar.
///
/// [accentColor] should be [AppColors.income], [AppColors.expense], or
/// [AppColors.primary] depending on the metric.
/// ─────────────────────────────────────────────────────────────────────────
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.accentColor,
    this.isNegative = false,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color accentColor;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Colour dot / icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(26), // 10 % opacity
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelSmall),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(amount),
                  style: AppTextStyles.amountMedium.copyWith(
                    color: isNegative ? AppColors.expense : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
