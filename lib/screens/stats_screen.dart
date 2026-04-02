import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meditation_provider.dart';
import '../models/daily_stats.dart';
import '../widgets/heatmap_widget.dart';
import '../widgets/stats_chart.dart';
import '../widgets/glassmorphic_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedTypeId;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Consumer<MeditationProvider>(
          builder: (context, provider, child) {
            int totalDurationAllTime = 0;
            int totalSessions = 0;

            final List<DailyStats> filteredStats =
                provider.dailyStats.map((stat) {
              if (_selectedTypeId == null) {
                totalDurationAllTime += stat.totalDurationSeconds;
                totalSessions += stat.sessionCount;
                return stat;
              } else {
                final typeDuration =
                    stat.typeBreakdown[_selectedTypeId!] ?? 0;
                totalDurationAllTime += typeDuration;
                if (typeDuration > 0) totalSessions++;
                return DailyStats(
                  date: stat.date,
                  totalDurationSeconds: typeDuration,
                  sessionCount: typeDuration > 0 ? 1 : 0,
                  typeBreakdown: {_selectedTypeId!: typeDuration},
                );
              }
            }).where((s) => s.totalDurationSeconds > 0).toList();

            // 计算连续天数
            final consecutiveDays = _calcConsecutiveDays(filteredStats);
            // 计算平均时长
            final avgMinutes = totalSessions > 0
                ? (totalDurationAllTime / totalSessions / 60).round()
                : 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              child: AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) => child!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── 页面标题 ───
                    Text('数据统计', style: AppTypography.headlineLarge),
                    const SizedBox(height: 8),
                    Text('你的冥想旅程', style: AppTypography.bodyMedium),
                    const SizedBox(height: 20),

                    // ─── 筛选标签 ───
                    _buildFilterChips(provider),
                    const SizedBox(height: 24),

                    // ─── 英雄数据卡 ───
                    _buildHeroStats(totalDurationAllTime, totalSessions,
                        consecutiveDays, avgMinutes),
                    const SizedBox(height: 32),

                    // ─── 热力图 ───
                    GlassmorphicCard(
                      padding: const EdgeInsets.all(16),
                      child: HeatmapWidget(dailyStats: filteredStats),
                    ),
                    const SizedBox(height: 24),

                    // ─── 趋势图 ───
                    GlassmorphicCard(
                      padding: const EdgeInsets.all(16),
                      child: StatsChart(dailyStats: filteredStats),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips(MeditationProvider provider) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip('全部', null, provider),
          ...provider.types.map((type) {
            return _buildChip(type.name, type.id, provider,
                dotColor: _parseColor(type.colorCode));
          }),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String? typeId, MeditationProvider provider,
      {Color? dotColor}) {
    final isSelected = _selectedTypeId == typeId;
    return GestureDetector(
      onTap: () => setState(() => _selectedTypeId = typeId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surface1.withOpacity(0.4),
          borderRadius: AppRadius.pillBorder,
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.surface3.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStats(
      int totalSeconds, int totalSessions, int consecutive, int avgMinutes) {
    final hours = totalSeconds / 3600.0;

    return Row(
      children: [
        Expanded(
          child: GlowGlassCard(
            glowColor: AppColors.primary,
            glowIntensity: 0.1,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('总时长', style: AppTypography.bodySmall),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: Text(
                        hours.toStringAsFixed(1),
                        style: AppTypography.statNumber.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('hours', style: AppTypography.unit),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlowGlassCard(
            glowColor: AppColors.accent,
            glowIntensity: 0.08,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('总次数', style: AppTypography.bodySmall),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      totalSessions.toString(),
                      style: AppTypography.statNumber.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('次', style: AppTypography.unit.copyWith(
                      color: AppColors.accent.withOpacity(0.6),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _calcConsecutiveDays(List<DailyStats> stats) {
    if (stats.isEmpty) return 0;
    final dates = stats.map((s) => s.date).toSet();
    final now = DateTime.now();
    int count = 0;
    for (int i = 0; i < 365; i++) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      if (dates.contains(dateStr)) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  Color _parseColor(String colorCode) {
    try {
      if (colorCode.startsWith('#')) {
        return Color(
            int.parse(colorCode.substring(1, 7), radix: 16) + 0xFF000000);
      }
      return AppColors.primary;
    } catch (e) {
      return AppColors.primary;
    }
  }
}
