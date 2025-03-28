import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  DatabaseService databaseService = DatabaseService();
  ScheduleUtility scheduleUtility = ScheduleUtility();
  Map<String, dynamic>? patientData;
  bool isLoading = true;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    fetchPatientData();
    _pageController = PageController(initialPage: 0);
    debugPrint("Patient Dashboard Patient ID: ${widget.patientId}");
    debugPrint("Patient Dashboard Caregiver ID: ${widget.caregiverId}");
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
              style: Textstyle.bodySmall.copyWith(color: AppColors.white),
            ),
          );
        }

        // Get the last element in the tracking array
        final lastElement = trackingArray.last as Map<String, dynamic>;
        final vitals = lastElement['Vitals'] as Map<String, dynamic>?;
        final timestamp = lastElement['timestamp'] as Timestamp?;

        if (vitals == null || timestamp == null) {
          return const Center(child: Text('Incomplete vitals data'));
        }

        final formattedTimestamp = DateFormat(
          'MMMM dd, yyyy',
        ).format(timestamp.toDate());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last updated: $formattedTimestamp',
              style: Textstyle.bodySmall.copyWith(
                color: AppColors.white,
                fontStyle: FontStyle.italic,
              ),
            ),

            SizedBox(height: 10),
            ...vitals.entries.map((entry) {
              // Define a map of units
              final units = {
                'Blood Pressure': ' mmHg',
                'Heart Rate': ' bpm',
                'Temperature': '°C',
                'Pain': '/10',
                'Oxygen Saturation': '%',
                'Respiration': ' breaths/min',
              };

              // Get the unit for the current entry, default to an empty string if not found
              final unit = units[entry.key] ?? '';

              return Row(
                children: [
                  // Key
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Textstyle.bodySmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value}$unit', // Append the unit
                    style: Textstyle.bodySmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }),
          ],
        );
      },
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
