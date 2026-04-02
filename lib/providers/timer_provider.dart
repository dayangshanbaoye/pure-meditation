import 'package:flutter/material.dart';
import '../services/timer_service.dart';

class TimerProvider extends ChangeNotifier with WidgetsBindingObserver {
  final TimerService _timerService;
  
  String? _selectedTypeId;
  String? _selectedAudioPath;
  String? _selectedAudioName;

  TimerProvider(this._timerService) {
    _timerService.onTick = notifyListeners;
    WidgetsBinding.instance.addObserver(this);
  }

  bool get isRunning => _timerService.isRunning;
  int get elapsedSeconds => _timerService.elapsedSeconds;
  
  String? get selectedTypeId => _selectedTypeId;
  String? get selectedAudioPath => _selectedAudioPath;
  String? get selectedAudioName => _selectedAudioName;

  void selectType(String typeId) {
    if (isRunning) return; // Cannot change type while running
    _selectedTypeId = typeId;
    notifyListeners();
  }

  void selectAudio(String path, {String? name}) {
    _selectedAudioPath = path.isEmpty ? null : path;
    _selectedAudioName = path.isEmpty ? null : name;
    notifyListeners();
  }

  Future<void> init() async {
    await _timerService.init();
    notifyListeners();
  }

  Future<void> start() async {
    if (_selectedTypeId == null) return;
    await _timerService.start(_selectedTypeId!);
    notifyListeners();
  }

  Future<void> stop() async {
    await _timerService.stop(musicUsed: _selectedAudioPath);
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Force UI refresh with accurate time diff when app comes to foreground
      if (isRunning) {
        _timerService.forceRefresh();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
