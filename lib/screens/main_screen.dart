import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'type_manage_screen.dart';
import 'stats_screen.dart';
import 'record_manage_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<_NavItem> _navItems;
  late final List<AnimationController> _bounceControllers;

  final List<Widget> _pages = [
    const HomeScreen(),
    const StatsScreen(),
    const RecordManageScreen(),
    const TypeManageScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _navItems = [
      _NavItem(icon: Icons.self_improvement_rounded, label: '冥想'),
      _NavItem(icon: Icons.insights_rounded, label: '统计'),
      _NavItem(icon: Icons.list_alt_rounded, label: '记录'),
      _NavItem(icon: Icons.palette_rounded, label: '类型'),
    ];

    _bounceControllers = List.generate(
      _navItems.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _bounceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    _bounceControllers[index].forward(from: 0);
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景渐变
          Container(decoration: const BoxDecoration(gradient: AppColors.backgroundGradient)),

          // 页面内容
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // 自定义底部导航
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 12,
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgDeep.withOpacity(0.7),
              border: const Border(
                top: BorderSide(
                  color: Color(0x15FFFFFF),
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final isSelected = i == _currentIndex;
                return _buildNavItem(i, isSelected);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isSelected) {
    final item = _navItems[index];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTap(index),
      child: AnimatedBuilder(
        animation: _bounceControllers[index],
        builder: (context, child) {
          final bounceValue = _bounceControllers[index].value;
          final scale = 1.0 + (bounceValue < 0.5
              ? bounceValue * 0.3
              : (1.0 - bounceValue) * 0.3);

          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 64,
              height: 56,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 选中指示器圆点
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 4 : 0,
                    height: isSelected ? 4 : 0,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x6000FFC8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  // 图标
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textTertiary,
                    ),
                    child: Icon(
                      item.icon,
                      color: isSelected ? AppColors.primary : AppColors.textTertiary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 标签
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamilyBody,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : AppColors.textTertiary,
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}
