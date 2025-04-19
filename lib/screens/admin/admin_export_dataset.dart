import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/colors.dart';

class ExportDataset {
  static Future<void> exportTrackingData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final trackingDataList = <Map<String, dynamic>>[];

      final usersSnapshot = await firestore.collection('tracking').get();

      int patientNumber = 1;
      final Map<String, int> patientIdMapping = {};
      final Map<String, DateTime> patientBaseTimestamp = {};

      // Metadata variables
      int maleCount = 0;
      int femaleCount = 0;
      int otherGenderCount = 0;
      final ageRangeCount = <String, int>{};

      // Track the first age for each patient to avoid double counting in age ranges
      final Map<String, bool> patientAgeCaptured = {};

      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();
        final trackingArray = userData['tracking'] as List<dynamic>? ?? [];

        int? patientAge;
        String? patientGender;

        // Loop through each tracking record for the patient
        for (var trackingElement in trackingArray) {
          // Extract gender and age from the tracking record
          final gender = trackingElement['gender'] ?? 'N/A';
          final age = trackingElement['age'] ?? 0;

          // Count gender only once per patient (based on the first record)
          if (!patientIdMapping.containsKey(userId)) {
            if (gender == 'Male') {
              maleCount++;
            } else if (gender == 'Female') {
              femaleCount++;
            } else {
              otherGenderCount++;
            }

            // Capture the gender and age for the first record
            patientGender = gender;
            patientAge = age;

            patientIdMapping[userId] = patientNumber;
            patientNumber++;
          }

          if (!patientAgeCaptured.containsKey(userId)) {
            if (patientAge != null) {
              if (patientAge >= 1 && patientAge <= 5) {
                ageRangeCount['1-5'] = (ageRangeCount['1-5'] ?? 0) + 1;
              } else if (patientAge >= 6 && patientAge <= 10) {
                ageRangeCount['6-10'] = (ageRangeCount['6-10'] ?? 0) + 1;
              } else if (patientAge >= 11 && patientAge <= 15) {
                ageRangeCount['11-15'] = (ageRangeCount['11-15'] ?? 0) + 1;
              } else if (patientAge >= 16 && patientAge <= 20) {
                ageRangeCount['16-20'] = (ageRangeCount['16-20'] ?? 0) + 1;
              } else if (patientAge >= 21 && patientAge <= 25) {
                ageRangeCount['21-25'] = (ageRangeCount['21-25'] ?? 0) + 1;
              }
            }
            patientAgeCaptured[userId] = true;
          }

          final symptomAssessment =
              (trackingElement['Symptom Assessment'] as Map?)
                  ?.cast<String, dynamic>() ??
              {};
          final vitals =
              (trackingElement['Vitals'] as Map?)?.cast<String, dynamic>() ??
              {};
          final timestamp =
              trackingElement['timestamp'] is Timestamp
                  ? (trackingElement['timestamp'] as Timestamp).toDate()
                  : DateTime.now();

          // If this is the first record for the patient, set the base timestamp
          if (!patientBaseTimestamp.containsKey(userId)) {
            patientBaseTimestamp[userId] = timestamp;
          }

          // Calculate the time difference in minutes as a double (keep decimal precision)
          double timeDifferenceInMinutes =
              timestamp
                  .difference(patientBaseTimestamp[userId]!)
                  .inMilliseconds /
              60000.0;

          final dataRow = {
            'patientId': patientIdMapping[userId].toString(),
            'timeOffset (in minutes)': timeDifferenceInMinutes.toStringAsFixed(
              2,
            ), // Keep 2 decimal places
            'gender': patientGender,
            'age': patientAge.toString(),
            ...symptomAssessment,
            ...vitals,
          };

          trackingDataList.add(dataRow);

          // If this is the first timestamp of the new record, update the base timestamp
          if (timestamp == trackingArray.first) {
            patientBaseTimestamp[userId] =
                timestamp; // Set base timestamp for next records
          }
        }
      }

      // Export the data
      ExportHelper exportHelper = ExportHelper();
      await exportHelper.exportToCSV(
        data: trackingDataList,
        fileName: "tracking_data",
        patientCount: patientNumber - 1,
        maleCount: maleCount,
        femaleCount: femaleCount,
        otherGenderCount: otherGenderCount,
        ageRangeCount: ageRangeCount,
      );
    } catch (e) {
      //       debugPrint("Error exporting tracking data: $e");
    }
  }
}

class ExportHelper {
  final AuthService _auth = AuthService();
  final LogService _logService = LogService();
  final DatabaseService _databaseService = DatabaseService();

  Future<void> exportToCSV({
    required List<Map<String, dynamic>> data,
    required String fileName,
    required int patientCount,
    required int maleCount,
    required int femaleCount,
    required int otherGenderCount,
    required Map<String, int> ageRangeCount,
  }) async {
    try {
      final user = _auth.currentUserId;
      final exportDate = DateFormat(
        'MMMM d, yyyy h:mm a',
      ).format(DateTime.now());
      final userName = await _databaseService.fetchUserName(user!);

      if (data.isEmpty) {
        _showToast("No data available for export.");
        return;
      }

      // Metadata rows
      List<List<String>> rows = [
        ['SOLACE - Dataset', ''],
        ['Date exported:', exportDate],
        ['Exported by:', userName ?? 'Unknown'],
        ['', ''],
        ['Patient count:', patientCount.toString()],
        ['Male:', maleCount.toString()],
        ['Female:', femaleCount.toString()],
        ['Others:', otherGenderCount.toString()],
        ['', ''],
        ['Age Group Range', 'Count'],
      ];

      // Age range counts (only include non-zero values)
      for (var entry in ageRangeCount.entries) {
        if (entry.value > 0) {
          rows.add([entry.key, entry.value.toString()]);
        }
      }

      rows.add(['', '']);

      final headers = data.first.keys.toList();
      rows.add(headers);

      for (var docData in data) {
        rows.add(
          headers
              .map((header) => _formatValue(docData[header], header))
              .toList(),
        );
      }

      _showToast("CSV data prepared, saving file...");

      // Convert data to CSV format
      String csvData = const ListToCsvConverter().convert(rows);
      final csvBytes = Uint8List.fromList(utf8.encode(csvData));

      // Save file using FilePicker
      await _saveFile(csvBytes, fileName, "csv");

      await _logService.addLog(
        userId: user,
        action: 'Exported dataset as $fileName.csv',
      );
    } catch (e) {
      //       debugPrint("Error generating CSV: $e");
      _showToast("Error generating CSV.");
    }
  }

  /// Formats values for CSV
  String _formatValue(dynamic value, String header) {
    if (value == null) return '';
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    return value.toString();
  }

  /// Saves file using FilePicker (Static method)
  static Future<void> _saveFile(
    Uint8List bytes,
    String selectedValue,
    String extension,
  ) async {
    String formattedDate = DateFormat(
      'yyyy-MM-dd_HH-mm-ss',
    ).format(DateTime.now());
    String fileName =
        "${selectedValue}_exported_data_$formattedDate.$extension";

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save $extension File',
      fileName: fileName,
      bytes: bytes,
    );

    if (outputFile == null) {
      _showToast("File picking cancelled.", backgroundColor: AppColors.red);
    } else {
      _showToast("CSV export completed.");
    }
  }

  /// Shows toast message (Static method)
  static void _showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }
}
