// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:solace/controllers/notification_service.dart';
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
  final NotificationService notificationService = NotificationService();
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

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
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
      showToast("User is not Authenticated", backgroundColor: AppColors.red);
      return;
    }

    if (user.uid == null) {
      showToast("User ID is null", backgroundColor: AppColors.red);
      return;
    }

    final String userId = user.uid;
    final String? caregiverRole = await databaseService.fetchAndCacheUserRole(
      userId,
    );

    try {
      final String role =
          '${caregiverRole?.substring(0, 1).toUpperCase()}${caregiverRole?.substring(1)}';
      final String? caregiverName = await databaseService.fetchUserName(userId);
      final String? patientName = await databaseService.fetchUserName(
        widget.patientId,
      );

      await FirebaseFirestore.instance
          .collection('patient')
          .doc(widget.patientId)
          .collection('diagnoses')
          .add({
            'diagnosis': diagnosis,
            'description': description
                .split(RegExp(r'\s+'))
                .map(
                  (word) =>
                      word.isNotEmpty
                          ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                          : '',
                )
                .join(' '),
            'date': date,
          });

      await _logService.addLog(
        userId: userId,
        action: "Added Diagnosis $diagnosis to patient $patientName",
      );

      await notificationService.sendInAppNotificationToTaggedUsers(
        patientId: widget.patientId,
        currentUserId: userId,
        notificationMessage:
            "$role $caregiverName added a diagnosis to patient $patientName.",
        type: "update",
      );

      await notificationService.sendNotificationToTaggedUsers(
        widget.patientId,
        "Diagnosis Update",
        "$role $caregiverName added a diagnosis to patient $patientName.",
      );

      if (mounted) {
        showToast('Diagnosis added successfully');
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        showToast(
          'Failed to add diagnosis: $e',
          backgroundColor: AppColors.red,
        );
      }
    }
  }

  Future<void> _deleteDiagnosis(String diagnosisId) async {
    final user = _auth.currentUser;

    if (user == null) {
      showToast("User is not Authenticated", backgroundColor: AppColors.red);
      return;
    }

    final String userId = user.uid;
    final String? caregiverRole = await databaseService.fetchAndCacheUserRole(
      userId,
    );
    final String role =
        '${caregiverRole?.substring(0, 1).toUpperCase()}${caregiverRole?.substring(1)}';
    final String? caregiverName = await databaseService.fetchUserName(userId);
    final String? patientName = await databaseService.fetchUserName(
      widget.patientId,
    );

    try {
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

      await notificationService.sendInAppNotificationToTaggedUsers(
        patientId: widget.patientId,
        currentUserId: userId,
        notificationMessage:
            "$role $caregiverName removed a diagnosis to patient $patientName.",
        type: "update",
      );

      await notificationService.sendNotificationToTaggedUsers(
        widget.patientId,
        "Diagnosis Update",
        "$role $caregiverName removed a diagnosis to patient $patientName.",
      );

      if (mounted) {
        showToast('Diagnosis removed successfully');
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        showToast(
          'Failed to delete diagnosis: $e',
          backgroundColor: AppColors.red,
        );
      }
    }
  }

  Future<void> _showAddDiagnosisDialog() async {
    diagnosisController.clear();
    descriptionController.clear();
    dateController.clear();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return AlertDialog(
                  backgroundColor: AppColors.white,
                  content: SizedBox(
                    width: constraints.maxWidth * 1,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Add Previous Diagnosis',
                            style: Textstyle.subheader,
                          ),
                          Text(
                            "Fields marked with * are required.",
                            style: Textstyle.body,
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: diagnosisController,
                            focusNode: diagnosisFocusNode,
                            labelText: 'Diagnosis *',
                            enabled: !isSaving,
                            validator:
                                (val) =>
                                    val == null || val.isEmpty
                                        ? 'Diagnosis is required'
                                        : null,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(50),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: descriptionController,
                            focusNode: descriptionFocusNode,
                            labelText: 'Diagnosis Description',
                            enabled: !isSaving,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(200),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: dateController,
                            focusNode: dateFocusNode,
                            style: Textstyle.body,
                            decoration: InputDecoration(
                              labelText: 'Diagnosis Date *',
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
                            onTap:
                                !isSaving ? () => _selectDate(context) : null,
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
                            onPressed:
                                !isSaving
                                    ? () async {
                                      Navigator.of(context).pop();
                                    }
                                    : null,
                            style:
                                isSaving
                                    ? Buttonstyle.buttonGray
                                    : Buttonstyle.buttonRed,
                            child: Text('Cancel', style: Textstyle.smallButton),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            onPressed:
                                isSaving
                                    ? null
                                    : () async {
                                      final confirmed =
                                          await showConfirmationDialog(
                                            context,
                                            'add',
                                          );
                                      if (!confirmed) return;

                                      setState(() {
                                        isSaving = true; // Set saving state
                                      });

                                      String diagnosis =
                                          diagnosisController.text.trim();
                                      String description =
                                          descriptionController.text.trim();

                                      diagnosis = diagnosis
                                          .split(RegExp(r'\s+'))
                                          .map(
                                            (word) =>
                                                word.isNotEmpty
                                                    ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                                                    : '',
                                          )
                                          .join(' ');

                                      if (diagnosis.isEmpty) {
                                        showToast(
                                          'Please specify the diagnosis.',
                                          backgroundColor: AppColors.red,
                                        );
                                      } else if (_selectedDate == null) {
                                        showToast(
                                          'Please specify the diagnosis date.',
                                          backgroundColor: AppColors.red,
                                        );
                                      } else {
                                        await _addDiagnosis(
                                          diagnosis,
                                          description,
                                          _selectedDate!,
                                        );

                                        _getDiagnoses();

                                        if (mounted) {
                                          _resetDateControllers();
                                          Navigator.of(context).pop();
                                        }
                                      }

                                      setState(() {
                                        isSaving = false;
                                      });
                                    },
                            style: Buttonstyle.buttonNeon,
                            child:
                                isSaving
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(
                                          AppColors.white,
                                        ),
                                      ),
                                    )
                                    : Text(
                                      'Save',
                                      style: Textstyle.smallButton,
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
      },
    );
  }

  Future<void> _showDiagnosisOptionsDialog(String diagnosisId) async {
    bool isDeleting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return AlertDialog(
                  backgroundColor: AppColors.white,
                  title: Text('Options', style: Textstyle.subheader),
                  content: SizedBox(
                    width: constraints.maxWidth * 0.9,
                    child: Text(
                      "Are you sure you want to delete this record?",
                      style: Textstyle.body,
                    ),
                  ),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed:
                                isDeleting
                                    ? null
                                    : () {
                                      Navigator.of(context).pop();
                                    },
                            style:
                                isDeleting
                                    ? Buttonstyle.buttonGray
                                    : Buttonstyle.buttonNeon,
                            child: Text('Cancel', style: Textstyle.smallButton),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            onPressed:
                                isDeleting
                                    ? null
                                    : () async {
                                      final confirmed =
                                          await showConfirmationDialog(
                                            context,
                                            'delete',
                                          );
                                      if (!confirmed) return;

                                      setState(() {
                                        isDeleting = true; // Set deleting state
                                      });

                                      await _deleteDiagnosis(diagnosisId);
                                      _getDiagnoses();

                                      if (Navigator.of(context).canPop()) {
                                        Navigator.of(context).pop();
                                      }

                                      setState(() {
                                        isDeleting =
                                            false; // Reset deleting state
                                      });
                                    },
                            style: Buttonstyle.buttonRed,
                            child:
                                isDeleting
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(
                                          AppColors.white,
                                        ),
                                      ),
                                    )
                                    : Text(
                                      'Delete',
                                      style: Textstyle.smallButton,
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
      },
    );
  }

  Future<bool> showDiscardConfirmationDialog(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text('Discard Changes?', style: Textstyle.subheader),
          content: Text(
            'You have unsaved changes. Do you want to discard them?',
            style: Textstyle.body,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: Buttonstyle.buttonNeon,
                    child: Text('Cancel', style: Textstyle.smallButton),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: Buttonstyle.buttonRed,
                    child: Text('Discard', style: Textstyle.smallButton),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<bool> showConfirmationDialog(BuildContext context, String flag) async {
    String message = '';
    String buttonText = '';
    if (flag == 'delete') {
      message = 'Are you sure you want to delete this diagnosis?';
      buttonText = 'Delete';
    } else if (flag == 'add') {
      message = 'Are you sure you want to add this diagnosis?';
      buttonText = 'Add';
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text('Confirmation', style: Textstyle.subheader),
          content: Text(message, style: Textstyle.body),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style:
                        flag == 'delete'
                            ? Buttonstyle.buttonNeon
                            : Buttonstyle.buttonRed,
                    child: Text('Cancel', style: Textstyle.smallButton),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style:
                        flag == 'delete'
                            ? Buttonstyle.buttonRed
                            : Buttonstyle.buttonNeon,
                    child: Text(buttonText, style: Textstyle.smallButton),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    return confirmed == true;
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
        centerTitle: true,
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
                                    diagnosisText,
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
                                        "Diagnosis Date",
                                        style: Textstyle.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        diagnosisDate,
                                        style: Textstyle.body,
                                      ),
                                      if (description.isNotEmpty) ...[
                                        SizedBox(height: 10),
                                        Text(
                                          "Description",
                                          style: Textstyle.body.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          description,
                                          style: Textstyle.body,
                                        ),
                                      ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDiagnosisDialog,
        backgroundColor: AppColors.neon,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Medical Record'),
      ),
    );
  }
}
