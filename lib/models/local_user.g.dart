// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalUserAdapter extends TypeAdapter<LocalUser> {
  @override
  final int typeId = 1;

  @override
  LocalUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalUser(
      uid: fields[0] as String?,
      userRole: fields[1] as String?,
      email: fields[2] as String?,
      firstName: fields[3] as String?,
      middleName: fields[4] as String?,
      lastName: fields[5] as String?,
      phoneNumber: fields[6] as String?,
      birthday: fields[7] as Timestamp?,
      gender: fields[8] as String?,
      address: fields[9] as String?,
      profileImageUrl: fields[10] as String?,
      isVerified: fields[11] as bool?,
      newUser: fields[12] as bool?,
      dateCreated: fields[13] as Timestamp?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalUser obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.userRole)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.firstName)
      ..writeByte(4)
      ..write(obj.middleName)
      ..writeByte(5)
      ..write(obj.lastName)
      ..writeByte(6)
      ..write(obj.phoneNumber)
      ..writeByte(7)
      ..write(obj.birthday)
      ..writeByte(8)
      ..write(obj.gender)
      ..writeByte(9)
      ..write(obj.address)
      ..writeByte(10)
      ..write(obj.profileImageUrl)
      ..writeByte(11)
      ..write(obj.isVerified)
      ..writeByte(12)
      ..write(obj.newUser)
      ..writeByte(13)
      ..write(obj.dateCreated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
