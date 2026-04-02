import 'package:flutter/material.dart';

/// Pure Meditation 色彩系统
/// 参考: Tobias van Schneider 的深色 + 荧光配色、Calm App 的沉浸感
class AppColors {
  AppColors._();

  // ─── 基础背景色 ───
  static const Color bgDeep = Color(0xFF060A18);
  static const Color bgPrimary = Color(0xFF0A0E21);
  static const Color bgSecondary = Color(0xFF0F1428);
  static const Color bgTertiary = Color(0xFF151A33);

  // ─── 表面/卡片层级 ───
  static const Color surface1 = Color(0xFF1A1F3A);
  static const Color surface2 = Color(0xFF1E2545);
  static const Color surface3 = Color(0xFF252D52);
  static const Color surface4 = Color(0xFF2C365E);

  // ─── 主色 (荧光青渐变) ───
  static const Color primary = Color(0xFF00FFC8);
  static const Color primaryLight = Color(0xFF5BFFDB);
  static const Color primaryDark = Color(0xFF00CC9F);
  static const Color primaryMuted = Color(0xFF00996E);

  // ─── 辅助色 ───
  static const Color accent = Color(0xFFFFB74D);    // 暖琥珀
  static const Color accentSoft = Color(0x40FFB74D); // 低透明度

  // ─── 文字色阶 ───
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFFB0B3C5);
  static const Color textTertiary = Color(0xFF6B7099);
  static const Color textDisabled = Color(0xFF3D4266);

  // ─── 语义色 ───
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);

  // ─── 热力图色阶 (5级) ───
  static const Color heatmapEmpty = Color(0xFF111730);
  static const Color heatmapLevel1 = Color(0xFF0B3D28);
  static const Color heatmapLevel2 = Color(0xFF0E5A3A);
  static const Color heatmapLevel3 = Color(0xFF0F8050);
  static const Color heatmapLevel4 = Color(0xFF13A668);
  static const Color heatmapLevel5 = Color(0xFF00FFC8);

  static Color heatmapColor(int durationSeconds) {
    if (durationSeconds == 0) return heatmapEmpty;
    if (durationSeconds < 300) return heatmapLevel1;   // < 5 min
    if (durationSeconds < 600) return heatmapLevel2;   // 5-10 min
    if (durationSeconds < 1800) return heatmapLevel3;  // 10-30 min
    if (durationSeconds < 3600) return heatmapLevel4;  // 30-60 min
    return heatmapLevel5;                               // > 60 min
  }

  static List<Color> get heatmapLegendColors => [
    heatmapEmpty, heatmapLevel1, heatmapLevel2,
    heatmapLevel3, heatmapLevel4, heatmapLevel5,
  ];

  // ─── 渐变定义 ───
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgDeep, bgPrimary, bgSecondary],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x30253060),
      Color(0x18151A33),
    ],
  );

  static LinearGradient glowGradient(Color color) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      color.withOpacity(0.3),
      color.withOpacity(0.0),
    ],
  );

  // ─── 冥想类型调色板 ───
  static const List<String> typePalette = [
    '#00FFC8', '#00B4D8', '#7B61FF', '#FF6B9D',
    '#FFB74D', '#4CAF50', '#26C6DA', '#AB47BC',
    '#EF5350', '#78909C', '#FF8A65', '#66BB6A',
  ];
}
