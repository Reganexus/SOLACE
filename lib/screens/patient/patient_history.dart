// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:solace/themes/colors.dart';

class PatientHistory extends StatefulWidget {
  final String patientId;

  const PatientHistory({super.key, required this.patientId});

  @override
  _PatientHistoryState createState() => _PatientHistoryState();
}

class _PatientHistoryState extends State<PatientHistory> {
  DateTime? _selectedDate;
  bool isDescending = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = null;
    dateController.text =
        _selectedDate != null ? _formatDate(_selectedDate!) : '';
    _resetDateControllers();
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

  InputDecoration _buildInputDecoration(String label, FocusNode focusNode) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.gray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.neon, width: 2),
      ),
      labelStyle: TextStyle(
        fontSize: 16,
        fontFamily: 'Inter',
        fontWeight: FontWeight.normal,
        color: focusNode.hasFocus ? AppColors.neon : AppColors.black,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(1900),
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
        dateController.text = _formatDate(_selectedDate!);
      });
    }
  }

  String _formatDate(DateTime date) {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
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

  Future<void> _addDiagnosis(
    String diagnosis,
    String description,
    DateTime date,
  ) async {
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
  }

  Future<void> _deleteDiagnosis(String diagnosisId) async {
    await FirebaseFirestore.instance
        .collection('patient')
        .doc(widget.patientId)
        .collection('diagnoses')
        .doc(diagnosisId)
        .delete();
  }

  void _showAddDiagnosisDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: const Text(
                'Add Previous Diagnosis',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              content: SizedBox(
                width: constraints.maxWidth * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: diagnosisController,
                        focusNode: diagnosisFocusNode,
                        decoration: _buildInputDecoration(
                          'Previous Diagnosis',
                          diagnosisFocusNode,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.normal,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: descriptionController,
                        focusNode: descriptionFocusNode,
                        decoration: _buildInputDecoration(
                          'Description',
                          descriptionFocusNode,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.normal,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: dateController,
                        focusNode: dateFocusNode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.normal,
                          color: AppColors.black,
                        ),
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
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          backgroundColor: AppColors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.white,
                          ),
                        ),
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
                            // Save _selectedDate to the database
                            await _addDiagnosis(
                              diagnosis,
                              description,
                              _selectedDate!,
                            );

                            _resetDateControllers();
                            Navigator.of(context).pop();
                            setState(() {});
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill all fields correctly.',
                                ),
                              ),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          backgroundColor: AppColors.neon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Save',
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
              title: const Text(
                'Options',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              content: SizedBox(
                width: constraints.maxWidth * 0.9,
                child: Text(
                  "Do you want to delete this record?",
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
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
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          backgroundColor: AppColors.neon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.white,
                          ),
                        ),
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
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          backgroundColor: AppColors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Delete',
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
        children: const [
          Icon(Icons.event_busy, color: AppColors.black, size: 80),
          SizedBox(height: 20.0),
          Text(
            "No Previous Diagnosis",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          "Patient History",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: true,
        elevation: 0.0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 25.0),
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
                    padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gray,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.file_copy_rounded, size: 25),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        diagnosisDate,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                const Divider(thickness: 1.0),
                                const SizedBox(height: 5),
                                const Text(
                                  "Date",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                                Text(
                                  diagnosisText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.normal,
                                    color: AppColors.black,
                                  ),
                                ),
                                SizedBox(height: 10),
                                const Text(
                                  "Description",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.normal,
                                    color: AppColors.black,
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
