import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/transaction_model.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// DashboardState
///
/// Immutable value object carrying all the data the Dashboard needs.
/// The [DashboardNotifier] produces one of these via [AsyncValue<DashboardState>].
///
/// [chartSpots]        – pre-computed [FlSpot] list for fl_chart (x = day index)
/// [maxChartY]         – highest daily expense; used for dynamic Y-axis scaling
/// [monthlyIncome]     – total income for [selectedMonth]
/// [monthlyExpenses]   – total expenses for [selectedMonth]
/// [recentTransactions]– last 5 transactions shown on the dashboard
/// [accounts]          – all active accounts for the Asset Quick-View row
/// [selectedMonth]     – the month currently displayed
/// ─────────────────────────────────────────────────────────────────────────
class DashboardState {
  const DashboardState({
    required this.chartSpots,
    required this.maxChartY,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.totalBalance,
    required this.recentTransactions,
    required this.accounts,
    required this.selectedMonth,
  });

  final List<FlSpot> chartSpots;
  final double maxChartY;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double totalBalance;
  final List<TransactionModel> recentTransactions;
  final List<AccountModel> accounts;
  final DateTime selectedMonth;

  double get netSavings => monthlyIncome - monthlyExpenses;

  /// Returns an empty state skeleton used while loading.
  factory DashboardState.empty(DateTime month) => DashboardState(
        chartSpots: const [],
        maxChartY: 100,
        monthlyIncome: 0,
        monthlyExpenses: 0,
        totalBalance: 0,
        recentTransactions: const [],
        accounts: const [],
        selectedMonth: month,
      );

  DashboardState copyWith({
    List<FlSpot>? chartSpots,
    double? maxChartY,
    double? monthlyIncome,
    double? monthlyExpenses,
    double? totalBalance,
    List<TransactionModel>? recentTransactions,
    List<AccountModel>? accounts,
    DateTime? selectedMonth,
  }) =>
      DashboardState(
        chartSpots: chartSpots ?? this.chartSpots,
        maxChartY: maxChartY ?? this.maxChartY,
        monthlyIncome: monthlyIncome ?? this.monthlyIncome,
        monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
        totalBalance: totalBalance ?? this.totalBalance,
        recentTransactions: recentTransactions ?? this.recentTransactions,
        accounts: accounts ?? this.accounts,
        selectedMonth: selectedMonth ?? this.selectedMonth,
      );
}
