import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  // ─── 向后兼容的顶层快捷引用 ───
  static const Color scaffoldBackgroundColor = AppColors.bgPrimary;
  static const Color primaryColor = AppColors.primary;
  static const Color accentColor = AppColors.primary;
  static const Color textColor = AppColors.textPrimary;
  static const Color secondaryTextColor = AppColors.textSecondary;
  static const Color cardColor = AppColors.surface1;

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgPrimary,
    primaryColor: AppColors.primary,
    fontFamily: AppTypography.fontFamilyBody,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface1,
      onPrimary: AppColors.bgDeep,
      onSecondary: AppColors.bgDeep,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamilyBody,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: AppColors.textSecondary),
    ),
    textTheme: const TextTheme(
      displayLarge: AppTypography.timerDisplay,
      headlineLarge: AppTypography.headlineLarge,
      headlineMedium: AppTypography.headlineMedium,
      headlineSmall: AppTypography.headlineSmall,
      titleLarge: AppTypography.titleLarge,
      titleMedium: AppTypography.titleMedium,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelSmall: AppTypography.labelSmall,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface1,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgBorder,
      ),
      margin: EdgeInsets.zero,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.bgDeep,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgBorder,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface2,
      contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface1,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
      titleTextStyle: AppTypography.headlineSmall,
      contentTextStyle: AppTypography.bodyMedium,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      modalBackgroundColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.surface3,
      thickness: 0.5,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.textSecondary,
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}
