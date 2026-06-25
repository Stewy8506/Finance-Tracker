// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SuggestionHistoryEntryAdapter
    extends TypeAdapter<SuggestionHistoryEntry> {
  @override
  final int typeId = 7;

  @override
  SuggestionHistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SuggestionHistoryEntry(
      suggestionTitle: fields[0] as String,
      type: fields[1] as String,
      impactScore: fields[2] as double,
      appliedAt: fields[3] as DateTime,
      cashFlowImpact: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SuggestionHistoryEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.suggestionTitle)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.impactScore)
      ..writeByte(3)
      ..write(obj.appliedAt)
      ..writeByte(4)
      ..write(obj.cashFlowImpact);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionHistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
