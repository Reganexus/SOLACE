import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:solace/screens/caregiver/caregiver_add_medicine.dart';
import 'package:solace/screens/caregiver/caregiver_add_task.dart';
import 'package:solace/screens/patient/patient_history.dart';
import 'package:solace/screens/patient/patient_intervention.dart';
import 'package:solace/screens/patient/patient_medicine.dart';
import 'package:solace/screens/patient/patient_note.dart';
import 'package:solace/screens/patient/patient_schedule.dart';
import 'package:solace/screens/patient/patient_tasks.dart';
import 'package:solace/screens/patient/patient_tracking.dart';
import 'package:solace/services/database.dart';
import 'package:solace/screens/patient/patient_contacts.dart';
import 'package:solace/themes/colors.dart';

class PatientsDashboard extends StatefulWidget {
  final String patientId;
  final String caregiverId;
  final String role;

  const PatientsDashboard({
    super.key,
    required this.patientId,
    required this.caregiverId, // Include in constructor
    required this.role,
  });

  @override
  State<PatientsDashboard> createState() => _PatientsDashboardState();
}

class _PatientsDashboardState extends State<PatientsDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  Map<String, dynamic>? patientData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPatientData();
    debugPrint("Patient Dashboard Patient ID: ${widget.patientId}");
    debugPrint("Patient Dashboard Caregiver ID: ${widget.caregiverId}");
  }

  final Map<String, Widget Function(String, String)> routes = {
    'Contacts': (caregiverId, patientId) => Contacts(patientId: patientId),
    'History': (caregiverId, patientId) => PatientHistory(patientId: patientId),
    'Intervention':
        (caregiverId, patientId) => PatientIntervention(patientId: patientId),
    'Medicine':
        (caregiverId, patientId) => PatientMedicine(patientId: patientId),
    'Notes': (caregiverId, patientId) => PatientNote(patientId: patientId),
    'Schedules':
        (caregiverId, patientId) => PatientSchedule(patientId: patientId),
    'Tasks': (caregiverId, patientId) => PatientTasks(patientId: patientId),
    'Tracking':
        (caregiverId, patientId) => PatientTracking(patientId: patientId),
  };

  final List<Map<String, dynamic>> gridItems = [
    {'label': 'Contacts', 'icon': Icons.contact_page_rounded},
    {'label': 'History', 'icon': Icons.history},
    {'label': 'Intervention', 'icon': Icons.healing},
    {'label': 'Medicine', 'icon': Icons.medical_services_rounded},
    {'label': 'Notes', 'icon': Icons.create_rounded},
    {'label': 'Schedules', 'icon': Icons.calendar_today},
    {'label': 'Tasks', 'icon': Icons.task},
    {'label': 'Tracking', 'icon': Icons.monitor_heart_rounded},
  ];

  Future<void> fetchPatientData() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(widget.patientId)
              .get();

      if (snapshot.exists) {
        setState(() {
          patientData = snapshot.data();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Patient data not found.")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching patient data: $e")),
      );
    }
  }

  List<Widget> _buildAlternatingItems(
    BuildContext context,
    String caregiverId,
    String patientId,
  ) {
    final List<Widget> items = [];
    for (int i = 0; i < gridItems.length; i += 4) {
      final iconBatch = gridItems.skip(i).take(4).toList();

      // Add a Row combining icons and their labels
      items.add(
        Padding(
          padding: const EdgeInsets.only(
            bottom: 20,
          ), // Adjust spacing between batches
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              iconBatch.length * 2 - 1, // Include spaces between items
              (index) {
                if (index.isEven) {
                  // Icon and label container
                  final item = iconBatch[index ~/ 2];
                  return Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => routes[item['label']]!(
                                      caregiverId,
                                      patientId,
                                    ),
                              ),
                            );
                          },
                          child: _buildIconContainer(item['icon']),
                        ),
                        const SizedBox(
                          height: 5,
                        ), // Adjust spacing between icon and label
                        Text(
                          item['label'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Spacer between items
                  return const SizedBox(width: 10);
                }
              },
            ),
          ),
        ),
      );
    }
    return items;
  }

  Widget _buildIconContainer(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Icon(icon, size: 28, color: AppColors.black),
    );
  }

  Widget _buildActions(String role) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              _scheduleAppointment(widget.caregiverId, widget.patientId);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: AppColors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Schedule',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ViewPatientTask(patientId: widget.patientId),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: AppColors.darkpurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Add Task',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        if (role == 'doctor') ...[
          const SizedBox(width: 10.0), // Add spacing for the doctor role
          Expanded(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            ViewPatientMedicine(patientId: widget.patientId),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                backgroundColor: AppColors.darkblue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Add Med',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _scheduleAppointment(
    String caregiverId,
    String patientId,
  ) async {
    if (!mounted) return; // Ensure the widget is still mounted
    final DateTime today = DateTime.now();

    // Show the customized date picker
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(today.year, today.month + 3),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.neon,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.neon),
            ),
            dialogTheme: DialogThemeData(backgroundColor: AppColors.white),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || selectedDate == null) {
      return; // Ensure widget is still mounted
    }

    // Show the customized time picker
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

    if (!mounted || selectedTime == null) {
      return; // Ensure widget is still mounted
    }

    // Combine the selected date and time into a single DateTime object
    final DateTime scheduledDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Generate a single scheduleId to use for both caregiver and patient
    final String scheduleId =
        FirebaseFirestore.instance.collection('_').doc().id;

    try {
      debugPrint("Schedule caregiverId: $caregiverId");
      debugPrint("Schedule scheduledDateTime: $scheduledDateTime");
      debugPrint("Schedule patientId: $patientId");
      debugPrint("Schedule scheduleId: $scheduleId");

      // Save schedule in Firestore for both caregiver and patient
      await _databaseService.saveScheduleForCaregiver(
        caregiverId,
        scheduledDateTime,
        patientId,
        scheduleId,
      );
      await _databaseService.saveScheduleForPatient(
        patientId,
        scheduledDateTime,
        caregiverId,
        scheduleId,
      );
      debugPrint("Schedule saved for both caregiver and patient.");

      // Show success Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Appointment successfully scheduled!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Failed to save schedule: $e");

      // Show error Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to schedule appointment. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Patient Status',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection(
                          'patient',
                        ) // Assuming you have a 'patient' collection
                        .doc(
                          widget.patientId,
                        ) // Document ID for the current user (patient)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Error fetching data'));
                  }

                  // Extract patient data and status directly
                  final patientData =
                      snapshot.data?.data() as Map<String, dynamic>?;
                  final status =
                      patientData?['status'] ??
                      'stable'; // Default to 'stable' if null
                  final isUnstable = status == 'unstable';
                  final isUnavailable = patientData == null;

                  final statusMessage =
                      isUnavailable
                          ? 'No status yet'
                          : isUnstable
                          ? '⚠️ Symptoms detected. Please consult your doctor.'
                          : 'ⓘ No symptoms detected. Keep up the good work!';
                  final backgroundColor =
                      isUnavailable
                          ? AppColors.blackTransparent
                          : isUnstable
                          ? AppColors.red
                          : AppColors.neon;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 20.0,
                                horizontal: 15.0,
                              ),
                              child: Text(
                                isUnavailable
                                    ? 'Unavailable'
                                    : isUnstable
                                    ? 'Unstable'
                                    : 'Stable',
                                style: const TextStyle(
                                  fontSize: 50.0,
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12.0),
                              decoration: const BoxDecoration(
                                color: AppColors.blackTransparent,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(10.0),
                                  bottomRight: Radius.circular(10.0),
                                ),
                              ),
                              child: Text(
                                statusMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Spacer
              const SizedBox(height: 20.0),

              _buildActions(widget.role),

              // Spacer
              const SizedBox(height: 20.0),

              ..._buildAlternatingItems(
                context,
                widget.caregiverId,
                widget.patientId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
