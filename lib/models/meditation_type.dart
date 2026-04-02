import 'package:hive/hive.dart';

part 'meditation_type.g.dart';

@HiveType(typeId: 0)
class MeditationType extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String colorCode;

  MeditationType({
    required this.id,
    required this.name,
    required this.colorCode,
  });
}
