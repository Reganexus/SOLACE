// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_users.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalUsersAdapter extends TypeAdapter<LocalUsers> {
  @override
  final int typeId = 0;

  @override
  LocalUsers read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalUsers()..localUsers = (fields[0] as List?)?.cast<LocalUser>();
  }

  @override
  void write(BinaryWriter writer, LocalUsers obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.localUsers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalUsersAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
