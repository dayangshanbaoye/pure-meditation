import 'package:flutter/material.dart';

/// 动效系统 — 统一的过渡动画与组件动效工厂
class AppAnimations {
  AppAnimations._();

  // ─── 标准曲线 ───
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve breathingCurve = Curves.easeInOutSine;
  static const Curve bounceCurve = Curves.elasticOut;

  // ─── 标准时长 ───
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration breathing = Duration(milliseconds: 2500);

  /// 淡入+上滑 入场动画
  static Widget fadeSlideIn({
    required Widget child,
    required Animation<double> animation,
    double offsetY = 20.0,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: defaultCurve,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, offsetY / 100),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: defaultCurve,
        )),
        child: child,
      ),
    );
  }

  /// 交错入场动画 — 用于列表/网格中的子项
  static Widget staggeredItem({
    required Widget child,
    required AnimationController controller,
    required int index,
    int totalItems = 10,
    double delayFactor = 0.06,
  }) {
    final begin = (index * delayFactor).clamp(0.0, 0.8);
    final end = (begin + 0.4).clamp(begin, 1.0);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: defaultCurve),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  /// 缩放弹跳动画
  static Widget scaleBounce({
    required Widget child,
    required Animation<double> animation,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: bounceCurve),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: defaultCurve),
        child: child,
      ),
    );
  }
}

/// 自定义页面路由过渡
class FadeSlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlideRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppAnimations.medium,
          reverseTransitionDuration: AppAnimations.fast,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: AppAnimations.defaultCurve,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: AppAnimations.defaultCurve,
                )),
                child: child,
              ),
            );
          },
        );
}
