import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

Future<AudioPlayerHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.puremeditation.audio',
      androidNotificationChannelName: 'Pure Meditation Audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  /// 当前音源名称（用于 UI 显示）
  String _currentSourceName = '';
  String get currentSourceName => _currentSourceName;

  /// 是否正在播放
  bool get isPlaying => _player.playing;

  /// 播放状态变化流（用于 UI 实时更新）
  Stream<bool> get playingStream => _player.playingStream;

  /// 播放器处理状态流
  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;

  AudioPlayerHandler() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  Future<void> loadCustomAudio(String urlOrPath,
      {required bool isLocal, String? displayName}) async {
    _currentSourceName = displayName ?? (isLocal ? _extractFileName(urlOrPath) : "在线音效");
    final item = MediaItem(
      id: urlOrPath,
      album: "Pure Meditation",
      title: _currentSourceName,
    );
    mediaItem.add(item);

    if (urlOrPath.startsWith('assets/')) {
      await _player.setAsset(urlOrPath);
    } else if (isLocal) {
      await _player.setFilePath(urlOrPath);
    } else {
      await _player.setUrl(urlOrPath);
    }
    await _player.setLoopMode(LoopMode.one);
  }

  String _extractFileName(String path) {
    final name = path.split('/').last.split('\\').last;
    // 去掉 uuid 前缀 (audio_xxxxx.mp3 -> 文件名)
    if (name.startsWith('audio_') && name.length > 43) {
      return name.substring(43); // skip 'audio_' + uuid (36 chars) + '.'
    }
    return name;
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    _currentSourceName = '';
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);
}
