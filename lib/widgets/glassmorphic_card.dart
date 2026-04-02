import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 可复用毛玻璃卡片组件
/// 灵感来自 Apple Vision Pro 设计语言与 Dribbble 2026 Wellness UI 趋势
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double blurRadius;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassmorphicCard({
    Key? key,
    required this.child,
    this.blurRadius = 12.0,
    this.opacity = 0.08,
    this.borderColor,
    this.borderWidth = 0.5,
    this.borderRadius,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.lgBorder;
    final effectiveBorderColor = borderColor ?? AppColors.primary.withOpacity(0.12);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: radius,
              color: AppColors.surface1.withOpacity(opacity),
              border: Border.all(
                color: effectiveBorderColor,
                width: borderWidth,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 带发光边框的毛玻璃卡片
class GlowGlassCard extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowIntensity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlowGlassCard({
    Key? key,
    required this.child,
    this.glowColor = AppColors.primary,
    this.glowIntensity = 0.15,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgBorder,
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(glowIntensity),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: GlassmorphicCard(
        borderColor: glowColor.withOpacity(0.2),
        padding: padding,
        child: child,
      ),
    );
  }
}
