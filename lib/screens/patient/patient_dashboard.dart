import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:solace/screens/caregiver/caregiver_add_medicine.dart';
import 'package:solace/screens/caregiver/caregiver_add_task.dart';
import 'package:solace/screens/patient/patient_edit.dart';
import 'package:solace/screens/patient/patient_history.dart';
import 'package:solace/screens/patient/patient_intervention.dart';
import 'package:solace/screens/patient/patient_note.dart';
import 'package:solace/screens/patient/patient_stream.dart';
import 'package:solace/screens/patient/patient_tracking.dart';
import 'package:solace/services/database.dart';
import 'package:solace/screens/patient/patient_contacts.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:solace/utility/schedule_utility.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:solace/shared/globals.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

class VitalStatus {
  final Color color;
  final IconData? icon;
  final String label;

  VitalStatus({required this.color, this.icon, required this.label});
}

class _PatientsDashboardState extends State<PatientsDashboard> {
  DatabaseService databaseService = DatabaseService();
  ScheduleUtility scheduleUtility = ScheduleUtility();
  Map<String, dynamic>? patientData;
  bool isLoading = true;
  late final PageController _pageController;

  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchPatientData();
    _startTimer();
    _pageController = PageController(initialPage: 0);
    debugPrint("Patient Dashboard Patient ID: ${widget.patientId}");
    debugPrint("Patient Dashboard Caregiver ID: ${widget.caregiverId}");
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 60), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  Future<void> fetchPatientData() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(widget.patientId)
              .get();

      if (snapshot.exists) {
        if (mounted) {
          setState(() {
            patientData = snapshot.data();
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Patient data not found.")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching patient data: $e")),
      );
    }
  }

  VitalStatus getVitalStatus(String key, dynamic value) {
    if (key == 'Blood Pressure' && value is String) {
      final parts = value.split('/');
      if (parts.length == 2) {
        final systolic = int.tryParse(parts[0]) ?? 0;
        final diastolic = int.tryParse(parts[1]) ?? 0;

        final systolicStatus = getVitalStatus('Blood Pressure (Systolic)', systolic);
        final diastolicStatus = getVitalStatus('Blood Pressure (Diastolic)', diastolic);

        return systolicStatus.color == Colors.red || diastolicStatus.color == Colors.red
            ? systolicStatus.color == Colors.red ? systolicStatus : diastolicStatus
            : systolicStatus.color == Colors.yellow || diastolicStatus.color == Colors.yellow
                ? systolicStatus.color == Colors.yellow ? systolicStatus : diastolicStatus
                : VitalStatus(color: Colors.white, label: "Normal");
      }
    }

    // Convert value to num safely
    final numValue = (value is num) ? value : num.tryParse(value.toString()) ?? 0;

    switch (key) {
      case 'Heart Rate':
        if (numValue < minExtremeHeartRate) return VitalStatus(color: Colors.red, icon: LucideIcons.alertTriangle, label: "Very Low");
        if (numValue < minNormalHeartRate) return VitalStatus(color: Colors.yellow, icon: LucideIcons.alertCircle, label: "Low");
        if (numValue > maxNormalHeartRate) return VitalStatus(color: Colors.yellow, icon: LucideIcons.alertCircle, label: "High");
        if (numValue > maxExtremeHeartRate) return VitalStatus(color: Colors.red, icon: LucideIcons.alertTriangle, label: "Very High");
        break;

      case 'Blood Pressure (Systolic)':
        if (numValue < minExtremeBloodPressureSystolic) return VitalStatus(color: Colors.red, icon: LucideIcons.alertTriangle, label: "Very Low");
        if (numValue < minNormalBloodPressureSystolic) return VitalStatus(color: Colors.yellow, icon: LucideIcons.alertCircle, label: "Low");
        if (numValue > maxNormalBloodPressureSystolic) return VitalStatus(color: Colors.yellow, icon: LucideIcons.alertCircle, label: "High");
        if (numValue > maxExtremeBloodPressureSystolic) return VitalStatus(color: Colors.red, icon: LucideIcons.alertTriangle, label: "Very High");
        break;

      case 'Blood Pressure (Diastolic)':
        if (numValue < minExtremeBloodPressureDiastolic) return VitalStatus(color: Colors.red, icon: LucideIcons.alertTriangle, label: "Very Low");
        if (numValue < minNormalBloodPressureDiastolic) return VitalStatus(color: Colors.yellow, icon: LucideIcons.alertCircle, label: "Low");
        if (numValue > maxNormalBloodPressureDiastolic) return VitalStatus(color: Colors.yellow, icon: LucideIcons.alertCircle, label: "High");
        if (numValue > maxExtremeBloodPressureDiastolic) return VitalStatus(color: Colors.red, icon: LucideIcons.alertTriangle, label: "Very High");
        break;

      case 'Oxygen Saturation':
        if (numValue < minExtremeOxygenSaturation) return VitalStatus(color: Colors.red, icon: LucideIcons.alertTriangle, label: "Very Low");
        if (numValue < minNormalOxygenSaturation) return VitalStatus(color: Colors.yellow, icon: LucideIcons.alertCircle, label: "Low");
        break;

      case 'Respiration':
        if (numValue < minExtremeRespirationRate) return VitalStatus(color: Colors.red, icon: LucideIcons.alertTriangle, label: "Very Low");
        if (numValue < minNormalRespirationRate) return VitalStatus(color: Colors.yellow, icon: LucideIcons.alertCircle, label: "Low");
        if (numValue > maxNormalRespirationRate) return VitalStatus(color: Colors.yellow, icon: LucideIcons.alertCircle, label: "High");
        if (numValue > maxExtremeRespirationRate) return VitalStatus(color: Colors.red, icon: LucideIcons.alertTriangle, label: "Very High");
        break;

      case 'Temperature':
        if (numValue < minExtremeTemperature) return VitalStatus(color: Colors.red, icon: LucideIcons.alertTriangle, label: "Very Low");
        if (numValue < minNormalTemperature) return VitalStatus(color: Colors.yellow, icon: LucideIcons.alertCircle, label: "Low");
        if (numValue > maxNormalTemperature) return VitalStatus(color: Colors.yellow, icon: LucideIcons.alertCircle, label: "High");
        if (numValue > maxExtremeTemperature) return VitalStatus(color: Colors.red, icon: LucideIcons.alertTriangle, label: "Very High");
        break;

      case 'Pain':
        if (numValue > maxExtremeScale) return VitalStatus(color: Colors.red, icon: LucideIcons.alertTriangle, label: "Very High");
        if (numValue > maxNormalScale) return VitalStatus(color: Colors.yellow, icon: LucideIcons.alertCircle, label: "High");
        break;
    }

    return VitalStatus(color: Colors.white, label: "Normal");
  }

  String _convertPredictionKeyToName(String key) {
    if (key.startsWith('bloodpressure_t')) return 'Blood Pressure';
    if (key.startsWith('heartrate_t')) return 'Heart Rate';
    if (key.startsWith('respiration_t')) return 'Respiration';
    if (key.startsWith('sao2_t')) return 'Oxygen Saturation';
    if (key.startsWith('temperature_t')) return 'Temperature';
    return key;
  }

  String _getVitalUnit(String key) {
    return {
      'Heart Rate': ' bpm',
      'Blood Pressure': ' mmHg',
      'Oxygen Saturation': '%',
      'Respiration': ' breaths/min',
      'Temperature': '°C',
      'Pain': '/10',
    }[key] ?? '';
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.inHours > 1) {
      return '${duration.inHours} hours';
    } else if (duration.inHours == 1) {
      return '1 hour';
    } else if (duration.inMinutes > 1) {
      return '${duration.inMinutes} minutes';
    } else {
      return 'Less than a minute';
    }
  }

  Widget _buildScheduleContainer() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/images/auth/calendar.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(color: AppColors.black.withValues(alpha: 0.4)),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Schedule Patient',
                style: Textstyle.heading.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Set appointments and visit to the patient at a particular time and day.',
                style: Textstyle.body.copyWith(color: AppColors.white),
              ),

              SizedBox(
                width: 200,
                child: TextButton(
                  onPressed: () {
                    _scheduleAppointment(widget.caregiverId, widget.patientId);
                  },
                  style: Buttonstyle.buttonDarkGray,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Schedule',
                        style: Textstyle.smallButton.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit_calendar,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskContainer() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/images/auth/task.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(color: AppColors.black.withValues(alpha: 0.4)),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Set Task',
                style: Textstyle.heading.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Set tasks for the patient to do.',
                style: Textstyle.body.copyWith(color: AppColors.white),
              ),

              SizedBox(
                width: 200,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ViewPatientTask(patientId: widget.patientId),
                      ),
                    );
                  },
                  style: Buttonstyle.buttonDarkGray,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Give Task',
                        style: Textstyle.smallButton.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit_calendar,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineContainer() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/images/auth/medicine.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(color: AppColors.black.withValues(alpha: 0.4)),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Prescribe Medicine',
                style: Textstyle.heading.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Give medications to the patient to take.',
                style: Textstyle.body.copyWith(color: AppColors.white),
              ),

              SizedBox(
                width: 200,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ViewPatientMedicine(
                              patientId: widget.patientId,
                            ),
                      ),
                    );
                  },
                  style: Buttonstyle.buttonDarkGray,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Prescribe Medicine',
                        style: Textstyle.smallButton.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.medical_services_rounded,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTracking() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/images/auth/tracking.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(color: AppColors.black.withValues(alpha: 0.4)),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Track Patient',
                style: Textstyle.heading.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Give inputs to monitor and track patient symptom flare-ups and vitals.',
                style: Textstyle.body.copyWith(color: AppColors.white),
              ),

              SizedBox(
                width: 200,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                PatientTracking(patientId: widget.patientId),
                      ),
                    );
                  },
                  style: Buttonstyle.buttonDarkGray,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Track Patient',
                        style: Textstyle.smallButton.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.monitor_heart_rounded,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/images/auth/notes.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(color: AppColors.black.withValues(alpha: 0.4)),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Take Notes',
                style: Textstyle.heading.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Add notes to the current events and changes in the condition of patient.',
                style: Textstyle.body.copyWith(color: AppColors.white),
              ),

              SizedBox(
                width: 200,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                PatientNote(patientId: widget.patientId),
                      ),
                    );
                  },
                  style: Buttonstyle.buttonDarkGray,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Add Note',
                        style: Textstyle.smallButton.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit_calendar_rounded,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(String role) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What you can do", style: Textstyle.subheader),
          const SizedBox(height: 10.0),
          Text(
            "Listed below are the features you can use to effectively monitor and manage the patient.",
            style: Textstyle.body,
          ),
          const SizedBox(height: 20.0),
          _buildTracking(),
          const SizedBox(height: 10.0),
          _buildNotes(),
          const SizedBox(height: 10.0),
          _buildScheduleContainer(),
          const SizedBox(height: 10.0),
          _buildTaskContainer(),
          if (role == 'doctor') ...[
            const SizedBox(height: 10.0),
            _buildMedicineContainer(),
          ],
        ],
      ),
    );
  }

  Widget _buildInterventions() {
    return PatientInterventions(patientId: widget.patientId);
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
      final caregiverRole = await databaseService.fetchAndCacheUserRole(
        caregiverId,
      );
      final patientRole = await databaseService.fetchAndCacheUserRole(
        patientId,
      );

      if (caregiverRole == null || patientRole == null) {
        debugPrint("Failed to fetch roles. Caregiver or patient role is null.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to schedule. Roles not found.")),
        );
        return;
      }

      await scheduleUtility.saveSchedule(
        userId: caregiverId,
        scheduleId: scheduleId,
        subCollectionName: 'schedules',
        scheduledDateTime: scheduledDateTime,
        extraData: {'patientId': patientId},
        collectionName: caregiverRole,
      );

      await scheduleUtility.saveSchedule(
        userId: patientId,
        scheduleId: scheduleId,
        subCollectionName: 'schedules',
        scheduledDateTime: scheduledDateTime,
        extraData: {'caregiverId': caregiverId},
        collectionName: patientRole,
      );

      debugPrint("Schedule saved for both caregiver and patient.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment successfully scheduled!')),
      );
    } catch (e) {
      debugPrint("Failed to save schedule: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to schedule appointment.")),
      );
    }
  }

  Widget _buildPatientStatus() {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('patient') // Assuming you have a 'patient' collection
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
        final patientData = snapshot.data?.data() as Map<String, dynamic>?;
        final status =
            patientData?['status'] ?? 'stable'; // Default to 'stable' if null
        final isUnstable = status == 'unstable';
        final isUnavailable = patientData == null;
        final String name =
            '${patientData?['firstName']} ${patientData?['lastName']}';
        final backgroundColor =
            isUnavailable
                ? AppColors.blackTransparent
                : isUnstable
                ? AppColors.red
                : AppColors.neon;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: backgroundColor,
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 30),
                        Text(
                          name,
                          style: Textstyle.bodyWhite.copyWith(fontSize: 20),
                        ),
                        Text(
                          isUnavailable
                              ? 'Unavailable'
                              : isUnstable
                              ? 'Unstable'
                              : 'Stable',
                          style: Textstyle.heading.copyWith(
                            fontSize: 40,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PatientHistory(
                                          patientId: widget.patientId,
                                        ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    'View Patient History',
                                    style: Textstyle.bodyWhite.copyWith(
                                      fontSize: 16,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.white,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: AppColors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    color: AppColors.black.withValues(alpha: 0.8),
                    child: _buildVitals(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVitals() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tracking')
          .doc(widget.patientId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching vitals data'));
        }

        final trackingData = snapshot.data?.data() as Map<String, dynamic>?;
        final trackingArray = trackingData?['tracking'] as List<dynamic>?;

        if (trackingArray == null || trackingArray.isEmpty) {
          return Center(
            child: Text(
              'No recent vitals. Track symptoms now',
              style: TextStyle(color: AppColors.white),
            ),
          );
        }

        final lastElement = trackingArray.last as Map<String, dynamic>;
        final vitals = lastElement['Vitals'] as Map<String, dynamic>?;
        final timestamp = lastElement['timestamp'] as Timestamp?;

        if (vitals == null || timestamp == null) {
          return const Center(child: Text('Incomplete vitals data'));
        }

        final formattedTimestamp = timeago.format(timestamp.toDate());

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('patient') // Corrected collection name
              .doc(widget.patientId)
              .get(), // Fetch predictions once
          builder: (context, predictionSnapshot) {
            if (predictionSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (predictionSnapshot.hasError) {
              return const Center(child: Text('Error fetching predictions'));
            }

            final predictionsData = predictionSnapshot.data?.data() as Map<String, dynamic>?;
            final predictionsArray = predictionsData?['predictions'] as List<dynamic>?;

            Map<String, dynamic> criticalPredictions = {};
            Map<String, String> predictionTimes = {};

            if (predictionsArray != null && predictionsArray.isNotEmpty) {
              for (var prediction in predictionsArray) {
                final predMap = prediction as Map<String, dynamic>;
                final predictionTimestamp = (predMap['timestamp'] as Timestamp?)?.toDate();

                if (predictionTimestamp == null) continue;

                // Define future time intervals
                final timeIntervals = {
                  't+1': predictionTimestamp.add(Duration(hours: 1)),
                  't+2': predictionTimestamp.add(Duration(hours: 6)),
                  't+3': predictionTimestamp.add(Duration(hours: 12)),
                };

                for (var key in predMap.keys) {
                  if (!key.startsWith('bloodpressure_t') &&
                      !key.startsWith('heartrate_t') &&
                      !key.startsWith('respiration_t') &&
                      !key.startsWith('sao2_t') &&
                      !key.startsWith('temperature_t')) {
                    continue;
                  }

                  final value = predMap[key];
                  final status = getVitalStatus(_convertPredictionKeyToName(key), value);

                  if (status.color == Colors.red || status.color == Colors.yellow) {
                    // Extract the time step (t+1, t+2, t+3)
                    final match = RegExp(r't\+(\d+)').firstMatch(key);
                    if (match != null) {
                      final timeKey = 't+${match.group(1)}';
                      final futureTime = timeIntervals[timeKey];

                      if (futureTime != null) {
                        final remainingTime = futureTime.difference(_currentTime);

                        if (!criticalPredictions.containsKey(_convertPredictionKeyToName(key))) {
                          criticalPredictions[_convertPredictionKeyToName(key)] = value;
                          predictionTimes[_convertPredictionKeyToName(key)] =
                              _formatRemainingTime(remainingTime);
                        }
                      }
                    }
                  }
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last updated: $formattedTimestamp',
                  style: TextStyle(
                    color: AppColors.white,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 10),

                // Display current vitals
                ...vitals.entries.map((entry) {
                  final unit = _getVitalUnit(entry.key);
                  final dynamic rawValue = entry.value;
                  final num? value = rawValue is num ? rawValue : num.tryParse(rawValue.toString());

                  final status = (value != null) ? getVitalStatus(entry.key, value) : VitalStatus(color: Colors.white, label: "N/A");

                  return _buildVitalRow(entry.key, rawValue.toString(), unit, status);
                }),

                // Display earliest predicted critical vitals
                if (criticalPredictions.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Text(
                    'Predicted Critical Vitals',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  ...criticalPredictions.entries.map((entry) {
                    final unit = _getVitalUnit(entry.key);
                    final status = getVitalStatus(entry.key, entry.value);
                    final timeRemaining = predictionTimes[entry.key] ?? "Unknown";

                    return _buildVitalRow(
                      entry.key,
                      '(in $timeRemaining) ${entry.value}',
                      unit,
                      status,
                    );
                  }),
                ],
              ],
            );
          },
        );
      },
    );
  }

  // Extracted UI function to avoid repetition
  Widget _buildVitalRow(String key, String value, String unit, VitalStatus status) {
    return Row(
      children: [
        Expanded(
          child: Text(
            key,
            style: TextStyle(color: AppColors.white),
          ),
        ),
        Row(
          children: [
            Text(
              '$value$unit',
              style: TextStyle(
                color: status.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (status.icon != null) ...[
              SizedBox(width: 5),
              Icon(status.icon, color: status.color, size: 16),
              SizedBox(width: 5),
              Text(
                status.label,
                style: TextStyle(color: status.color, fontSize: 12),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCarousel() {
    return CarouselWidget(
      pageController: _pageController,
      patientId: widget.patientId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Patient Status', style: Textstyle.subheader),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Contacts(patientId: widget.patientId),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.perm_contact_cal_rounded, size: 20, color: AppColors.black),
                      SizedBox(width: 5),
                      Text("Contacts", style: TextStyle(fontSize: 12, color: AppColors.black)),
                    ],
                  ),
                ),
                SizedBox(width: 15),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPatient(patientId: widget.patientId),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: AppColors.black),
                      SizedBox(width: 5),
                      Text("Edit Profile", style: TextStyle(fontSize: 12, color: AppColors.black)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientStatus(),
            _buildActions(widget.role),
            const SizedBox(height: 20.0),
            Divider(),
            _buildInterventions(),
            const SizedBox(height: 20.0),
            _buildCarousel(),
          ],
        ),
      ),
    );
  }
}
