import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimestampAdapter extends TypeAdapter<Timestamp> {
  @override
  final typeId = 2;  // Ensure that this ID is unique for the adapter

  @override
  Timestamp read(BinaryReader reader) {
    // Read the timestamp as a DateTime, and then convert it back to Timestamp
    return Timestamp.fromMillisecondsSinceEpoch(reader.readInt32());
  }

  @override
  void write(BinaryWriter writer, Timestamp obj) {
    // Write the timestamp as milliseconds
    writer.writeInt32(obj.seconds * 1000);  // Storing only seconds in milliseconds
  }
}
