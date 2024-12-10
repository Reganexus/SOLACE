// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:solace/themes/colors.dart';

class ExportDataScreen extends StatefulWidget {
  final String filterValue; // Filter parameter
  final String title; // Title for the export

  const ExportDataScreen(
      {super.key, required this.filterValue, required this.title});

  @override
  _ExportDataScreenState createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  // Export format
  String? _selectedFormat = 'CSV'; // Default format
  final List<String> _formats = ['CSV', 'XLS', 'PDF'];

  // Time range filter
  String? _selectedTimeRange = 'All Time'; // Default time range
  final List<String> _timeRanges = ['This Week', 'This Month', 'All Time'];

  // Fetch data method based on filter value
  Future<void> _fetchData() async {
    try {
      // Query based on filter value (userRole or riskLevel)
      QuerySnapshot querySnapshot;
      DateTime startDate;

      // Calculate the start date for the selected time range
      if (_selectedTimeRange == 'This Week') {
        startDate = _getStartOfThisWeek();
      } else if (_selectedTimeRange == 'This Month') {
        startDate = _getStartOfThisMonth();
      } else {
        startDate = DateTime(1970, 1, 1); // All time (no filtering)
      }

      // Query Firestore based on the selected time range
      if (widget.filterValue == "patient" ||
          widget.filterValue == "caregiver" ||
          widget.filterValue == "doctor") {
        querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('userRole', isEqualTo: widget.filterValue)
            .where('dateCreated', isGreaterThanOrEqualTo: startDate)
            .get();
      } else if (widget.filterValue == "good" ||
          widget.filterValue == "low" ||
          widget.filterValue == "high") {
        querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('riskLevel', isEqualTo: widget.filterValue)
            .where('dateCreated', isGreaterThanOrEqualTo: startDate)
            .get();
      } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('dateCreated', isGreaterThanOrEqualTo: startDate)
            .get();
      }

      // Columns order
      final List<String> orderedColumns = [
        'uid',
        'firstName',
        'middleName',
        'lastName',
        'email',
        'phoneNumber',
        'birthday',
        'gender',
        'address',
        'dateCreated'
      ];

      // Prepare data for export
      List<Map<String, dynamic>> data = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> documentData = doc.data() as Map<String, dynamic>;

        // Add uid (document ID)
        documentData['uid'] = doc.id;

        // Exclude unnecessary fields
        documentData.removeWhere((key, value) =>
            key == 'isVerified' ||
            key == 'newUser' ||
            key == 'userRole' ||
            key == 'profileImageUrl');

        // Reorder the document data to match the desired column order
        Map<String, dynamic> orderedData = {};
        for (var column in orderedColumns) {
          if (documentData.containsKey(column)) {
            orderedData[column] = documentData[column];
          }
        }

        data.add(orderedData);
        print('Fetched Document (Ordered): $orderedData');
      }

      // Export data based on selected format
      _exportData(data);
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  // Get start of this week (Monday at 00:00)
  DateTime _getStartOfThisWeek() {
    final now = DateTime.now();
    final daysToSubtract = now.weekday - DateTime.monday;
    return now
        .subtract(Duration(days: daysToSubtract))
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
  }

  // Get start of this month (1st day of the month at 00:00)
  DateTime _getStartOfThisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1)
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
  }

  // Export data based on selected format
  void _exportData(List<Map<String, dynamic>> data) {
    if (_selectedFormat == 'CSV') {
      exportToCSV(data);
    } else if (_selectedFormat == 'XLS') {
      exportToXLS(data);
    } else if (_selectedFormat == 'PDF') {
      exportToPDF(data);
    }
  }

  // CSV Export
  Future<void> exportToCSV(List<Map<String, dynamic>> data) async {
    try {
      final headers = [
        'uid',
        'firstName',
        'middleName',
        'lastName',
        'email',
        'phoneNumber',
        'birthday',
        'gender',
        'address',
        'dateCreated'
      ];

      final dateFormat = DateFormat('MMMM dd, yyyy at h:mm:ss a \'UTC\'z');
      List<List<String>> rows = [];
      rows.add(headers);

      for (var docData in data) {
        List<String> row = [];
        for (var header in headers) {
          var value = docData[header];

          if (header == 'dateCreated' || header == 'birthday') {
            if (value is Timestamp) {
              value = dateFormat.format(
                  DateTime.fromMillisecondsSinceEpoch(value.seconds * 1000));
            }
          }

          if (value is String &&
              header == 'phoneNumber' &&
              value.startsWith('0')) {
            value =
                value.replaceFirst(RegExp(r'^0+'), ''); // Remove leading zeros
          }

          row.add(value.toString());
        }
        rows.add(row);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final csvBytes = Uint8List.fromList(utf8.encode(csvData));

      // Save the file using FilePicker
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV File',
        fileName: 'exported_data.csv',
        bytes: csvBytes,
      );

      if (outputFile != null) {
        // outputFile is the file path (String)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV file saved at: $outputFile')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picking cancelled.')),
        );
      }
    } catch (e) {
      print("Error generating CSV: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating CSV: $e')),
      );
    }
  }

// XLS Export
  Future<void> exportToXLS(List<Map<String, dynamic>> data) async {
    try {
      var excel = Excel.createExcel();
      final headers = [
        'uid',
        'firstName',
        'middleName',
        'lastName',
        'email',
        'phoneNumber',
        'birthday',
        'gender',
        'address',
        'dateCreated'
      ];

      final dateFormat = DateFormat('MMMM dd, yyyy at h:mm:ss a \'UTC\'z');
      var sheet = excel['Sheet1'];
      sheet.appendRow(headers);

      for (var docData in data) {
        List<String> row = [];
        for (var header in headers) {
          var value = docData[header];

          if (header == 'dateCreated' || header == 'birthday') {
            if (value is Timestamp) {
              value = dateFormat.format(
                  DateTime.fromMillisecondsSinceEpoch(value.seconds * 1000));
            }
          }

          if (value is String &&
              header == 'phoneNumber' &&
              value.startsWith('0')) {
            value =
                value.replaceFirst(RegExp(r'^0+'), ''); // Remove leading zeros
          }

          row.add(value.toString());
        }
        sheet.appendRow(row);
      }

      final xlsBytes = Uint8List.fromList(excel.encode()!);

      // Save the file using FilePicker
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save XLS File',
        fileName: 'exported_data.xlsx',
        bytes: xlsBytes,
      );

      if (outputFile != null) {
        // outputFile is the file path (String)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('XLS file saved at: $outputFile')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picking cancelled.')),
        );
      }
    } catch (e) {
      print("Error generating XLS: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating XLS: $e')),
      );
    }
  }

// PDF Export
  Future<void> exportToPDF(List<Map<String, dynamic>> data) async {
    try {
      final pdf = pw.Document();
      final headers = [
        'uid',
        'firstName',
        'middleName',
        'lastName',
        'email',
        'phoneNumber',
        'birthday',
        'gender',
        'address',
        'dateCreated'
      ];

      final dateFormat = DateFormat('MMMM dd, yyyy at h:mm:ss a \'UTC\'z');

      pdf.addPage(
        pw.Page(
          orientation: pw.PageOrientation.landscape, // Set to landscape
          build: (pw.Context context) {
            return pw.TableHelper.fromTextArray(
              headers: headers,
              data: data.map((docData) {
                List<String> row = [];
                for (var header in headers) {
                  var value = docData[header];

                  if (header == 'dateCreated' || header == 'birthday') {
                    if (value is Timestamp) {
                      value = dateFormat.format(
                          DateTime.fromMillisecondsSinceEpoch(
                              value.seconds * 1000));
                    }
                  }

                  if (value is String &&
                      header == 'phoneNumber' &&
                      value.startsWith('0')) {
                    value = value.replaceFirst(
                        RegExp(r'^0+'), ''); // Remove leading zeros
                  }

                  row.add(value.toString());
                }
                return row;
              }).toList(),
              headerStyle:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              cellStyle: pw.TextStyle(fontSize: 8),
              cellPadding: pw.EdgeInsets.all(2),
            );
          },
        ),
      );

      final pdfBytes = Uint8List.fromList(await pdf.save());

      // Save the file using FilePicker
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF File',
        fileName: 'exported_data.pdf',
        bytes: pdfBytes,
      );

      if (outputFile != null) {
        // outputFile is the file path (String)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF file saved at: $outputFile')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picking cancelled.')),
        );
      }
    } catch (e) {
      print("Error generating PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Export Data'),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dynamic title (e.g., "Export Patient Data")
                Text(
                  widget.title, // Use the passed title here
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: 20), // Add space after the title

                // Export Format Selection
                Text(
                  'Select Export Format:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    color: AppColors.black,
                  ),
                ),
                Column(
                  children: _formats.map((format) {
                    return RadioListTile<String>(
                      title: Text(
                        format,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Inter',
                          color: AppColors.black,
                        ),
                      ),
                      activeColor: AppColors.neon,
                      value: format,
                      groupValue: _selectedFormat,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedFormat = value;
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),

                // Time Range Selection
                Text(
                  'Select Time Range:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    color: AppColors.black,
                  ),
                ),
                Column(
                  children: _timeRanges.map((range) {
                    return RadioListTile<String>(
                      title: Text(
                        range,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Inter',
                          color: AppColors.black,
                        ),
                      ),
                      activeColor: AppColors.neon,
                      value: range,
                      groupValue: _selectedTimeRange,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedTimeRange = value;
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),

                // Export Data Button
                Center(
                  child: TextButton(
                    onPressed: _fetchData,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      backgroundColor: AppColors.neon,
                    ),
                    child: Text(
                      'Export Data',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
