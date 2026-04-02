import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../services/audio_handler.dart';
import '../services/local_music_service.dart';
import '../providers/timer_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:uuid/uuid.dart';

/// 内置音效数据
class _AmbientSound {
  final String name;
  final String subtitle;
  final IconData icon;
  final String url;
  final Color accentColor;

  const _AmbientSound({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.url,
    required this.accentColor,
  });
}

const _builtInSounds = [
  _AmbientSound(
    name: '雨声',
    subtitle: '轻柔的雨滴',
    icon: Icons.water_drop_rounded,
    url: 'assets/audio/rain.mp3',
    accentColor: Color(0xFF4A90E2),
  ),
  _AmbientSound(
    name: '海浪',
    subtitle: '潮起潮落',
    icon: Icons.waves_rounded,
    url: 'assets/audio/ocean.mp3',
    accentColor: Color(0xFF26C6DA),
  ),
  _AmbientSound(
    name: '颂钵',
    subtitle: '冥想颂钵共鸣',
    icon: Icons.music_note_rounded,
    url: 'assets/audio/bowl.mp3',
    accentColor: Color(0xFFFFB74D),
  ),
  _AmbientSound(
    name: '森林',
    subtitle: '鸟鸣与风声',
    icon: Icons.forest_rounded,
    url: 'assets/audio/forests.mp3',
    accentColor: Color(0xFF66BB6A),
  ),
];

class AudioPickerSheet extends StatefulWidget {
  final AudioPlayerHandler audioHandler;

  const AudioPickerSheet({Key? key, required this.audioHandler}) : super(key: key);

  static void show(BuildContext context, AudioPlayerHandler handler) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AudioPickerSheet(audioHandler: handler),
    );
  }

  @override
  State<AudioPickerSheet> createState() => _AudioPickerSheetState();
}

class _AudioPickerSheetState extends State<AudioPickerSheet> {
  bool _isLoading = false;
  String? _currentPlaying; // 当前播放的标识（内置音效名称或本地文件路径）

  @override
  void initState() {
    super.initState();
    // 从 TimerProvider 恢复当前播放状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerProvider = context.read<TimerProvider>();
      if (timerProvider.selectedAudioPath != null) {
        setState(() {
          _currentPlaying = timerProvider.selectedAudioName ?? timerProvider.selectedAudioPath;
        });
      }
    });
  }

  Future<void> _playBuiltIn(_AmbientSound sound) async {
    final timerProvider = context.read<TimerProvider>();
    try {
      setState(() {
        _isLoading = true;
        _currentPlaying = sound.name;
      });
      await widget.audioHandler.loadCustomAudio(
        sound.url,
        isLocal: false, // isLocal is false so it doesn't extract file name as online resource, but audio handler knows it's an asset
        displayName: sound.name,
      );
      widget.audioHandler.play();
      timerProvider.selectAudio(sound.url, name: sound.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('播放失败: ${sound.name}'),
            backgroundColor: AppColors.surface2,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _playLocalMusic(LocalMusicItem music) async {
    final timerProvider = context.read<TimerProvider>();
    try {
      setState(() {
        _isLoading = true;
        _currentPlaying = music.path;
      });
      await widget.audioHandler.loadCustomAudio(
        music.path,
        isLocal: true,
        displayName: music.name,
      );
      widget.audioHandler.play();
      timerProvider.selectAudio(music.path, name: music.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('播放失败: ${music.name}'),
            backgroundColor: AppColors.surface2,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLocalFile() async {
    final timerProvider = context.read<TimerProvider>();
    final localMusicService = context.read<LocalMusicService>();
    try {
      setState(() => _isLoading = true);
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        final tempPath = result.files.single.path!;
        final originalName = result.files.single.name;
        final appDocDir = await getApplicationDocumentsDirectory();
        final ext = tempPath.split('.').last;
        final newFileName = 'audio_${const Uuid().v4()}.$ext';
        final newPath = '${appDocDir.path}/$newFileName';

        final File tempFile = File(tempPath);
        final File newFile = await tempFile.copy(newPath);

        // 持久化记录
        await localMusicService.addMusic(newFile.path, originalName);

        await widget.audioHandler.loadCustomAudio(
          newFile.path,
          isLocal: true,
          displayName: originalName,
        );
        widget.audioHandler.play();
        timerProvider.selectAudio(newFile.path, name: originalName);

        if (mounted) {
          setState(() => _currentPlaying = newFile.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('文件选择失败'),
            backgroundColor: AppColors.surface2,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLocalMusic(LocalMusicItem music) async {
    final localMusicService = context.read<LocalMusicService>();
    final timerProvider = context.read<TimerProvider>();

    // 如果正在播放这个文件，先停止
    if (_currentPlaying == music.path) {
      await _stopAudio();
    }

    await localMusicService.removeMusic(music.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除: ${music.name}'),
          backgroundColor: AppColors.surface2,
        ),
      );
    }
  }

  Future<void> _stopAudio() async {
    await widget.audioHandler.stop();
    if (mounted) {
      context.read<TimerProvider>().selectAudio('');
      setState(() => _currentPlaying = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.primary.withOpacity(0.15)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 固定头部
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                // 拖拽条
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // 标题栏
                Row(
                  children: [
                    Text('背景音乐', style: AppTypography.headlineSmall),
                    const Spacer(),
                    if (_currentPlaying != null)
                      GestureDetector(
                        onTap: _stopAudio,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.12),
                            borderRadius: AppRadius.pillBorder,
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stop_rounded,
                                  color: AppColors.error, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '停止',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('选择冥想背景音，沉浸其中', style: AppTypography.bodySmall),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // 可滚动内容
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20, 0, 20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── 内置音效网格 ───
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: _builtInSounds.map((sound) {
                        final isPlaying = _currentPlaying == sound.name;
                        return _buildSoundCard(sound, isPlaying);
                      }).toList(),
                    ),

                  const SizedBox(height: 20),

                  // ─── 已导入音乐区域 ───
                  _buildLocalMusicSection(),

                  const SizedBox(height: 16),

                  // ─── 导入本地文件按钮 ───
                  GestureDetector(
                    onTap: _pickLocalFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '导入本地音频文件',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 本地音乐管理区域
  Widget _buildLocalMusicSection() {
    return Consumer<LocalMusicService>(
      builder: (context, musicService, child) {
        if (musicService.items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分区标题
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '已导入音乐',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${musicService.items.length} 首',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 音乐列表
            ...musicService.items.map((music) {
              final isPlaying = _currentPlaying == music.path;
              return _buildLocalMusicItem(music, isPlaying);
            }),
          ],
        );
      },
    );
  }

  /// 单个本地音乐项
  Widget _buildLocalMusicItem(LocalMusicItem music, bool isPlaying) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _playLocalMusic(music),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isPlaying
                ? AppColors.accent.withOpacity(0.1)
                : AppColors.surface2.withOpacity(0.4),
            borderRadius: AppRadius.mdBorder,
            border: Border.all(
              color: isPlaying
                  ? AppColors.accent.withOpacity(0.35)
                  : AppColors.surface3.withOpacity(0.3),
              width: isPlaying ? 1.2 : 0.5,
            ),
          ),
          child: Row(
            children: [
              // 图标
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isPlaying
                      ? AppColors.accent.withOpacity(0.15)
                      : AppColors.surface3.withOpacity(0.5),
                  borderRadius: AppRadius.smBorder,
                ),
                child: Icon(
                  isPlaying
                      ? Icons.equalizer_rounded
                      : Icons.audiotrack_rounded,
                  color: isPlaying ? AppColors.accent : AppColors.textTertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // 文件名
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      music.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isPlaying
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isPlaying)
                      Text(
                        '正在播放',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accent.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),

              // 播放指示器
              if (isPlaying)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildPlayingIndicator(AppColors.accent),
                ),

              // 删除按钮
              GestureDetector(
                onTap: () => _confirmDelete(music),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: AppRadius.smBorder,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error.withOpacity(0.6),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 删除确认
  void _confirmDelete(LocalMusicItem music) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          '删除音乐',
          style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          '确定要删除 "${music.name}" 吗？\n文件将被永久删除。',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '取消',
              style: AppTypography.labelLarge.copyWith(color: AppColors.textTertiary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteLocalMusic(music);
            },
            child: Text(
              '删除',
              style: AppTypography.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundCard(_AmbientSound sound, bool isPlaying) {
    return GestureDetector(
      onTap: () => _playBuiltIn(sound),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPlaying
              ? sound.accentColor.withOpacity(0.12)
              : AppColors.surface2.withOpacity(0.4),
          borderRadius: AppRadius.lgBorder,
          border: Border.all(
            color: isPlaying
                ? sound.accentColor.withOpacity(0.4)
                : AppColors.surface3.withOpacity(0.4),
            width: isPlaying ? 1.5 : 0.5,
          ),
          boxShadow: isPlaying
              ? [
                  BoxShadow(
                    color: sound.accentColor.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: sound.accentColor.withOpacity(0.15),
                    borderRadius: AppRadius.smBorder,
                  ),
                  child: Icon(
                    sound.icon,
                    color: sound.accentColor,
                    size: 20,
                  ),
                ),
                if (isPlaying)
                  _buildPlayingIndicator(sound.accentColor),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sound.name,
                  style: AppTypography.titleMedium.copyWith(
                    color: isPlaying ? sound.accentColor : AppColors.textPrimary,
                  ),
                ),
                Text(
                  sound.subtitle,
                  style: AppTypography.caption.copyWith(
                    color: isPlaying
                        ? sound.accentColor.withOpacity(0.7)
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayingIndicator(Color color) {
    return Row(
      children: List.generate(3, (i) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + i * 100),
          width: 3,
          height: 8.0 + (i % 2 == 0 ? 6 : 0),
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
