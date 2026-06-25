// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_purchase.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringPurchaseAdapter extends TypeAdapter<RecurringPurchase> {
  @override
  final int typeId = 2;

  @override
  RecurringPurchase read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringPurchase(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      firstYear: fields[3] as int,
      recurEveryNYears: fields[4] as int?,
      category: fields[5] as String,
      note: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringPurchase obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.firstYear)
      ..writeByte(4)
      ..write(obj.recurEveryNYears)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringPurchaseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
