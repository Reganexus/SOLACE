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
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';
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
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final LogService _logService = LogService();
  bool isSaving = false;
  String? _selectedFormat = 'CSV';
  String? _selectedTimeRange = 'All Time';
  final List<String> _formats = ['CSV', 'PDF'];
  final List<String> _timeRanges = ['This Week', 'This Month', 'All Time'];

  void _showToast(String message, {Color? backgroundColor}) {
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

  Future<void> _fetchData() async {
    setState(() => isSaving = true);
    _showToast("Fetching data...");
    try {
      final user = _auth.currentUser;

      if (user == null) {
        //     debugPrint("Error: No authenticated user found.");
        return;
      }

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
      } else if (["caregiver", "doctor"].contains(widget.filterValue)) {
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
        return;
      }

      if (querySnapshot.docs.isEmpty) {
        _showToast(
          "No data found for the selected filters.",
          backgroundColor: AppColors.red,
        );
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

              // Process cases as comma-separated string
              List<dynamic>? cases = documentData['cases'] as List<dynamic>?;
              documentData['cases'] = cases != null ? cases.join(', ') : '';

              // Add caseDescription
              documentData['caseDescription'] =
                  documentData['caseDescription'] ?? '';
            }

            documentData['name'] = fullName;

            return documentData;
          }).toList();

      await _logService.addLog(
        userId: user.uid,
        action: "Exported ${widget.filterValue} Data to $_selectedFormat",
      );

      _exportData(data, selectedValue);
    } catch (e) {
      //     debugPrint("Error fetching data: $e");
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
      if (data.isEmpty) {
        _showToast(
          "No data available for export.",
          backgroundColor: AppColors.red,
        );
        return;
      }

      final user = _authService.currentUserId;
      final headers = _getHeaders(selectedValue);
      final filterName = widget.filterValue;
      final capitalizedFilterName =
          filterName[0].toUpperCase() + filterName.substring(1);
      final exportDate = DateFormat(
        'MMMM d, yyyy h:mm a',
      ).format(DateTime.now());
      final userName = await _databaseService.fetchUserName(user!) ?? 'Unknown';

      final title =
          filterName == 'stable' || filterName == 'unstable'
              ? '$capitalizedFilterName Patients Data Summary'
              : '${capitalizedFilterName}s Data Summary';
      final numberOfFilterValue = data.length;

      List<List<String>> rows = [
        ['SOLACE - $title', ''],
        ['Date exported:', exportDate],
        ['Exported by:', userName],
        ['', ''],
        ['Number of ${filterName}s', '$numberOfFilterValue'],
        ['', ''],
        headers,
      ];

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
    } catch (e) {
      //     debugPrint("Error generating CSV: $e");
      _showToast("Error generating CSV.", backgroundColor: AppColors.red);
    }
  }

  Future<void> exportToPDF(
    List<Map<String, dynamic>> data,
    String selectedValue,
  ) async {
    try {
      final pdf = pw.Document();
      final headers = _getHeaders(selectedValue);

      // Load image as Uint8List
      final ByteData imageData = await rootBundle.load(
        'lib/assets/images/auth/solace.png',
      ); // Replace with your image path
      final Uint8List imageBytes = imageData.buffer.asUint8List();
      final image = pw.MemoryImage(imageBytes);

      // Ensure headers and data are not empty
      if (headers.isEmpty || data.isEmpty) {
        pdf.addPage(
          pw.Page(
            build:
                (context) => pw.Center(
                  child: pw.Text('No data available for the selected filters.'),
                ),
          ),
        );
      } else {
        // Metadata and Table
        final user = _auth.currentUser!;
        final userName =
            await _databaseService.fetchUserName(user.uid) ?? 'Unknown';
        final filterName = widget.filterValue;
        final capitalizedFilterName =
            filterName[0].toUpperCase() + filterName.substring(1);
        final exportDate = DateFormat(
          'MMMM d, yyyy h:mm a',
        ).format(DateTime.now());
        final title =
            filterName == 'stable' || filterName == 'unstable'
                ? '$capitalizedFilterName Patients Data Summary'
                : '${capitalizedFilterName}s Data Summary';
        final numberOfFilterValue = data.length;

        pdf.addPage(
          pw.Page(
            orientation: pw.PageOrientation.landscape,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Center(child: pw.Image(image, width: 40, height: 40)),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'SOLACE - $title',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Date exported: $exportDate',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Exported by: $userName',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Number of ${filterName}s: $numberOfFilterValue',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 9),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      // Headers
                      pw.TableRow(
                        children:
                            headers
                                .map((header) => _pdfCell(header, true))
                                .toList(),
                      ),
                      // Data Rows
                      ...data.map((docData) {
                        return pw.TableRow(
                          children:
                              headers.map((header) {
                                final value = _formatValue(
                                  docData[header],
                                  header,
                                );
                                return _pdfCell(value);
                              }).toList(),
                        );
                      }),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      // Save PDF
      _showToast("PDF data prepared, saving file...");
      final pdfBytes = Uint8List.fromList(await pdf.save());
      await _saveFile(pdfBytes, selectedValue, "pdf");
    } catch (e) {
      //     debugPrint("Error generating PDF: $e");
      _showToast("Error generating PDF.", backgroundColor: AppColors.red);
    }
  }

  // Create a PDF cell with text
  pw.Widget _pdfCell(String text, [bool isHeader = false]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 7,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.left,
      ),
    );
  }

  // Determine headers dynamically based on filter value
  List<String> _getHeaders(String filterValue) {
    List<String> headers = [
      'name',
      'birthday',
      'age',
      'religion',
      'gender',
      'address',
    ];

    if (filterValue == 'patient') {
      headers.addAll(['cases', 'caseDescription']);
    } else if (!["stable", "unstable"].contains(filterValue)) {
      headers.insert(3, 'email');
      headers.insert(4, 'phoneNumber');
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
      _showToast("File picking cancelled.", backgroundColor: AppColors.red);
    } else {
      _showToast("$extension Export completed.");
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
