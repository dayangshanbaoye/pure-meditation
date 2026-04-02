import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../providers/meditation_provider.dart';
import '../services/audio_handler.dart';
import '../widgets/breathing_button.dart';
import '../widgets/audio_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _breathTextController;
  late Animation<double> _breathTextOpacity;

  @override
  void initState() {
    super.initState();

    // 呼吸引导文字动画
    _breathTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _breathTextOpacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _breathTextController, curve: Curves.easeInOutSine),
    );

    // 初始化选中类型
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerProvider = context.read<TimerProvider>();
      final medProvider = context.read<MeditationProvider>();
      if (timerProvider.selectedTypeId == null && medProvider.types.isNotEmpty) {
        timerProvider.selectType(medProvider.types.first.id);
      }
    });
  }

  @override
  void dispose() {
    _breathTextController.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // ─── 顶部操作栏 ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 音乐按钮
                  _buildMusicButton(),
                  // 类型选择器
                  _buildTypeSelector(),
                  const SizedBox(width: 48), // 占位平衡
                ],
              ),
            ),

            // ─── 中央冥想区域 ───
            Expanded(
              child: Consumer<TimerProvider>(
                builder: (context, timer, child) {
                  // 控制呼吸文字动画与冥想状态同步
                  if (timer.isRunning && !_breathTextController.isAnimating) {
                    _breathTextController.repeat(reverse: true);
                  } else if (!timer.isRunning && _breathTextController.isAnimating) {
                    _breathTextController.stop();
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 计时器显示
                      _buildTimerDisplay(timer),
                      const SizedBox(height: 16),
                      // 呼吸引导文字
                      _buildBreathingGuide(timer),
                      const SizedBox(height: 48),
                      // 呼吸按钮
                      BreathingButton(
                        isRunning: timer.isRunning,
                        onTap: () => _handleButtonTap(timer),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ─── 迷你播放控制条 ───
            _buildMiniPlayer(),

            const SizedBox(height: 100), // 底部导航栏空间
          ],
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(TimerProvider timer) {
    final text = _formatDuration(timer.elapsedSeconds);
    return ShaderMask(
      shaderCallback: (bounds) {
        if (!timer.isRunning) {
          return LinearGradient(
            colors: [AppColors.textPrimary, AppColors.textPrimary],
          ).createShader(bounds);
        }
        return const LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: AppTypography.timerDisplay.copyWith(
          color: Colors.white, // ShaderMask 需要白色
          shadows: timer.isRunning
              ? [
                  Shadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _buildBreathingGuide(TimerProvider timer) {
    if (!timer.isRunning) {
      return Text(
        '点击开始冥想',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _breathTextController,
      builder: (context, child) {
        final isInhale = _breathTextController.status == AnimationStatus.forward;
        return Opacity(
          opacity: _breathTextOpacity.value,
          child: Text(
            isInhale ? '吸气...' : '呼气...',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.primary.withOpacity(0.7),
              letterSpacing: 8,
              fontWeight: FontWeight.w300,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMusicButton() {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        final hasAudio = timerProvider.selectedAudioPath != null;
        return GestureDetector(
          onTap: () {
            final handler = context.read<AudioPlayerHandler>();
            AudioPickerSheet.show(context, handler);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasAudio
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface1.withOpacity(0.5),
              borderRadius: AppRadius.mdBorder,
              border: Border.all(
                color: hasAudio
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Icon(
              hasAudio ? Icons.music_note_rounded : Icons.music_off_rounded,
              color: hasAudio ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
          ),
        );
      },
    );
  }

  /// 迷你播放控制条
  Widget _buildMiniPlayer() {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        final audioName = timerProvider.selectedAudioName;
        if (audioName == null) return const SizedBox.shrink();

        final audioHandler = context.read<AudioPlayerHandler>();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: AppRadius.lgBorder,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface1.withOpacity(0.7),
                  borderRadius: AppRadius.lgBorder,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.12),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.05),
                      blurRadius: 16,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 音乐图标（带呼吸动画指示）
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: AppRadius.smBorder,
                      ),
                      child: const Icon(
                        Icons.equalizer_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 音楽名称
                    Expanded(
                      child: Text(
                        audioName,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // 播放/暂停按钮
                    StreamBuilder<bool>(
                      stream: audioHandler.playingStream,
                      initialData: audioHandler.isPlaying,
                      builder: (context, snapshot) {
                        final isPlaying = snapshot.data ?? false;
                        return GestureDetector(
                          onTap: () {
                            if (isPlaying) {
                              audioHandler.pause();
                            } else {
                              audioHandler.play();
                            }
                            // force rebuild
                            setState(() {});
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),

                    // 停止按钮
                    GestureDetector(
                      onTap: () async {
                        await audioHandler.stop();
                        timerProvider.selectAudio('');
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.stop_rounded,
                          color: AppColors.error.withOpacity(0.7),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSelector() {
    return Consumer2<MeditationProvider, TimerProvider>(
      builder: (context, medProvider, timerProvider, child) {
        if (medProvider.types.isEmpty) {
          return const SizedBox.shrink();
        }

        final selectedType = medProvider.types.firstWhere(
          (t) => t.id == timerProvider.selectedTypeId,
          orElse: () => medProvider.types.first,
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface1.withOpacity(0.5),
            borderRadius: AppRadius.pillBorder,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.12),
              width: 0.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: timerProvider.selectedTypeId ?? selectedType.id,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textTertiary, size: 18),
              dropdownColor: AppColors.surface2,
              style: AppTypography.labelLarge,
              isDense: true,
              borderRadius: AppRadius.lgBorder,
              items: medProvider.types.map((type) {
                return DropdownMenuItem<String>(
                  value: type.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _parseColor(type.colorCode),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _parseColor(type.colorCode).withOpacity(0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(type.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: timerProvider.isRunning
                  ? null
                  : (String? newId) {
                      if (newId != null) {
                        timerProvider.selectType(newId);
                      }
                    },
            ),
          ),
        );
      },
    );
  }

  void _handleButtonTap(TimerProvider timer) {
    if (timer.isRunning) {
      timer.stop();
      context.read<MeditationProvider>().reloadStats();
    } else {
      if (timer.selectedTypeId != null) {
        timer.start();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('请先选择冥想类型',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                )),
          ),
        );
      }
    }
  }

  Color _parseColor(String colorCode) {
    try {
      if (colorCode.startsWith('#')) {
        return Color(int.parse(colorCode.substring(1, 7), radix: 16) + 0xFF000000);
      }
      return AppColors.primary;
    } catch (e) {
      return AppColors.primary;
    }
  }
}
