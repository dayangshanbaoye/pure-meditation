import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/meditation_type.dart';
import '../models/meditation_record.dart';
import '../models/daily_stats.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static const String typesBoxName = 'meditation_types';
  static const String recordsBoxName = 'meditation_records';
  static const String statsBoxName = 'daily_stats';

  late Box<MeditationType> _typesBox;
  late Box<MeditationRecord> _recordsBox;
  late Box<DailyStats> _statsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(MeditationTypeAdapter());
    Hive.registerAdapter(MeditationRecordAdapter());
    Hive.registerAdapter(DailyStatsAdapter());

    // Open boxes
    _typesBox = await Hive.openBox<MeditationType>(typesBoxName);
    _recordsBox = await Hive.openBox<MeditationRecord>(recordsBoxName);
    _statsBox = await Hive.openBox<DailyStats>(statsBoxName);

    // Initialize default types if empty
    if (_typesBox.isEmpty) {
      await _initDefaultTypes();
    }
  }

  Future<void> _initDefaultTypes() async {
    final uuid = const Uuid();
    final defaultTypes = [
      MeditationType(id: uuid.v4(), name: '正念呼吸', colorCode: '#00FFC8'),
      MeditationType(id: uuid.v4(), name: '内观', colorCode: '#006D32'),
      MeditationType(id: uuid.v4(), name: '睡前放松', colorCode: '#4A90E2'),
    ];

    for (var type in defaultTypes) {
      await _typesBox.put(type.id, type);
    }
  }

  // === Types operations ===
  List<MeditationType> getAllTypes() {
    return _typesBox.values.toList();
  }

  Future<void> addType(MeditationType type) async {
    await _typesBox.put(type.id, type);
  }

  Future<void> updateType(MeditationType type) async {
    await _typesBox.put(type.id, type);
  }

  Future<void> deleteType(String id) async {
    await _typesBox.delete(id);
  }

  // === Records operations ===
  Future<void> addRecord(MeditationRecord record) async {
    await _recordsBox.put(record.id, record);
    await _updateDailyStats(record);
  }

  Future<void> deleteRecord(String id) async {
    final record = _recordsBox.get(id);
    if (record != null) {
      await _recordsBox.delete(id);
      // Ideally, we should also subtract this from DailyStats, but for simplicity
      // and rare use case of deletion, we recalculate or ignore.
      // Re-aggregating for that day would be safer.
      await _recalculateDailyStats(record.startTime);
    }
  }

  List<MeditationRecord> getAllRecords() {
    final records = _recordsBox.values.toList();
    records.sort((a, b) => b.startTime.compareTo(a.startTime));
    return records;
  }

  Future<void> updateRecord(MeditationRecord record, {DateTime? oldStartTime}) async {
    await _recordsBox.put(record.id, record);
    if (oldStartTime != null && _dateFormat.format(oldStartTime) != _dateFormat.format(record.startTime)) {
      await _recalculateDailyStats(oldStartTime);
    }
    await _recalculateDailyStats(record.startTime);
  }

  // === DailyStats aggregation logic ===
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  Future<void> _updateDailyStats(MeditationRecord record) async {
    final dateStr = _dateFormat.format(record.startTime);
    DailyStats? stats = _statsBox.get(dateStr);

    if (stats == null) {
      stats = DailyStats(
        date: dateStr,
        totalDurationSeconds: record.durationSeconds,
        sessionCount: 1,
        typeBreakdown: {record.typeId: record.durationSeconds},
      );
    } else {
      stats.totalDurationSeconds += record.durationSeconds;
      stats.sessionCount += 1;
      
      // We must copy the map or mutate it so Hive detects changes.
      // Hive specifically requires saving object reference or modifying fields directly
      // but modifying a map inside an object is fine if we save it back.
      final breakdown = Map<String, int>.from(stats.typeBreakdown);
      breakdown[record.typeId] = (breakdown[record.typeId] ?? 0) + record.durationSeconds;
      stats.typeBreakdown = breakdown;
      
    }
    await _statsBox.put(dateStr, stats);
  }

  Future<void> _recalculateDailyStats(DateTime date) async {
    final dateStr = _dateFormat.format(date);
    // Find all records for this date
    final dailyRecords = _recordsBox.values.where((r) => _dateFormat.format(r.startTime) == dateStr).toList();
    
    if (dailyRecords.isEmpty) {
      await _statsBox.delete(dateStr);
      return;
    }

    int totalDuration = 0;
    Map<String, int> breakdown = {};
    for (var r in dailyRecords) {
      totalDuration += r.durationSeconds;
      breakdown[r.typeId] = (breakdown[r.typeId] ?? 0) + r.durationSeconds;
    }

    final stats = DailyStats(
      date: dateStr,
      totalDurationSeconds: totalDuration,
      sessionCount: dailyRecords.length,
      typeBreakdown: breakdown,
    );
    await _statsBox.put(dateStr, stats);
  }

  List<DailyStats> getAllDailyStats() {
    return _statsBox.values.toList();
  }
}
