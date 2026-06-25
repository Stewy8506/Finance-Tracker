// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalAdapter extends TypeAdapter<Goal> {
  @override
  final int typeId = 1;

  @override
  Goal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Goal(
      id: fields[0] as String,
      name: fields[1] as String,
      targetAmount: fields[2] as double,
      targetYear: fields[3] as int,
      type: fields[4] as String,
      priority: fields[5] as String,
      propertyValue: fields[6] as double?,
      downPaymentPct: fields[7] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.targetAmount)
      ..writeByte(3)
      ..write(obj.targetYear)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.propertyValue)
      ..writeByte(7)
      ..write(obj.downPaymentPct);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
