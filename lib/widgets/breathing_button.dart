import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// 多层呼吸光环按钮
/// 灵感: Apple Watch 呼吸动画 + Calm App 的沉浸式按钮设计
class BreathingButton extends StatefulWidget {
  final bool isRunning;
  final VoidCallback onTap;

  const BreathingButton({
    Key? key,
    required this.isRunning,
    required this.onTap,
  }) : super(key: key);

  @override
  State<BreathingButton> createState() => _BreathingButtonState();
}

class _BreathingButtonState extends State<BreathingButton>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _rippleController;
  late AnimationController _iconController;

  late Animation<double> _breathScale;
  late Animation<double> _ring1Scale;
  late Animation<double> _ring2Scale;
  late Animation<double> _ring1Opacity;
  late Animation<double> _ring2Opacity;
  late Animation<double> _rippleScale;
  late Animation<double> _rippleOpacity;

  @override
  void initState() {
    super.initState();

    // 主呼吸控制器 — 5秒一个循环 (2.5s 吸气 + 2.5s 呼气)
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 涟漪控制器 — 点击时触发
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 图标过渡控制器
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // ─── 呼吸动画 ───
    _breathScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );

    // 中圈 — 延迟跟随
    _ring1Scale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeInOutSine),
      ),
    );
    _ring1Opacity = Tween<double>(begin: 0.25, end: 0.5).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );

    // 外圈 — 更大延迟
    _ring2Scale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOutSine),
      ),
    );
    _ring2Opacity = Tween<double>(begin: 0.1, end: 0.3).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );

    // ─── 涟漪动画 ───
    _rippleScale = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
    _rippleOpacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    if (widget.isRunning) {
      _breathController.repeat(reverse: true);
      _iconController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant BreathingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _breathController.repeat(reverse: true);
        _iconController.forward();
      } else {
        _breathController.animateTo(0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut);
        _iconController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _rippleController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _rippleController.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathController, _rippleController, _iconController]),
        builder: (context, child) {
          final isActive = widget.isRunning;
          final coreScale = isActive ? _breathScale.value : 1.0;
          final r1Scale = isActive ? _ring1Scale.value : 1.0;
          final r2Scale = isActive ? _ring2Scale.value : 1.0;
          final r1Opacity = isActive ? _ring1Opacity.value : 0.15;
          final r2Opacity = isActive ? _ring2Opacity.value : 0.06;

          return SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ─── 涟漪扩散 (点击时) ───
                if (_rippleController.isAnimating)
                  Transform.scale(
                    scale: _rippleScale.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(_rippleOpacity.value),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                // ─── 外圈光晕 ───
                Transform.scale(
                  scale: r2Scale,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(r2Opacity * 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(r2Opacity * 0.3),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── 中圈光晕 ───
                Transform.scale(
                  scale: r1Scale,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(r1Opacity * 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(r1Opacity * 0.4),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── 核心按钮 ───
                GestureDetector(
                  onTap: _handleTap,
                  child: Transform.scale(
                    scale: coreScale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(isActive ? 0.25 : 0.12),
                            AppColors.primaryDark.withOpacity(isActive ? 0.15 : 0.06),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(isActive ? 0.8 : 0.5),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(isActive ? 0.4 : 0.15),
                            blurRadius: isActive ? 20 : 10,
                            spreadRadius: isActive ? 4 : 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return RotationTransition(
                              turns: Tween(begin: 0.75, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            key: ValueKey(isActive),
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
