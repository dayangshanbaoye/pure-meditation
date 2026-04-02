import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/daily_stats.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 增强版统计图表 — 渐变柱状图 + 发光折线 + 时间范围切换
class StatsChart extends StatefulWidget {
  final List<DailyStats> dailyStats;

  const StatsChart({Key? key, required this.dailyStats}) : super(key: key);

  @override
  State<StatsChart> createState() => _StatsChartState();
}

class _StatsChartState extends State<StatsChart> {
  int _daysRange = 7;
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final Map<String, int> statsMap = {
      for (var stat in widget.dailyStats) stat.date: stat.totalDurationSeconds
    };

    final dateFormat = DateFormat('yyyy-MM-dd');
    final shortFormat = _daysRange <= 7
        ? DateFormat('E', 'en')
        : DateFormat('MM/dd');

    List<BarChartGroupData> barGroups = [];
    List<FlSpot> lineSpots = [];
    double cumulative = 0;
    double maxBarValue = 0;

    for (int i = _daysRange - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = dateFormat.format(date);
      final duration = statsMap[dateStr] ?? 0;
      final durationMinutes = duration / 60.0;

      cumulative += durationMinutes;
      if (durationMinutes > maxBarValue) maxBarValue = durationMinutes;

      final x = _daysRange - 1 - i;

      barGroups.add(
        BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: durationMinutes,
              width: _daysRange <= 7 ? 20 : (_daysRange <= 14 ? 12 : 8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.primary.withOpacity(0.05),
                  AppColors.primary.withOpacity(0.6),
                ],
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxBarValue > 0 ? maxBarValue * 1.3 : 10,
                color: AppColors.surface1.withOpacity(0.3),
              ),
            ),
          ],
          showingTooltipIndicators: _touchedIndex == x ? [0] : [],
        ),
      );

      lineSpots.add(FlSpot(x.toDouble(), cumulative));
    }

    final double maxY = maxBarValue > 0 ? maxBarValue * 1.3 : 10.0;
    final double maxLinY = cumulative > 0 ? cumulative * 1.2 : 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── 标题 + 范围切换 ───
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text('冥想趋势', style: AppTypography.titleLarge),
            const Spacer(),
            _buildRangeChips(),
          ],
        ),
        const SizedBox(height: 24),

        // ─── 图表 ───
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              // 柱状图
              BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: barGroups,
                  maxY: maxY,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.surface2.withOpacity(0.5),
                      strokeWidth: 0.5,
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.surface3,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final mins = rod.toY.toStringAsFixed(0);
                        return BarTooltipItem(
                          '$mins 分钟',
                          AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      setState(() {
                        if (response != null && response.spot != null) {
                          _touchedIndex = response.spot!.touchedBarGroupIndex;
                        } else {
                          _touchedIndex = null;
                        }
                      });
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: maxY / 4,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            '${value.toInt()}m',
                            style: AppTypography.caption,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _daysRange <= 7 ? 1.0 : (_daysRange <= 14 ? 3.0 : 6.0),
                        getTitlesWidget: (value, meta) {
                          final dayIndex = value.toInt();
                          if (dayIndex < 0 || dayIndex >= _daysRange) {
                            return const SizedBox.shrink();
                          }
                          final date = today.subtract(
                              Duration(days: _daysRange - 1 - dayIndex));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              shortFormat.format(date),
                              style: AppTypography.caption,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // 折线图叠加
              Padding(
                padding: const EdgeInsets.only(left: 36), // 匹配 Y 轴标签宽度
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: lineSpots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: AppColors.accent,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: AppColors.accent,
                              strokeWidth: 1.5,
                              strokeColor: AppColors.bgPrimary,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.accent.withOpacity(0.15),
                              AppColors.accent.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    minY: 0,
                    maxY: maxLinY,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRangeChips() {
    return Row(
      children: [7, 14, 30].map((days) {
        final isSelected = _daysRange == days;
        return GestureDetector(
          onTap: () => setState(() => _daysRange = days),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: AppRadius.pillBorder,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.textTertiary.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Text(
              '${days}天',
              style: AppTypography.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
