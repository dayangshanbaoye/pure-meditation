import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_stats.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 增强版热力图 — 5级色阶 + Tooltip + 月份标签 + 入场动画
class HeatmapWidget extends StatefulWidget {
  final List<DailyStats> dailyStats;

  const HeatmapWidget({Key? key, required this.dailyStats}) : super(key: key);

  @override
  State<HeatmapWidget> createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends State<HeatmapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  OverlayEntry? _tooltipOverlay;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _tooltipOverlay?.remove();
    super.dispose();
  }

  void _showTooltip(BuildContext context, GlobalKey key, String date, int duration) {
    _tooltipOverlay?.remove();
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final minutes = duration ~/ 60;
    final tooltipText = '$date\n${minutes > 0 ? "$minutes 分钟" : "无记录"}';

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 40,
        top: position.dy - 52,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface3,
              borderRadius: AppRadius.smBorder,
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              tooltipText,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_tooltipOverlay!);
    Future.delayed(const Duration(seconds: 2), () {
      _tooltipOverlay?.remove();
      _tooltipOverlay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Assuming row 0 is Sunday, row 1 is Mon... align to Sunday.
    final int todayWeekday = today.weekday == 7 ? 0 : today.weekday;
    // 52 weeks means 51 full weeks + current week. 
    final startDate = today.subtract(Duration(days: todayWeekday + 51 * 7));

    final Map<String, int> statsMap = {};
    for (var stat in widget.dailyStats) {
      statsMap[stat.date] = stat.totalDurationSeconds;
    }

    final dateFormat = DateFormat('yyyy-MM-dd');
    final monthFormat = DateFormat('MMM');

    // 计算月份标签位置
    final List<_MonthLabel> monthLabels = [];
    int? lastMonth;
    for (int week = 0; week < 52; week++) {
      final dateInWeek = startDate.add(Duration(days: week * 7));
      if (dateInWeek.month != lastMonth) {
        monthLabels.add(_MonthLabel(
          label: monthFormat.format(dateInWeek),
          weekIndex: week,
        ));
        lastMonth = dateInWeek.month;
      }
    }

    const double cellSize = 15;
    const double cellSpacing = 3;
    const double weekdayLabelWidth = 28;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── 标题 ───
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text('冥想热力图', style: AppTypography.titleLarge),
            const Spacer(),
            Text('最近一年', style: AppTypography.bodySmall),
          ],
        ),
        const SizedBox(height: 16),

        // ─── 热力图主体 ───
        SizedBox(
          height: 7 * (cellSize + cellSpacing) + 24, // +24 for month labels
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 月份标签行
                SizedBox(
                  height: 18,
                  child: Row(
                    children: [
                      SizedBox(width: weekdayLabelWidth),
                      ...List.generate(52, (weekIndex) {
                        final label = monthLabels.firstWhere(
                          (m) => m.weekIndex == weekIndex,
                          orElse: () => _MonthLabel(label: '', weekIndex: -1),
                        );
                        return SizedBox(
                          width: cellSize + cellSpacing,
                          child: label.weekIndex >= 0
                              ? Text(
                                  label.label,
                                  style: AppTypography.caption.copyWith(fontSize: 9),
                                )
                              : null,
                        );
                      }),
                    ],
                  ),
                ),
                // 网格 + 星期标签
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 星期标签
                    SizedBox(
                      width: weekdayLabelWidth,
                      child: Column(
                        children: ['', 'Mon', '', 'Wed', '', 'Fri', ''].map((label) {
                          return SizedBox(
                            height: cellSize + cellSpacing,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                label,
                                style: AppTypography.caption.copyWith(fontSize: 9),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // 热力图网格
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        return Row(
                          children: List.generate(52, (weekIndex) {
                            return Column(
                              children: List.generate(7, (dayIndex) {
                                final dayOffset = (weekIndex * 7) + dayIndex;
                                final currentDay = startDate.add(Duration(days: dayOffset));
                                final dateStr = dateFormat.format(currentDay);
                                final duration = statsMap[dateStr] ?? 0;

                                if (currentDay.isAfter(today)) {
                                  return Container(
                                    width: cellSize,
                                    height: cellSize,
                                    margin: const EdgeInsets.all(cellSpacing / 2),
                                    color: Colors.transparent,
                                  );
                                }

                                // 瀑布式入场
                                final cellIndex = weekIndex * 7 + dayIndex;
                                final totalCells = 52 * 7;
                                final animStart = (cellIndex / totalCells) * 0.7;
                                final animEnd = (animStart + 0.3).clamp(0.0, 1.0);
                                final cellAnimation = CurvedAnimation(
                                  parent: _entranceController,
                                  curve: Interval(animStart, animEnd, curve: Curves.easeOut),
                                );

                                final cellKey = GlobalKey();

                                return GestureDetector(
                                  onTap: () => _showTooltip(
                                    context,
                                    cellKey,
                                    DateFormat('yyyy-MM-dd').format(currentDay),
                                    duration,
                                  ),
                                  child: FadeTransition(
                                    opacity: cellAnimation,
                                    child: Container(
                                      key: cellKey,
                                      width: cellSize,
                                      height: cellSize,
                                      margin: EdgeInsets.all(cellSpacing / 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.heatmapColor(duration),
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: duration > 1800
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.heatmapColor(duration)
                                                      .withOpacity(0.3),
                                                  blurRadius: 4,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          }),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),
        // ─── 图例 ───
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Less', style: AppTypography.caption),
            const SizedBox(width: 4),
            ...AppColors.heatmapLegendColors.map((color) => Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
            const SizedBox(width: 4),
            Text('More', style: AppTypography.caption),
          ],
        ),
      ],
    );
  }
}

class _MonthLabel {
  final String label;
  final int weekIndex;
  _MonthLabel({required this.label, required this.weekIndex});
}
