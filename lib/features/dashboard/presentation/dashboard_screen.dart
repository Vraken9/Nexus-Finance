import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../transactions/presentation/widgets/transaction_tile.dart';
import '../domain/dashboard_notifier.dart';
import '../domain/dashboard_state.dart';
import 'widgets/asset_quick_view.dart';
import 'widgets/trend_chart.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// DashboardScreen
///
/// Elegant, minimalist home screen for Nexus Finance.
///
/// Layout:
///  1. Glassmorphism Financial Summary Hero Card
///     (Total Balance · Monthly Income · Monthly Expense)
///  2. Asset Quick-View – horizontal scroll of account balances
///  3. Spending Trend chart (fl_chart, smooth gradient)
///  4. Recent Transactions (last 5, grouped by type)
/// ─────────────────────────────────────────────────────────────────────────
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: asyncState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Error: $err', style: AppTextStyles.bodyMedium),
        ),
        data: (state) => _DashboardBody(state: state),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dashboardNotifierProvider.notifier);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: notifier.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            pinned: true,
            expandedHeight: 0,
            title: Text('Nexus Finance', style: AppTextStyles.labelLarge),
            actions: [
              // Month navigator – back
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: AppColors.textPrimary),
                onPressed: () => notifier.changeMonth(DateTime(
                  state.selectedMonth.year,
                  state.selectedMonth.month - 1,
                )),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Center(
                  child: Text(
                    DateHelpers.toMonthYear(state.selectedMonth),
                    style: AppTextStyles.labelMedium,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right,
                    color: AppColors.textPrimary),
                onPressed: () => notifier.changeMonth(DateTime(
                  state.selectedMonth.year,
                  state.selectedMonth.month + 1,
                )),
              ),
            ],
          ),

          // ── Hero glassmorphism card ────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _GlassHeroCard(state: state),
            ),
          ),

          // ── Asset Quick-View ──────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionHeader(title: 'Akun Saya'),
                ),
                const SizedBox(height: 14),
                const AssetQuickView(),
              ],
            ),
          ),

          // ── Spending Trend ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'Tren Pengeluaran',
                    subtitle: DateHelpers.toMonthYear(state.selectedMonth),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TrendChart(
                      spots: state.chartSpots,
                      maxY: state.maxChartY,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Recent Transactions ───────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: 'Transaksi Terkini'),
                  const SizedBox(height: 14),
                  if (state.recentTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          'Belum ada transaksi.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.recentTransactions.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                          indent: 76,
                          endIndent: 16,
                        ),
                        itemBuilder: (_, i) => TransactionTile(
                          transaction: state.recentTransactions[i],
                          showDate: true,
                        ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header — title + optional subtitle (e.g. month)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title, style: AppTextStyles.labelLarge),
        if (subtitle != null) ...[      
          const SizedBox(width: 8),
          Text(
            subtitle!,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textDisabled,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}

class _GlassHeroCard extends StatelessWidget {
  const _GlassHeroCard({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1E3A5F)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          // ── Decorative blurred circles ──────────────────────────────────
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(18),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -50,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(12),
              ),
            ),
          ),

          // ── Card content ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total balance label
                Text(
                  'Total Saldo',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white60,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                // Balance amount
                Text(
                  CurrencyFormatter.format(state.totalBalance),
                  style: AppTextStyles.amountHero.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                  ),
                ),

                const SizedBox(height: 20),

                // Glass divider
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      height: 1,
                      color: Colors.white.withAlpha(40),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Income / Expense row
                Row(
                  children: [
                    // Income
                    Expanded(
                      child: _GlassMiniStat(
                        icon: Icons.arrow_downward_rounded,
                        iconColor: AppColors.income,
                        label: 'Pemasukan',
                        amount: state.monthlyIncome,
                      ),
                    ),
                    // Vertical separator
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withAlpha(40),
                    ),
                    // Expense
                    Expanded(
                      child: _GlassMiniStat(
                        icon: Icons.arrow_upward_rounded,
                        iconColor: AppColors.expense,
                        label: 'Pengeluaran',
                        amount: state.monthlyExpenses,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Small stat row (income / expense) inside the hero card.
class _GlassMiniStat extends StatelessWidget {
  const _GlassMiniStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.formatCompact(amount),
                style: AppTextStyles.amountMedium.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
