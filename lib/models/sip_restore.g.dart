// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sip_restore.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SipRestoreAdapter extends TypeAdapter<SipRestore> {
  @override
  final int typeId = 8;

  @override
  SipRestore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SipRestore(
      originalSipPct: fields[0] as double,
      restoreYear: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SipRestore obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.originalSipPct)
      ..writeByte(1)
      ..write(obj.restoreYear);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SipRestoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
