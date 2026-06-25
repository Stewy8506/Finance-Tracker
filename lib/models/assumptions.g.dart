// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assumptions.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssumptionsAdapter extends TypeAdapter<Assumptions> {
  @override
  final int typeId = 3;

  @override
  Assumptions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Assumptions(
      sipReturnRate: fields[0] as double,
      cashSavingsRate: fields[1] as double,
      expenseInflation: fields[2] as double,
      homeLoanRate: fields[3] as double,
      loanTenureYears: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Assumptions obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.sipReturnRate)
      ..writeByte(1)
      ..write(obj.cashSavingsRate)
      ..writeByte(2)
      ..write(obj.expenseInflation)
      ..writeByte(3)
      ..write(obj.homeLoanRate)
      ..writeByte(4)
      ..write(obj.loanTenureYears);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssumptionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
