import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/colors.dart';

class ExportDataset {
  static Future<void> exportTrackingData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final trackingDataList = <Map<String, dynamic>>[];

      final usersSnapshot = await firestore.collection('tracking').get();

      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();
        final trackingArray = userData['tracking'] as List<dynamic>? ?? [];

        for (var trackingElement in trackingArray) {
          final symptomAssessment =
              (trackingElement['Symptom Assessment'] as Map?)
                  ?.cast<String, dynamic>() ??
              {};
          final vitals =
              (trackingElement['Vitals'] as Map?)?.cast<String, dynamic>() ??
              {};
          final timestamp =
              trackingElement['timestamp'] is Timestamp
                  ? (trackingElement['timestamp'] as Timestamp)
                      .toDate()
                      .toIso8601String()
                  : 'N/A';
          final gender = trackingElement['gender'] ?? 'N/A';
          final age = trackingElement['age'] ?? 'N/A';

          final dataRow = {
            'userId': userId,
            'gender': gender,
            'age': age,
            ...symptomAssessment,
            ...vitals,
            'timestamp': timestamp,
          };

          trackingDataList.add(dataRow);
        }
      }

      // ✅ Create an instance of ExportHelper
      ExportHelper exportHelper = ExportHelper();
      await exportHelper.exportToCSV(
        data: trackingDataList,
        fileName: "tracking_data",
      );
    } catch (e) {
      debugPrint("Error exporting tracking data: $e");
    }
  }
}

class ExportHelper {
  final AuthService _auth = AuthService();
  final LogService _logService = LogService();

  Future<void> exportToCSV({
    required List<Map<String, dynamic>> data,
    required String fileName,
  }) async {
    try {
      final user = _auth.currentUserId;
      if (data.isEmpty) {
        _showToast("No data available for export.");
        return;
      }

      // Extract headers dynamically
      final headers = data.first.keys.toList();
      List<List<String>> rows = [headers];

      // Process data rows
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
        userId: user!,
        action: 'Exported dataset as $fileName.csv',
      );

      _showToast("CSV export completed.");
    } catch (e) {
      debugPrint("Error generating CSV: $e");
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
      _showToast("File saving cancelled.");
    }
  }

  /// Shows toast message (Static method)
  static void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }
}
