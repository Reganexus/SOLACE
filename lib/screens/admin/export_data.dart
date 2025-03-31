// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';

class ExportDataScreen extends StatefulWidget {
  final String filterValue; // Filter parameter
  final String title; // Title for the export

  const ExportDataScreen({
    super.key,
    required this.filterValue,
    required this.title,
  });

  @override
  _ExportDataScreenState createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LogService _logService = LogService();
  bool isSaving = false;
  String? _selectedFormat = 'CSV';
  String? _selectedTimeRange = 'All Time';
  final List<String> _formats = ['CSV', 'PDF'];
  final List<String> _timeRanges = ['This Week', 'This Month', 'All Time'];

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _fetchData() async {
    setState(() => isSaving = true);
    _showToast("Fetching data...");
    try {
      final user = _auth.currentUser;

      if (user == null) {
        print("Error: No authenticated user found.");
        return;
      }

      debugPrint("User ID: $user");
      QuerySnapshot querySnapshot;
      DateTime startDate;

      if (_selectedTimeRange == 'This Week') {
        startDate = _getStartOfThisWeek();
      } else if (_selectedTimeRange == 'This Month') {
        startDate = _getStartOfThisMonth();
      } else {
        startDate = DateTime(1970, 1, 1);
      }

      String selectedValue = widget.filterValue;

      if (widget.filterValue == "patient") {
        querySnapshot =
            await FirebaseFirestore.instance
                .collection('patient')
                .where('dateCreated', isGreaterThanOrEqualTo: startDate)
                .get();
      } else if ([
        "caregiver",
        "doctor",
        "admin",
      ].contains(widget.filterValue)) {
        querySnapshot =
            await FirebaseFirestore.instance
                .collection(selectedValue)
                .where('dateCreated', isGreaterThanOrEqualTo: startDate)
                .get();
      } else if (widget.filterValue == "stable" ||
          widget.filterValue == "unstable") {
        querySnapshot =
            await FirebaseFirestore.instance
                .collection('patient')
                .where('status', isEqualTo: widget.filterValue)
                .where('dateCreated', isGreaterThanOrEqualTo: startDate)
                .get();
      } else {
        querySnapshot =
            await FirebaseFirestore.instance
                .collection('admin')
                .where('dateCreated', isGreaterThanOrEqualTo: startDate)
                .get();
      }

      if (querySnapshot.docs.isEmpty) {
        _showToast("No data found for the selected filters.");
        setState(() => isSaving = false);
        return;
      }

      List<Map<String, dynamic>> data =
          querySnapshot.docs.map((doc) {
            Map<String, dynamic> documentData =
                doc.data() as Map<String, dynamic>;

            String fullName = [
              documentData['firstName'] ?? '',
              documentData['middleName'] ?? '',
              documentData['lastName'] ?? '',
            ].where((name) => name.isNotEmpty).join(' ');

            documentData.remove('firstName');
            documentData.remove('middleName');
            documentData.remove('lastName');
            documentData.remove('uid');
            documentData.remove('dateCreated');

            if (widget.filterValue == "patient") {
              documentData.remove('email');
              documentData.remove('phoneNumber');
            }

            documentData['fullname'] = fullName;

            return documentData;
          }).toList();

      await _logService.addLog(
        userId: user.uid,
        action: "Exported ${widget.filterValue} Data to $_selectedFormat",
      );

      _exportData(data, selectedValue);
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() => isSaving = false);
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
    return DateTime(
      now.year,
      now.month,
      1,
    ).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
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
    List<Map<String, dynamic>> data,
    String selectedValue,
  ) async {
    try {
      final headers = _getHeaders(selectedValue);
      List<List<String>> rows = [headers];

      for (var docData in data) {
        rows.add(
          headers
              .map((header) => _formatValue(docData[header], header))
              .toList(),
        );
      }

      _showToast("CSV data prepared, saving file...");

      String csvData = const ListToCsvConverter().convert(rows);
      final csvBytes = Uint8List.fromList(utf8.encode(csvData));
      await _saveFile(csvBytes, selectedValue, "csv");

      _showToast("CSV export completed.");
    } catch (e) {
      print("Error generating CSV: $e");
      _showToast("Error generating CSV.");
    }
  }

  Future<void> exportToPDF(
    List<Map<String, dynamic>> data,
    String selectedValue,
  ) async {
    try {
      final pdf = pw.Document();
      final headers = _getHeaders(selectedValue);

      pdf.addPage(
        pw.Page(
          orientation: pw.PageOrientation.landscape,
          build: (pw.Context context) {
            return pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                for (int i = 0; i < headers.length; i++)
                  i: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  children:
                      headers.map((header) => _pdfCell(header, true)).toList(),
                ),
                ...data.map(
                  (docData) => pw.TableRow(
                    children:
                        headers
                            .map(
                              (header) => _pdfCell(
                                _formatValue(docData[header], header),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            );
          },
        ),
      );

      _showToast("PDF data prepared, saving file...");
      final pdfBytes = Uint8List.fromList(await pdf.save());
      await _saveFile(pdfBytes, selectedValue, "pdf");

      _showToast("PDF export completed.");
    } catch (e) {
      print("Error generating PDF: $e");
      _showToast("Error generating PDF.");
    }
  }

  // Determine headers dynamically based on filter value
  List<String> _getHeaders(String filterValue) {
    List<String> headers = [
      'fullname',
      'birthday',
      'age',
      'religion',
      'gender',
      'address',
    ];

    if (!["patient", "stable", "unstable"].contains(filterValue)) {
      headers.insert(3, 'email'); // Insert email after lastName
      headers.insert(4, 'phoneNumber'); // Insert phoneNumber after email
    }

    return headers;
  }

  // Format values for CSV/PDF output
  String _formatValue(dynamic value, String header) {
    if (value == null) return '';

    if (header == 'birthday' || header == 'dateCreated') {
      if (value is Timestamp) {
        return DateFormat(
          header == 'birthday'
              ? 'MMMM dd, yyyy'
              : 'MMMM dd, yyyy at h:mm:ss a \'UTC\'z',
        ).format(DateTime.fromMillisecondsSinceEpoch(value.seconds * 1000));
      }
    }

    return value.toString();
  }

  // Create a PDF cell with text
  pw.Widget _pdfCell(String text, [bool isHeader = false]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.left,
      ),
    );
  }

  // Save the file
  Future<void> _saveFile(
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
      _showToast("File picking cancelled.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(widget.title, style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Export Format:', style: Textstyle.subheader),

              Wrap(
                children:
                    _formats.map((format) {
                      return RadioListTile<String>(
                        title: Text(format, style: Textstyle.body),
                        activeColor: AppColors.neon,
                        value: format,
                        groupValue: _selectedFormat,
                        onChanged:
                            isSaving
                                ? null
                                : (String? value) {
                                  setState(() => _selectedFormat = value);
                                },
                      );
                    }).toList(),
              ),

              SizedBox(height: 20),

              Text('Select Time Range:', style: Textstyle.subheader),

              Wrap(
                children:
                    _timeRanges.map((range) {
                      return RadioListTile<String>(
                        title: Text(range, style: Textstyle.body),
                        activeColor: AppColors.purple,
                        value: range,
                        groupValue: _selectedTimeRange,
                        onChanged:
                            isSaving
                                ? null
                                : (String? value) {
                                  setState(() => _selectedTimeRange = value);
                                },
                      );
                    }).toList(),
              ),

              SizedBox(height: 20),

              // Export Data Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: isSaving ? null : _fetchData,
                  style:
                      isSaving ? Buttonstyle.buttonDarkGray : Buttonstyle.neon,
                  child:
                      isSaving
                          ? Loader.loaderWhite
                          : Text('Export Data', style: Textstyle.smallButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
