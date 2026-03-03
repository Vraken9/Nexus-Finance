import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// TrendChart
///
/// Renders the "Monthly Spending Trend" fl_chart [LineChart].
///
/// Key properties enforced by the spec:
///  • isCurved: true
///  • LinearGradient fill (Slate Blue → Transparent)
///  • Dynamic Y-axis scaling via [maxY]
///  • Touch tooltip showing date & amount
///  • X-axis shows every 5th day label (1, 5, 10, 15, 20, 25, 31)
/// ─────────────────────────────────────────────────────────────────────────
class TrendChart extends StatefulWidget {
  const TrendChart({
    super.key,
    required this.spots,
    required this.maxY,
    this.height = 200,
  });

  final List<FlSpot> spots;
  final double maxY;
  final double height;

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.spots.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No spending data this month.',
            style: AppTextStyles.bodySmall,
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: LineChart(_buildChartData()),
    );
  }

  LineChartData _buildChartData() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LineChartData(
      minX: 1,
      maxX: 31,
      minY: 0,
      maxY: widget.maxY,
      gridData: _buildGridData(isDark),
      borderData: FlBorderData(show: false),
      titlesData: _buildTitlesData(),
      lineTouchData: _buildTouchData(isDark),
      lineBarsData: [_buildLineBar(isDark)],
    );
  }

  // ── Line bar ──────────────────────────────────────────────────────────────

  LineChartBarData _buildLineBar(bool isDark) {
    final lineColor = isDark ? AppColors.chartLineDark : AppColors.chartLine;
    final dotSurface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final fillStart = isDark ? AppColors.chartFillStartDark : AppColors.chartFillStart;
    final fillEnd = isDark ? AppColors.chartFillEndDark : AppColors.chartFillEnd;
    return LineChartBarData(
      spots: widget.spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: lineColor,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) {
          final isTouched = index == _touchedIndex;
          return FlDotCirclePainter(
            radius: isTouched ? 6 : 3,
            color: isTouched ? AppColors.primary : dotSurface,
            strokeWidth: 2,
            strokeColor: lineColor,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillStart, fillEnd],
        ),
      ),
    );
  }

  // ── Grid ──────────────────────────────────────────────────────────────────

  FlGridData _buildGridData(bool isDark) {
    final interval = widget.maxY > 0 ? widget.maxY / 4 : 25.0;
    final gridColor = isDark ? AppColors.borderDark : AppColors.border;
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (_) => FlLine(
        color: gridColor,
        strokeWidth: 1,
        dashArray: [4, 4],
      ),
    );
  }

  // ── Titles ────────────────────────────────────────────────────────────────

  FlTitlesData _buildTitlesData() {
    final interval = widget.maxY > 0 ? widget.maxY / 4 : 25.0;
    return FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            interval: interval,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const SizedBox.shrink();
              return Text(
                CurrencyFormatter.formatCompact(value),
                style: AppTextStyles.bodySmall,
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 5,
            getTitlesWidget: (value, meta) {
              final day = value.toInt();
              if (![1, 5, 10, 15, 20, 25, 31].contains(day)) {
                return const SizedBox.shrink();
              }
              return Text(
                day.toString(),
                style: AppTextStyles.labelSmall,
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      );
  }

  // ── Touch ─────────────────────────────────────────────────────────────────

  LineTouchData _buildTouchData(bool isDark) => LineTouchData(
        handleBuiltInTouches: true,
        touchCallback: (event, response) {
          final spots = response?.lineBarSpots;
          if (spots == null || spots.isEmpty) {
            setState(() => _touchedIndex = -1);
            return;
          }
          setState(() {
            _touchedIndex = spots.first.spotIndex;
          });
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.primary,
          tooltipRoundedRadius: 10,
          getTooltipItems: (spots) => spots.map((spot) {
            return LineTooltipItem(
              'Day ${spot.x.toInt()}\n${CurrencyFormatter.format(spot.y)}',
              AppTextStyles.labelSmall.copyWith(color: Colors.white),
            );
          }).toList(),
        ),
      );
}
