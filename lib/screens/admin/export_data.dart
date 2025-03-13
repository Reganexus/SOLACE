// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
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
  final List<String> _formats = ['CSV', 'PDF'];

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

      var selectedValue = widget.filterValue;

      // Query Firestore based on the selected time range
      if (widget.filterValue == "patient") {
        querySnapshot = await FirebaseFirestore.instance
            .collection('patient')
            .where('dateCreated', isGreaterThanOrEqualTo: startDate)
            .get();
      } else if (widget.filterValue == "caregiver" ||
          widget.filterValue == "doctor" ||
          widget.filterValue == "admin") {
        querySnapshot = await FirebaseFirestore.instance
            .collection(selectedValue)
            .where('dateCreated', isGreaterThanOrEqualTo: startDate)
            .get();
      } else if (widget.filterValue == "stable" ||
          widget.filterValue == "unstable") {
        querySnapshot = await FirebaseFirestore.instance
            .collection('patient')
            .where('status', isEqualTo: widget.filterValue)
            .where('dateCreated', isGreaterThanOrEqualTo: startDate)
            .get();
      } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('admin')
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
        'age',
        'religion',
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
      _exportData(data, selectedValue);
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
  void _exportData(List<Map<String, dynamic>> data, String selectedValue) {
    if (_selectedFormat == 'CSV') {
      exportToCSV(data, selectedValue);
    } else if (_selectedFormat == 'PDF') {
      exportToPDF(data, selectedValue);
    }
  }

  // CSV Export
  Future<void> exportToCSV(
      List<Map<String, dynamic>> data, String selectedValue) async {
    try {
      final headers = [
        'uid',
        'firstName',
        'middleName',
        'lastName',
        'email',
        'phoneNumber',
        'birthday',
        'age',
        'religion',
        'gender',
        'address',
        'dateCreated'
      ];

      final dateFormat = DateFormat('MMMM dd, yyyy'); // For birthday
      final timestampFormat =
          DateFormat('MMMM dd, yyyy at h:mm:ss a \'UTC\'z'); // For dateCreated
      List<List<String>> rows = [];
      rows.add(headers);

      for (var docData in data) {
        List<String> row = [];
        for (var header in headers) {
          var value = docData[header];

          if (header == 'birthday') {
            if (value is Timestamp) {
              value = dateFormat.format(
                  DateTime.fromMillisecondsSinceEpoch(value.seconds * 1000));
            }
          } else if (header == 'dateCreated') {
            if (value is Timestamp) {
              value = timestampFormat.format(
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

      String formattedDate =
          DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      String fileName = "${selectedValue}_exported_data_$formattedDate.csv";

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV File',
        fileName: fileName,
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

// PDF Export
  Future<void> exportToPDF(
      List<Map<String, dynamic>> data, String selectedValue) async {
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
        'age',
        'religion',
        'gender',
        'address',
        'dateCreated'
      ];

      final dateFormat = DateFormat('MMMM dd, yyyy'); // For birthday
      final timestampFormat =
          DateFormat('MMMM dd, yyyy at h:mm:ss a \'UTC\'z'); // For dateCreated

      pdf.addPage(
        pw.Page(
          orientation: pw.PageOrientation.landscape, // Set to landscape
          build: (pw.Context context) {
            final List<List<String>> rows = [
              headers,
              ...data.map((docData) {
                return headers.map((header) {
                  var value = docData[header];

                  if (header == 'birthday') {
                    if (value is Timestamp) {
                      value = dateFormat.format(
                          DateTime.fromMillisecondsSinceEpoch(
                              value.seconds * 1000));
                    }
                  } else if (header == 'dateCreated') {
                    if (value is Timestamp) {
                      value = timestampFormat.format(
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

                  return value?.toString() ?? ''; // Handle null values
                }).toList();
              })
            ];

            return pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                for (int i = 0; i < headers.length; i++)
                  i: const pw.FlexColumnWidth(1),
              },
              children: rows.map((row) {
                return pw.TableRow(
                  children: row.map((cell) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text(
                        cell,
                        style: const pw.TextStyle(fontSize: 8),
                        textAlign: pw.TextAlign.left,
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            );
          },
        ),
      );

      final pdfBytes = Uint8List.fromList(await pdf.save());

      // Save the file using FilePicker
      String formattedDate =
          DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      String fileName = "${selectedValue}_exported_data_$formattedDate.pdf";

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF File',
        fileName: fileName,
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
        title: Text(
          'Export Data',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
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
