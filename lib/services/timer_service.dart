import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/meditation_record.dart';
import 'storage_service.dart';

class TimerService {
  final StorageService _storageService;
  TimerService(this._storageService);

  static const String _startTimeKey = 'meditation_start_time';
  static const String _currentTypeIdKey = 'meditation_current_type_id';
  
  DateTime? _startTime;
  String? _currentTypeId;
  Timer? _uiTimer;
  
  // Callback to notify UI of tick updates
  VoidCallback? onTick;

  bool get isRunning => _startTime != null;
  
  int get elapsedSeconds {
    if (_startTime == null) return 0;
    return DateTime.now().difference(_startTime!).inSeconds;
  }

  Future<void> init() async {
    // Check if there's an ongoing meditation session from a previous cold boot
    final prefs = await SharedPreferences.getInstance();
    final startTimeStr = prefs.getString(_startTimeKey);
    final typeId = prefs.getString(_currentTypeIdKey);
    
    if (startTimeStr != null && typeId != null) {
      _startTime = DateTime.tryParse(startTimeStr);
      _currentTypeId = typeId;
      _startUiTimer();
    }
  }

  Future<void> start(String typeId) async {
    if (isRunning) return;

    _startTime = DateTime.now();
    _currentTypeId = typeId;

    // Persist to SharedPreferences for crash/kill recovery
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_startTimeKey, _startTime!.toIso8601String());
    await prefs.setString(_currentTypeIdKey, typeId);

    _startUiTimer();
  }

  Future<void> stop({String? musicUsed}) async {
    if (!isRunning) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime!).inSeconds;

    // Save record if duration is meaningful (e.g. > 10 seconds)
    // Here we save it regardless as per specs, or maybe > 10s is better,
    // but we stick to standard save.
    if (duration > 0) {
      final record = MeditationRecord(
        id: const Uuid().v4(),
        startTime: _startTime!,
        endTime: endTime,
        durationSeconds: duration,
        typeId: _currentTypeId!,
        musicUsed: musicUsed,
      );
      await _storageService.addRecord(record);
    }

    _cleanUp();
  }

  void _startUiTimer() {
    _uiTimer?.cancel();
    // This timer simply triggers UI rebuilds. It doesn't accumulate time.
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      onTick?.call();
    });
  }

  Future<void> _cleanUp() async {
    _uiTimer?.cancel();
    _uiTimer = null;
    _startTime = null;
    _currentTypeId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_startTimeKey);
    await prefs.remove(_currentTypeIdKey);
    
    onTick?.call();
  }

  // Force refresh elapsed time when app resumes
  void forceRefresh() {
    onTick?.call();
  }
}
