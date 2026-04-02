import 'package:hive/hive.dart';

part 'meditation_record.g.dart';

@HiveType(typeId: 1)
class MeditationRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  final DateTime endTime;

  @HiveField(3)
  final int durationSeconds;

  @HiveField(4)
  final String typeId;

  @HiveField(5)
  final String? musicUsed;

  MeditationRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.typeId,
    this.musicUsed,
  });
}
