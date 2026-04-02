import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/daily_stats.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 增强版统计图表 — 渐变柱状图 + 发光折线 + 时间范围切换
enum ChartRange { week, month, year }

class StatsChart extends StatefulWidget {
  final List<DailyStats> dailyStats;

  const StatsChart({Key? key, required this.dailyStats}) : super(key: key);

  @override
  State<StatsChart> createState() => _StatsChartState();
}

class _StatsChartState extends State<StatsChart> {
  ChartRange _range = ChartRange.week;
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<BarChartGroupData> barGroups = [];
    List<FlSpot> lineSpots = [];
    double cumulative = 0;
    double maxBarValue = 0;
    int barsCount = 0;

    if (_range == ChartRange.week || _range == ChartRange.month) {
      barsCount = _range == ChartRange.week ? 7 : 30;
      final Map<String, int> statsMap = {
        for (var stat in widget.dailyStats) stat.date: stat.totalDurationSeconds
      };
      final dateFormat = DateFormat('yyyy-MM-dd');

      for (int i = barsCount - 1; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dateStr = dateFormat.format(date);
        final duration = statsMap[dateStr] ?? 0;
        final durationMinutes = duration / 60.0;

        cumulative += durationMinutes;
        if (durationMinutes > maxBarValue) maxBarValue = durationMinutes;

        final x = barsCount - 1 - i;

        barGroups.add(
          BarChartGroupData(
            x: x,
            barRods: [
              BarChartRodData(
                toY: durationMinutes,
                width: _range == ChartRange.week ? 20 : 8,
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
    } else {
      // Year view: 12 months
      barsCount = 12;
      for (int i = 11; i >= 0; i--) {
        int targetMonth = today.month - i;
        int targetYear = today.year;
        while (targetMonth <= 0) {
          targetMonth += 12;
          targetYear -= 1;
        }

        int monthlySecs = 0;
        for (var stat in widget.dailyStats) {
          try {
            final date = DateTime.parse(stat.date);
            if (date.year == targetYear && date.month == targetMonth) {
              monthlySecs += stat.totalDurationSeconds;
            }
          } catch (e) {
            // ignore parse errors
          }
        }

        final durationMinutes = monthlySecs / 60.0;
        cumulative += durationMinutes;
        if (durationMinutes > maxBarValue) maxBarValue = durationMinutes;

        final x = 11 - i;

        barGroups.add(
          BarChartGroupData(
            x: x,
            barRods: [
              BarChartRodData(
                toY: durationMinutes,
                width: 14,
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
                        final mins = rod.toY;
                        String text;
                        if (mins >= 120) {
                          text = '${(mins / 60).toStringAsFixed(1)} 小时';
                        } else {
                          text = '${mins.toStringAsFixed(0)} 分钟';
                        }
                        return BarTooltipItem(
                          text,
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
                          
                          // Convert to hours if values are large (e.g. Year view)
                          if (maxY >= 120) {
                             if (value % 60 == 0 || value == (maxY / 4).ceilToDouble()) {
                                return Text(
                                  '${(value / 60).toStringAsFixed(1)}h',
                                  style: AppTypography.caption,
                                );
                             }
                          }
                          
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
                        interval: 1.0, 
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= barsCount) {
                            return const SizedBox.shrink();
                          }
                          
                          Widget textWidget(String text) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(text, style: AppTypography.caption),
                            );
                          }

                          if (_range == ChartRange.week) {
                            final date = today.subtract(Duration(days: 6 - idx));
                            return textWidget(DateFormat('E', 'en').format(date));
                          } else if (_range == ChartRange.month) {
                            // Show points to prevent overlap
                            if (idx == 0 || idx == 10 || idx == 20 || idx == 29) {
                              final date = today.subtract(Duration(days: 29 - idx));
                              return textWidget(DateFormat('M/d').format(date));
                            }
                          } else if (_range == ChartRange.year) {
                            // Show all 12 months, abbreviated
                            int targetMonth = today.month - (11 - idx);
                            while (targetMonth <= 0) targetMonth += 12;
                            const months = ['J','F','M','A','M','J','J','A','S','O','N','D'];
                            return textWidget(months[targetMonth - 1]);
                          }
                          return const SizedBox.shrink();
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
    final Map<ChartRange, String> rangeNames = {
      ChartRange.week: '周',
      ChartRange.month: '月',
      ChartRange.year: '年',
    };

    return Row(
      children: ChartRange.values.map((range) {
        final isSelected = _range == range;
        return GestureDetector(
          onTap: () => setState(() => _range = range),
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
              rangeNames[range]!,
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
