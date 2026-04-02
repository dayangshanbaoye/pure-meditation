// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meditation_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeditationRecordAdapter extends TypeAdapter<MeditationRecord> {
  @override
  final int typeId = 1;

  @override
  MeditationRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeditationRecord(
      id: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime,
      durationSeconds: fields[3] as int,
      typeId: fields[4] as String,
      musicUsed: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MeditationRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.durationSeconds)
      ..writeByte(4)
      ..write(obj.typeId)
      ..writeByte(5)
      ..write(obj.musicUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeditationRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
