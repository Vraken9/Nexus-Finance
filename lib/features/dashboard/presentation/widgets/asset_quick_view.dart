import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/account_model.dart';
import '../../../../shared/providers/repository_providers.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// AssetQuickView
///
/// Horizontally scrollable row showing every active account's name,
/// icon, and current balance.  One card per account — color-coded by type.
/// ─────────────────────────────────────────────────────────────────────────
class AssetQuickView extends ConsumerWidget {
  const AssetQuickView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountRepositoryProvider).getAllActive();

    if (accounts.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _AccountCard(account: accounts[i]),
      ),
    );
  }
}

// ── Single account card ───────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final AccountModel account;

  /// Accent color driven by account type string.
  Color get _accent => switch (account.type) {
        'bank' => const Color(0xFF2196F3),   // blue
        'card' => const Color(0xFFFF5722),   // deep-orange
        'ewallet' => const Color(0xFF9C27B0), // purple
        _ => const Color(0xFF4CAF50),         // green (cash / default)
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accent;

    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              IconData(account.iconCodePoint, fontFamily: 'MaterialIcons'),
              color: accent,
              size: 18,
            ),
          ),

          // Name + balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.formatCompact(account.balance),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
