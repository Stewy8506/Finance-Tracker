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
      targetMonth: fields[7] as int?,
      emiMonths: fields[8] as int?,
      emiInterestRate: fields[9] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringPurchase obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.targetMonth)
      ..writeByte(8)
      ..write(obj.emiMonths)
      ..writeByte(9)
      ..write(obj.emiInterestRate);
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
