// ignore_for_file: avoid_print

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
import 'package:solace/services/log_service.dart';
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
    required this.caregiverId,
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
  final LogService _logService = LogService();
  DatabaseService databaseService = DatabaseService();
  ScheduleUtility scheduleUtility = ScheduleUtility();
  Map<String, dynamic>? patientData;
  bool isLoading = true;
  bool _isTagging = false;
  late final PageController _pageController;
  late String patientName = '';

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
    _loadPatientName();
    debugPrint("Patient Name: $patientName");
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
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

        final systolicStatus = getVitalStatus(
          'Blood Pressure (Systolic)',
          systolic,
        );
        final diastolicStatus = getVitalStatus(
          'Blood Pressure (Diastolic)',
          diastolic,
        );

        return systolicStatus.color == AppColors.red ||
                diastolicStatus.color == AppColors.red
            ? systolicStatus.color == AppColors.red
                ? systolicStatus
                : diastolicStatus
            : systolicStatus.color == AppColors.yellow ||
                diastolicStatus.color == AppColors.yellow
            ? systolicStatus.color == AppColors.yellow
                ? systolicStatus
                : diastolicStatus
            : VitalStatus(color: AppColors.white, label: "Normal");
      }
    }

    // Convert value to num safely
    final numValue =
        (value is num) ? value : num.tryParse(value.toString()) ?? 0;

    switch (key) {
      case 'Heart Rate':
        if (numValue < minExtremeHeartRate) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very Low",
          );
        }
        if (numValue < minNormalHeartRate) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "Low",
          );
        }
        if (numValue > maxNormalHeartRate) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "High",
          );
        }
        if (numValue > maxExtremeHeartRate) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very High",
          );
        }
        break;

      case 'Blood Pressure (Systolic)':
        if (numValue < minExtremeBloodPressureSystolic) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very Low",
          );
        }
        if (numValue < minNormalBloodPressureSystolic) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "Low",
          );
        }
        if (numValue > maxNormalBloodPressureSystolic) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "High",
          );
        }
        if (numValue > maxExtremeBloodPressureSystolic) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very High",
          );
        }
        break;

      case 'Blood Pressure (Diastolic)':
        if (numValue < minExtremeBloodPressureDiastolic) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very Low",
          );
        }
        if (numValue < minNormalBloodPressureDiastolic) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "Low",
          );
        }
        if (numValue > maxNormalBloodPressureDiastolic) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "High",
          );
        }
        if (numValue > maxExtremeBloodPressureDiastolic) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very High",
          );
        }
        break;

      case 'Oxygen Saturation':
        if (numValue < minExtremeOxygenSaturation) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very Low",
          );
        }
        if (numValue < minNormalOxygenSaturation) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "Low",
          );
        }
        break;

      case 'Respiration':
        if (numValue < minExtremeRespirationRate) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very Low",
          );
        }
        if (numValue < minNormalRespirationRate) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "Low",
          );
        }
        if (numValue > maxNormalRespirationRate) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "High",
          );
        }
        if (numValue > maxExtremeRespirationRate) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very High",
          );
        }
        break;

      case 'Temperature':
        if (numValue < minExtremeTemperature) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very Low",
          );
        }
        if (numValue < minNormalTemperature) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "Low",
          );
        }
        if (numValue > maxNormalTemperature) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "High",
          );
        }
        if (numValue > maxExtremeTemperature) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very High",
          );
        }
        break;

      case 'Pain':
        if (numValue > maxExtremeScale) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very High",
          );
        }
        if (numValue > maxNormalScale) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "High",
          );
        }
        break;
    }

    return VitalStatus(color: AppColors.white, label: "Normal");
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
        }[key] ??
        '';
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

  Widget _buildContainer({
    required String title,
    required String description,
    required String imagePath,
    required String buttonText,
    required IconData buttonIcon,
    required VoidCallback onPressed,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
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
              Text(
                title,
                style: Textstyle.heading.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Textstyle.body.copyWith(color: AppColors.white),
              ),
              SizedBox(
                width: 200,
                child: TextButton(
                  onPressed: onPressed,
                  style: Buttonstyle.buttonDarkGray,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonText,
                        style: Textstyle.smallButton.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(buttonIcon, size: 16, color: AppColors.white),
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

  Widget _buildScheduleContainer() {
    return _buildContainer(
      title: 'Schedule Patient',
      description:
          'Set appointments and visit to the patient at a particular time and day.',
      imagePath: 'lib/assets/images/auth/calendar.jpg',
      buttonText: 'Schedule',
      buttonIcon: Icons.edit_calendar,
      onPressed: () {
        _scheduleAppointment(widget.caregiverId, widget.patientId);
      },
    );
  }

  Widget _buildTaskContainer() {
    return _buildContainer(
      title: 'Set Task',
      description: 'Set tasks for the patient to do.',
      imagePath: 'lib/assets/images/auth/task.jpg',
      buttonText: 'Give Task',
      buttonIcon: Icons.edit_calendar,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewPatientTask(patientId: widget.patientId),
          ),
        );
      },
    );
  }

  Widget _buildMedicineContainer() {
    return _buildContainer(
      title: 'Prescribe Medicine',
      description: 'Give medications to the patient to take.',
      imagePath: 'lib/assets/images/auth/medicine.jpg',
      buttonText: 'Prescribe Medicine',
      buttonIcon: Icons.medical_services_rounded,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ViewPatientMedicine(patientId: widget.patientId),
          ),
        );
      },
    );
  }

  Widget _buildTracking() {
    return _buildContainer(
      title: 'Track Patient',
      description: 'Monitor and track patient symptom flare-ups and vitals.',
      imagePath: 'lib/assets/images/auth/tracking.jpg',
      buttonText: 'Track Patient',
      buttonIcon: Icons.monitor_heart_rounded,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientTracking(patientId: widget.patientId),
          ),
        );
      },
    );
  }

  Widget _buildNotes() {
    return _buildContainer(
      title: 'Take Notes',
      description:
          'Add notes on the current events and changes in the patient\'s condition.',
      imagePath: 'lib/assets/images/auth/notes.jpg',
      buttonText: 'Add Note',
      buttonIcon: Icons.edit_calendar_rounded,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientNote(patientId: widget.patientId),
          ),
        );
      },
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
      await _logService.addLog(
        userId: widget.caregiverId,
        action: "Scheduled patient $patientName on $scheduledDateTime",
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
      stream:
          FirebaseFirestore.instance
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
          future:
              FirebaseFirestore.instance
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

            final predictionsData =
                predictionSnapshot.data?.data() as Map<String, dynamic>?;
            final predictionsArray =
                predictionsData?['predictions'] as List<dynamic>?;

            Map<String, dynamic> criticalPredictions = {};
            Map<String, String> predictionTimes = {};

            if (predictionsArray != null && predictionsArray.isNotEmpty) {
              for (var prediction in predictionsArray) {
                final predMap = prediction as Map<String, dynamic>;
                final predictionTimestamp =
                    (predMap['timestamp'] as Timestamp?)?.toDate();

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
                  final status = getVitalStatus(
                    _convertPredictionKeyToName(key),
                    value,
                  );

                  if (status.color == AppColors.red ||
                      status.color == AppColors.yellow) {
                    // Extract the time step (t+1, t+2, t+3)
                    final match = RegExp(r't\+(\d+)').firstMatch(key);
                    if (match != null) {
                      final timeKey = 't+${match.group(1)}';
                      final futureTime = timeIntervals[timeKey];

                      if (futureTime != null) {
                        final remainingTime = futureTime.difference(
                          _currentTime,
                        );

                        if (!criticalPredictions.containsKey(
                          _convertPredictionKeyToName(key),
                        )) {
                          criticalPredictions[_convertPredictionKeyToName(
                                key,
                              )] =
                              value;
                          predictionTimes[_convertPredictionKeyToName(
                            key,
                          )] = _formatRemainingTime(remainingTime);
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
                  final num? value =
                      rawValue is num
                          ? rawValue
                          : num.tryParse(rawValue.toString());

                  final status =
                      (value != null)
                          ? getVitalStatus(entry.key, value)
                          : VitalStatus(color: AppColors.white, label: "N/A");

                  return _buildVitalRow(
                    entry.key,
                    rawValue.toString(),
                    unit,
                    status,
                  );
                }),

                Divider(),

                // Display earliest predicted critical vitals
                if (criticalPredictions.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Text(
                    'Predicted Critical Vitals',
                    style: Textstyle.subheader.copyWith(color: AppColors.white),
                  ),
                  SizedBox(height: 10),
                  ...criticalPredictions.entries.map((entry) {
                    final unit = _getVitalUnit(entry.key);
                    final status = getVitalStatus(entry.key, entry.value);
                    final timeRemaining =
                        predictionTimes[entry.key] ?? "Unknown";

                    return _buildVitalColumn(
                      entry.key,
                      '(in $timeRemaining)',
                      '${entry.value}',
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
  Widget _buildVitalRow(
    String key,
    String value,
    String unit,
    VitalStatus status,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                key,
                style: Textstyle.bodySmall.copyWith(color: AppColors.white),
              ),
            ),
            Row(
              children: [
                Text(
                  '$value$unit',
                  style: Textstyle.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                if (status.icon != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: status.color,
                    ),
                    child: Row(
                      children: [
                        Icon(status.icon, color: AppColors.white, size: 14),
                        SizedBox(width: 5),
                        Text(
                          status.label,
                          style: Textstyle.bodySuperSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildVitalColumn(
    String key,
    String time,
    String value,
    String unit,
    VitalStatus status,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.darkgray,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    key,
                    style: Textstyle.bodySmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 5),
                  Text(
                    time,
                    style: Textstyle.bodySmall.copyWith(color: AppColors.white),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  if (status.icon != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: status.color,
                      ),
                      child: Row(
                        children: [
                          Icon(status.icon, color: AppColors.white, size: 14),
                          SizedBox(width: 5),
                          Text(
                            status.label,
                            style: Textstyle.bodySuperSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(width: 8),
                  Text(
                    '$value$unit',
                    style: Textstyle.bodySmall.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCarousel() {
    return CarouselWidget(
      pageController: _pageController,
      patientId: widget.patientId,
    );
  }

  Future<bool> _isUserTagged(String patientId, String userId) async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(patientId)
              .get();

      if (docSnapshot.exists) {
        List<dynamic> tags = docSnapshot.data()?['tag'] ?? [];
        return tags.contains(userId);
      }
      return false;
    } catch (e) {
      print('Error checking tag: $e');
      return false;
    }
  }

  Future<void> _tagPatient({
    required String patientId,
    required String userId,
  }) async {
    if (_isTagging) return; // Prevent multiple taps

    final shouldTag = await _showConfirmationDialog(
      title: 'Tag Patient',
      definition:
          'Tagging a patient means adding them to your assigned patient list.',
      message: 'Are you sure you want to tag this patient?',
    );

    if (shouldTag) {
      try {
        if (userId.isEmpty) {
          showToast('User is not authenticated');
          return;
        }

        final String? userRole = await databaseService.fetchAndCacheUserRole(
          userId,
        );

        if (userRole == null) {
          showToast('User has no role');
          return;
        }

        setState(() {
          _isTagging = true;
        });

        showToast('Tagging in progress...');

        final patientRef = FirebaseFirestore.instance
            .collection('patient')
            .doc(patientId);
        final userRef = FirebaseFirestore.instance
            .collection(userRole)
            .doc(userId);

        // Add caregiver/nurse/doctor ID to patient's tags subcollection
        await patientRef.collection('tags').doc(userId).set({});

        // Add patient ID to caregiver/nurse/doctor's tags subcollection
        await userRef.collection('tags').doc(patientId).set({});

        await _logService.addLog(
          userId: widget.caregiverId,
          action: "Tagged patient $patientName",
        );
        await databaseService.addNotification(
          widget.caregiverId,
          'You successfully tagged patient $patientName',
          'tag',
        );

        showToast('Successfully tagged patient.');
      } catch (e) {
        showToast('Error tagging patient: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isTagging = false;
          });
        }
      }
    }
  }

  Future<void> _untagPatient({
    required String patientId,
    required String userId,
  }) async {
    if (_isTagging) return;

    final shouldUntag = await _showConfirmationDialog(
      title: 'Untag Patient',
      definition:
          'Untagging a patient means removing them from your assigned patient list.',
      message: 'Are you sure you want to untag this patient?',
    );

    if (shouldUntag) {
      try {
        if (userId.isEmpty) {
          showToast('User is not authenticated');
          return;
        }

        final String? userRole = await databaseService.fetchAndCacheUserRole(
          userId,
        );

        if (userRole == null) {
          showToast('User has no role');
          return;
        }

        setState(() {
          _isTagging = true;
        });

        showToast('Untagging in progress...');

        final patientRef = FirebaseFirestore.instance
            .collection('patient')
            .doc(patientId);
        final userRef = FirebaseFirestore.instance
            .collection(userRole)
            .doc(userId);

        // Remove caregiver/nurse/doctor ID from patient's tags subcollection
        await patientRef.collection('tags').doc(userId).delete();

        // Remove patient ID from caregiver/nurse/doctor's tags subcollection
        await userRef.collection('tags').doc(patientId).delete();

        await _logService.addLog(
          userId: widget.caregiverId,
          action: "Untagged patient $patientName",
        );
        await databaseService.addNotification(
          widget.caregiverId,
          'You successfully untagged patient $patientName',
          'tag',
        );

        showToast('Successfully untagged patient.');
      } catch (e) {
        showToast('Error untagging patient: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isTagging = false;
          });
        }
      }
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String definition,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text(title, style: Textstyle.subheader),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(definition, style: Textstyle.body),
                  SizedBox(height: 30),
                  Text(
                    message,
                    style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        style: Buttonstyle.buttonRed,
                        child: Text('No', style: Textstyle.smallButton),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        style: Buttonstyle.buttonNeon,
                        child: Text('Yes', style: Textstyle.smallButton),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
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
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  Contacts(patientId: widget.patientId),
                        ),
                      ),
                  child: Icon(
                    Icons.perm_contact_cal_rounded,
                    size: 24,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(width: 5),
                GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  EditPatient(patientId: widget.patientId),
                        ),
                      ),
                  child: Icon(Icons.edit, size: 24, color: AppColors.black),
                ),
                if (widget.role != 'caregiver')
                  FutureBuilder<bool>(
                    future: _isUserTagged(widget.patientId, widget.caregiverId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return CircularProgressIndicator();
                      }

                      final isTagged = snapshot.data!;

                      return Row(
                        children: [
                          SizedBox(width: 5),
                          SizedBox(
                            height: 30,
                            child: TextButton(
                              onPressed:
                                  () =>
                                      isTagged
                                          ? _untagPatient(
                                            patientId: widget.patientId,
                                            userId: widget.caregiverId,
                                          )
                                          : _tagPatient(
                                            patientId: widget.patientId,
                                            userId: widget.caregiverId,
                                          ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: 3,
                                  horizontal: 8,
                                ),
                                backgroundColor:
                                    isTagged ? AppColors.red : AppColors.neon,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                isTagged ? 'Untag Patient' : 'Tag Patient',
                                style: Textstyle.bodySuperSmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: _isTagging ? false : true,
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
