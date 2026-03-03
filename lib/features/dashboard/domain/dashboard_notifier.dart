import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/repository_providers.dart';
import 'dashboard_state.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// DashboardNotifier
///
/// [AsyncNotifier<DashboardState>] — the single source of truth for the
/// Dashboard screen.
///
/// Responsibilities:
///  1. Fetch aggregated data from [TransactionRepository] and [AccountRepository].
///  2. Build type-safe [FlSpot] list for fl_chart.
///  3. Expose [changeMonth] so the user can navigate months.
///  4. Expose [refresh] for pull-to-refresh.
///
/// The notifier NEVER writes to the DB — that is the job of
/// [TransactionFormNotifier]. After a write the calling notifier calls
/// [ref.invalidate(dashboardNotifierProvider)] to trigger a rebuild.
/// ─────────────────────────────────────────────────────────────────────────
class DashboardNotifier extends AsyncNotifier<DashboardState> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Future<DashboardState> build() => _load(_selectedMonth);

  // ── Public interactions ────────────────────────────────────────────────────

  /// Navigates to the previous or next month.
  Future<void> changeMonth(DateTime month) async {
    _selectedMonth = month;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(month));
  }

  /// Pull-to-refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(_selectedMonth));
  }

  // ── Private loader ─────────────────────────────────────────────────────────

  Future<DashboardState> _load(DateTime month) async {
    final txRepo = ref.read(transactionRepositoryProvider);
    final acRepo = ref.read(accountRepositoryProvider);

    // ── Single Isar query for the month — reuse the list for all aggregations.
    final monthTxns = txRepo.getByMonth(month);

    final dailyTotals = txRepo.getDailyExpenseTotals(monthTxns, month);
    final income = txRepo.getMonthlyIncomeFromList(monthTxns);
    final expenses = txRepo.getMonthlyExpensesFromList(monthTxns);
    final totalBalance = acRepo.getTotalBalance();
    final accounts = acRepo.getAllActive();

    // Show the 5 most recent transactions for THIS month (not global).
    final recent = (monthTxns.length <= 5)
        ? monthTxns
        : monthTxns.sublist(0, 5); // already sorted desc by DashboardNotifier

    // Build FlSpot list: x = day of month (1-based), y = daily expense total.
    final spots = _buildChartSpots(dailyTotals);
    final maxY = _computeMaxY(dailyTotals);

    return DashboardState(
      chartSpots: spots,
      maxChartY: maxY,
      monthlyIncome: income,
      monthlyExpenses: expenses,
      totalBalance: totalBalance,
      recentTransactions: recent,
      accounts: accounts,
      selectedMonth: month,
    );
  }

  // ── Chart helpers ──────────────────────────────────────────────────────────

  /// Converts the day→amount map into [FlSpot]s.
  /// X-axis: 1 through 31 (day of month).
  /// Y-axis: daily expense total.
  List<FlSpot> _buildChartSpots(Map<DateTime, double> dailyTotals) {
    final List<FlSpot> spots = [];
    for (final entry in dailyTotals.entries) {
      spots.add(FlSpot(
        entry.key.day.toDouble(),
        entry.value,
      ));
    }
    // Ensure spots are sorted ascending by day for fl_chart.
    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  /// Returns the maxY for dynamic axis scaling.
  /// Pads by 20 % so the highest point is never clipped.
  double _computeMaxY(Map<DateTime, double> dailyTotals) {
    if (dailyTotals.isEmpty) return 100;
    final highest = dailyTotals.values.reduce((a, b) => a > b ? a : b);
    if (highest == 0) return 100;
    return (highest * 1.2).ceilToDouble();
  }
}

/// Provider registration — consumed by the Dashboard screen.
final dashboardNotifierProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);
