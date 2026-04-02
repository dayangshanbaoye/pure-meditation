import 'package:hive/hive.dart';

part 'daily_stats.g.dart';

@HiveType(typeId: 2)
class DailyStats extends HiveObject {
  @HiveField(0)
  final String date; // Format: yyyy-MM-dd

  @HiveField(1)
  int totalDurationSeconds;

  @HiveField(2)
  int sessionCount;

  @HiveField(3)
  Map<String, int> typeBreakdown; // typeId -> durationSeconds

  DailyStats({
    required this.date,
    required this.totalDurationSeconds,
    required this.sessionCount,
    required this.typeBreakdown,
  });
}
