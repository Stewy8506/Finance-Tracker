// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      startingCtcLpa: fields[0] as double,
      annualHikePct: fields[1] as double,
      taxRegime: fields[2] as String,
      cityPreset: fields[3] as String,
      monthlyRent: fields[4] as double,
      monthlyFood: fields[5] as double,
      monthlyTransport: fields[6] as double,
      monthlyMisc: fields[7] as double,
      sipRatePct: fields[8] as double,
      onboardingComplete: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.startingCtcLpa)
      ..writeByte(1)
      ..write(obj.annualHikePct)
      ..writeByte(2)
      ..write(obj.taxRegime)
      ..writeByte(3)
      ..write(obj.cityPreset)
      ..writeByte(4)
      ..write(obj.monthlyRent)
      ..writeByte(5)
      ..write(obj.monthlyFood)
      ..writeByte(6)
      ..write(obj.monthlyTransport)
      ..writeByte(7)
      ..write(obj.monthlyMisc)
      ..writeByte(8)
      ..write(obj.sipRatePct)
      ..writeByte(9)
      ..write(obj.onboardingComplete);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
