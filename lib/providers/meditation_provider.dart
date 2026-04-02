import 'package:flutter/foundation.dart';
import '../models/meditation_type.dart';
import '../models/meditation_record.dart';
import '../models/daily_stats.dart';
import '../services/storage_service.dart';

class MeditationProvider extends ChangeNotifier {
  final StorageService _storageService;

  List<MeditationType> _types = [];
  List<DailyStats> _dailyStats = [];
  List<MeditationRecord> _records = [];

  MeditationProvider(this._storageService);

  List<MeditationType> get types => _types;
  List<DailyStats> get dailyStats => _dailyStats;
  List<MeditationRecord> get records => _records;

  Future<void> loadData() async {
    _types = _storageService.getAllTypes();
    _dailyStats = _storageService.getAllDailyStats();
    _records = _storageService.getAllRecords();
    notifyListeners();
  }

  // Reload stats after a meditation session finishes
  Future<void> reloadStats() async {
    _dailyStats = _storageService.getAllDailyStats();
    _records = _storageService.getAllRecords();
    notifyListeners();
  }

  Future<void> addType(MeditationType type) async {
    await _storageService.addType(type);
    await loadData();
  }

  Future<void> updateType(MeditationType type) async {
    await _storageService.updateType(type);
    await loadData();
  }

  Future<void> deleteType(String id) async {
    await _storageService.deleteType(id);
    await loadData();
  }

  Future<void> addRecord(MeditationRecord record) async {
    await _storageService.addRecord(record);
    await reloadStats();
  }

  Future<void> deleteRecord(String id) async {
    await _storageService.deleteRecord(id);
    await reloadStats();
  }

  Future<void> updateRecord(MeditationRecord record, {DateTime? oldStartTime}) async {
    await _storageService.updateRecord(record, oldStartTime: oldStartTime);
    await reloadStats();
  }
}
