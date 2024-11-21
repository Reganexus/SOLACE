import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  // Initialize Hive
  await Hive.initFlutter();

  // Delete the box from disk
  await Hive.deleteBoxFromDisk('LocalUsers');
  debugPrint('LocalUsers box deleted successfully!');
}
