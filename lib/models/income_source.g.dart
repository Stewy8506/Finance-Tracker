// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income_source.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IncomeSourceAdapter extends TypeAdapter<IncomeSource> {
  @override
  final int typeId = 4;

  @override
  IncomeSource read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IncomeSource(
      id: fields[0] as String,
      label: fields[1] as String,
      monthlyAmount: fields[2] as double,
      annualGrowthPct: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, IncomeSource obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.monthlyAmount)
      ..writeByte(3)
      ..write(obj.annualGrowthPct);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
