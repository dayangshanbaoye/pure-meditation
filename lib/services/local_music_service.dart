import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地音乐记录
class LocalMusicItem {
  final String path;
  final String name;
  final String addedAt;

  LocalMusicItem({
    required this.path,
    required this.name,
    required this.addedAt,
  });

  Map<String, String> toJson() => {
        'path': path,
        'name': name,
        'addedAt': addedAt,
      };

  factory LocalMusicItem.fromJson(Map<String, dynamic> json) => LocalMusicItem(
        path: json['path'] as String,
        name: json['name'] as String,
        addedAt: json['addedAt'] as String,
      );
}

/// 本地音乐管理服务
/// 使用 SharedPreferences 持久化已导入的本地音乐列表
class LocalMusicService extends ChangeNotifier {
  static const String _key = 'local_music_list';
  List<LocalMusicItem> _items = [];

  List<LocalMusicItem> get items => List.unmodifiable(_items);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonStr);
        _items = jsonList
            .map((e) => LocalMusicItem.fromJson(e as Map<String, dynamic>))
            .toList();
        // 清理不存在的文件
        _items.removeWhere((item) => !File(item.path).existsSync());
        await _save();
      } catch (e) {
        debugPrint('LocalMusicService: 加载音乐列表失败: $e');
        _items = [];
      }
    }
    notifyListeners();
  }

  Future<void> addMusic(String path, String originalName) async {
    // 检查是否已存在
    if (_items.any((item) => item.path == path)) return;

    final item = LocalMusicItem(
      path: path,
      name: originalName,
      addedAt: DateTime.now().toIso8601String(),
    );
    _items.insert(0, item); // 最新的排在前面
    await _save();
    notifyListeners();
  }

  Future<void> removeMusic(String path) async {
    // 删除物理文件
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('LocalMusicService: 删除文件失败: $e');
    }

    // 删除记录
    _items.removeWhere((item) => item.path == path);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }
}
