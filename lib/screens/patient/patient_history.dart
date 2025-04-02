// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textformfield.dart';
import 'package:solace/themes/textstyle.dart';

class PatientHistory extends StatefulWidget {
  final String patientId;

  const PatientHistory({super.key, required this.patientId});

  @override
  _PatientHistoryState createState() => _PatientHistoryState();
}

class _PatientHistoryState extends State<PatientHistory> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService databaseService = DatabaseService();
  final LogService _logService = LogService();
  DateTime? _selectedDate;
  bool isDescending = true;
  late String patientName = '';

  @override
  void initState() {
    super.initState();
    _selectedDate = null;
    dateController.text =
        _selectedDate != null
            ? DateFormat("MMMM d, yyyy").format(_selectedDate!)
            : '';
    _resetDateControllers();
    _loadPatientName();
    debugPrint("Patient Name: $patientName");
  }

  @override
  void dispose() {
    diagnosisFocusNode.dispose();
    descriptionFocusNode.dispose();
    dateFocusNode.dispose();
    diagnosisController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientName() async {
    final name = await databaseService.fetchUserName(widget.patientId);
    if (mounted) {
      setState(() {
        patientName = name ?? 'Unknown';
      });
    }
    debugPrint("Patient Name: $patientName");
  }

  // Controller for the dialog input fields
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final FocusNode diagnosisFocusNode = FocusNode();
  final FocusNode descriptionFocusNode = FocusNode();
  final FocusNode dateFocusNode = FocusNode();

  void _resetDateControllers() {
    diagnosisController.clear();
    descriptionController.clear();
    dateController.clear();
    _selectedDate = null; // Reset date
  }

  void _toggleSortingOrder() {
    setState(() {
      isDescending = !isDescending;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(1950),
      lastDate: now, // Restrict the selection to today or earlier
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.neon,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;

        // Format the date for the text field
        dateController.text = DateFormat("MMMM d, yyyy").format(_selectedDate!);
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getDiagnoses() async {
    final diagnosisSnapshot =
        await FirebaseFirestore.instance
            .collection('patient')
            .doc(widget.patientId)
            .collection('diagnoses')
            .get();

    return diagnosisSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Include the Firestore document ID
      return data;
    }).toList();
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _addDiagnosis(
    String diagnosis,
    String description,
    DateTime date,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      showToast("User is not Authenticated");
      return;
    }

    if (user.uid == null) {
      showToast("User is id Null");
      return;
    }

    final String userId = user.uid;

    String capitalize(String input) {
      if (input.isEmpty) return input;
      return toBeginningOfSentenceCase(input.toLowerCase()) ?? input;
    }

    await FirebaseFirestore.instance
        .collection('patient')
        .doc(widget.patientId)
        .collection('diagnoses')
        .add({
          'diagnosis': capitalize(diagnosis), // Capitalized diagnosis
          'description': capitalize(description), // Capitalized description
          'date': date,
        });

    await _logService.addLog(
      userId: userId,
      action: "Added Diagnosis $diagnosis to patient $patientName",
    );

    showToast('Diagnosis added successfully');
  }

  Future<void> _deleteDiagnosis(String diagnosisId) async {
    final user = _auth.currentUser;

    if (user == null) {
      showToast("User is not Authenticated");
      return;
    }

    final String userId = user.uid;

    final doc =
        await FirebaseFirestore.instance
            .collection('patient')
            .doc(widget.patientId)
            .collection('diagnoses')
            .doc(diagnosisId)
            .get();

    final String diagnosis = doc.data()?['diagnosis'] ?? 'Unknown Diagnosis';

    await FirebaseFirestore.instance
        .collection('patient')
        .doc(widget.patientId)
        .collection('diagnoses')
        .doc(diagnosisId)
        .delete();

    await _logService.addLog(
      userId: userId,
      action: "Removed Diagnosis $diagnosis from patient $patientName",
    );
  }

  void _showAddDiagnosisDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text('Add Previous Diagnosis', style: Textstyle.subheader),
              content: SizedBox(
                width: constraints.maxWidth * 1,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomTextField(
                        controller: diagnosisController,
                        focusNode: diagnosisFocusNode,
                        labelText: 'Previous Diagnosis',
                        enabled: true,
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Diagnosis is required'
                                    : null,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: descriptionController,
                        focusNode: descriptionFocusNode,
                        labelText: 'Description',
                        enabled: true,
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Description is required'
                                    : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: dateController,
                        focusNode: dateFocusNode,
                        style: Textstyle.body,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          filled: true,
                          fillColor: AppColors.gray,
                          suffixIcon: Icon(
                            Icons.calendar_today,
                            color:
                                dateFocusNode.hasFocus
                                    ? AppColors.neon
                                    : AppColors.black,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: AppColors.neon,
                              width: 2,
                            ),
                          ),
                          labelStyle: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                            color:
                                dateFocusNode.hasFocus
                                    ? AppColors.neon
                                    : AppColors.black,
                          ),
                        ),
                        validator:
                            (val) =>
                                _selectedDate == null
                                    ? 'Please select a date'
                                    : null,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _resetDateControllers();
                          Navigator.of(context).pop();
                        },
                        style: Buttonstyle.buttonRed,
                        child: Text('Cancel', style: Textstyle.smallButton),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final diagnosis = diagnosisController.text.trim();
                          final description = descriptionController.text.trim();

                          if (diagnosis.isNotEmpty &&
                              description.isNotEmpty &&
                              _selectedDate != null) {
                            await _addDiagnosis(
                              diagnosis,
                              description,
                              _selectedDate!,
                            );

                            _resetDateControllers();
                            Navigator.of(context).pop();
                            setState(() {});
                          } else {
                            showToast('Please fill all fields correctly.');
                          }
                        },
                        style: Buttonstyle.buttonNeon,
                        child: Text('Save', style: Textstyle.smallButton),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDiagnosisOptionsDialog(String diagnosisId) {
    showDialog(
      context: context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text('Options', style: Textstyle.subheader),
              content: SizedBox(
                width: constraints.maxWidth * 0.9,
                child: Text(
                  "Do you want to delete this record?",
                  style: Textstyle.body,
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _resetDateControllers();
                          Navigator.of(context).pop();
                        },
                        style: Buttonstyle.buttonNeon,
                        child: Text('Cancel', style: Textstyle.smallButton),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await _deleteDiagnosis(diagnosisId);
                          Navigator.of(context).pop();
                          setState(() {}); // Refresh the diagnoses list
                        },
                        style: Buttonstyle.buttonRed,
                        child: Text('Delete', style: Textstyle.smallButton),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNoHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, color: AppColors.black, size: 70),
          SizedBox(height: 20.0),
          Text("No Previous Diagnosis", style: Textstyle.body),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text("Patient History", style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: true,
        elevation: 0.0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: _toggleSortingOrder,
              child: Image.asset(
                isDescending
                    ? 'lib/assets/images/shared/navigation/date_ascending.png'
                    : 'lib/assets/images/shared/navigation/date_descending.png',
                height: 24,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getDiagnoses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }

          final diagnoses = snapshot.data ?? [];

          if (diagnoses.isEmpty) {
            // Show no history state if there are no diagnoses
            return _buildNoHistoryState();
          }

          // Sort the diagnoses list based on the current sorting order
          diagnoses.sort((a, b) {
            final dateA =
                a['date'] is Timestamp
                    ? (a['date'] as Timestamp).toDate()
                    : DateTime(0); // Default to epoch if no valid date
            final dateB =
                b['date'] is Timestamp
                    ? (b['date'] as Timestamp).toDate()
                    : DateTime(0); // Default to epoch if no valid date

            return isDescending
                ? dateB.compareTo(dateA) // Descending order
                : dateA.compareTo(dateB); // Ascending order
          });

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    color: AppColors.white,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: List.generate(diagnoses.length, (index) {
                        final diagnosis = diagnoses[index];
                        final diagnosisId = diagnosis['id'] as String? ?? '';
                        final diagnosisText =
                            diagnosis['diagnosis'] as String? ?? 'Unknown';
                        final description =
                            diagnosis['description'] as String? ??
                            'No description';
                        final diagnosisDate =
                            (diagnosis['date'] != null &&
                                    diagnosis['date'] is Timestamp)
                                ? DateFormat('MMMM dd, yyyy').format(
                                  (diagnosis['date'] as Timestamp).toDate(),
                                )
                                : 'Unknown date';

                        return GestureDetector(
                          onTap: () => _showDiagnosisOptionsDialog(diagnosisId),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10.0),
                            decoration: BoxDecoration(
                              color: AppColors.gray,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    0,
                                  ),
                                  child: Text(
                                    diagnosisDate,
                                    style: Textstyle.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Divider(),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Date",
                                        style: Textstyle.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        diagnosisText,
                                        style: Textstyle.body,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        "Description",
                                        style: Textstyle.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(description, style: Textstyle.body),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neon,
        onPressed: _showAddDiagnosisDialog,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}
