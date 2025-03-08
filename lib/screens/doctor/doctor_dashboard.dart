// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/models/my_patient.dart';
import 'package:solace/screens/doctor/doctor_medicine.dart';
import 'package:solace/screens/doctor/doctor_tasks.dart';
import 'package:solace/screens/doctor/doctor_users.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/contacts.dart';
import 'package:solace/themes/colors.dart';
import 'package:accordion/accordion.dart';
import 'package:solace/models/my_user.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  DoctorDashboardState createState() => DoctorDashboardState();
}

class DoctorDashboardState extends State<DoctorDashboard> {
  final ValueNotifier<int?> _openSectionIndex = ValueNotifier<int?>(null);
  final ScrollController _scrollController = ScrollController();
  final String doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final DatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
  }

  @override
  void dispose() {
    _openSectionIndex.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> gridItems = [
    {'label': 'Caregiver', 'icon': Icons.perm_contact_calendar_rounded},
    {'label': 'Contacts', 'icon': Icons.contact_page_rounded},
    {'label': 'Medicine', 'icon': Icons.medical_services_rounded},
    {'label': 'Prescribe', 'icon': Icons.medication_liquid},
  ];

  final Map<String, Widget Function(String)> routes = {
    'Caregiver': (userId) => DoctorUsers(currentUserId: userId),
    'Contacts': (userId) => Contacts(currentUserId: userId),
    'Medicine': (userId) => DoctorMedicine(currentUserId: userId),
    'Prescribe': (userId) => DoctorTasks(currentUserId: userId),
  };

  Widget _buildIconContainer(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Icon(
        icon,
        size: 28,
        color: AppColors.black,
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context, String userId) {
    return [
      // Grid for icons
      GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // Ensure 4 items in a row
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: gridItems.length,
        itemBuilder: (context, index) {
          final item = gridItems[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => routes[item['label']]!(userId),
                ),
              );
            },
            child: _buildIconContainer(item['icon']),
          );
        },
      ),

      const SizedBox(height: 5),

      // Grid for labels
      GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // Match the number of columns for labels
          crossAxisSpacing: 10,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: gridItems.length,
        itemBuilder: (context, index) {
          final item = gridItems[index];
          return Text(
            item['label'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          );
        },
      ),
    ];
  }

  Stream<List<PatientData>> _fetchPatients() {
    return FirebaseFirestore.instance.collection('patient').snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => PatientData.fromDocument(doc)).toList());
  }

  Future<List<String>> _getSymptoms(String patientId) async {
    final UserRole? role = await _databaseService.getUserRole(patientId);
    if (role != null) {
      return await _databaseService.fetchSymptoms(patientId, role);
    }
    return [];
  }

  void _handleOpenSection(int index) {
    _openSectionIndex.value = index;
  }

  void _handleCloseSection() {
    _openSectionIndex.value = null;
  }

  Future<void> _scheduleAppointment(
      String caregiverId, String patientId) async {
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
              style: TextButton.styleFrom(
                foregroundColor: AppColors.neon,
              ),
            ), dialogTheme: DialogThemeData(backgroundColor: AppColors.white),
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

    try {
      debugPrint("Schedule caregiverId: $caregiverId");
      debugPrint("Schedule scheduledDateTime: $scheduledDateTime");
      debugPrint("Schedule patientId: $patientId");

      // Save schedule in Firestore for both caregiver and patient
      await _databaseService.saveScheduleForDoctor(
          caregiverId, scheduledDateTime, patientId);
      await _databaseService.saveScheduleForPatient(
          patientId, scheduledDateTime, caregiverId);
      print("Schedule saved for both caregiver and patient.");
    } catch (e) {
      print("Failed to save schedule: $e");
    }
  }

  Widget _buildAccordion(List<PatientData> unstablePatients) {
    return Accordion(
      scaleWhenAnimating: false,
      paddingListHorizontal: 0.0,
      paddingListTop: 0.0,
      paddingListBottom: 0.0,
      maxOpenSections: 1,
      headerBackgroundColor: AppColors.gray,
      headerBackgroundColorOpened: AppColors.neon,
      contentBackgroundColor: AppColors.gray,
      contentBorderColor: AppColors.gray,
      contentHorizontalPadding: 20,
      contentVerticalPadding: 10,
      headerPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
      children: unstablePatients.map((patient) {
        return AccordionSection(
          onOpenSection: () =>
              _handleOpenSection(unstablePatients.indexOf(patient)),
          onCloseSection: _handleCloseSection,
          leftIcon: CircleAvatar(
            backgroundImage: (patient.profileImageUrl != null &&
                    patient.profileImageUrl!.isNotEmpty)
                ? NetworkImage(patient.profileImageUrl!)
                : const AssetImage('lib/assets/images/shared/placeholder.png')
                    as ImageProvider,
            radius: 24.0,
          ),
          rightIcon: ValueListenableBuilder<int?>(
            valueListenable: _openSectionIndex,
            builder: (context, value, child) {
              return Icon(
                Icons.keyboard_arrow_down,
                color: value == unstablePatients.indexOf(patient)
                    ? AppColors.white
                    : AppColors.black,
                size: 20,
              );
            },
          ),
          isOpen: _openSectionIndex.value == unstablePatients.indexOf(patient),
          header: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              '${patient.firstName} ${patient.lastName}',
              style: TextStyle(
                color:
                    _openSectionIndex.value == unstablePatients.indexOf(patient)
                        ? AppColors.white
                        : AppColors.black,
                fontSize: 18.0,
                fontWeight: FontWeight.normal,
                fontFamily: 'Inter',
              ),
              maxLines: 1, // Ensures text is limited to one line
              overflow:
                  TextOverflow.ellipsis, // Adds ellipsis when text overflows
            ),
          ),
          content: FutureBuilder<List<String>>(
            future: _getSymptoms(patient.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Text("Error loading symptoms");
              }

              final symptoms = snapshot.data ?? [];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Identified Symptoms',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    if (symptoms.isNotEmpty)
                      Wrap(
                        spacing: 5.0, // Horizontal space between items
                        runSpacing: 0.0, // Vertical space between items
                        children: symptoms.map((symptom) {
                          return Chip(
                            backgroundColor: AppColors.white,
                            label: Text(
                              symptom,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.normal,
                                color: AppColors.black,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    if (symptoms.isEmpty)
                      const Text("No identified symptoms available"),
                    const SizedBox(height: 20.0),
                    _buildActionButton(
                      'Schedule',
                      'lib/assets/images/shared/functions/schedule.png',
                      AppColors.purple,
                      () => _scheduleAppointment(doctorId, patient.uid),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(
      String label, String iconPath, Color bgColor, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, height: 20, width: 20),
            const SizedBox(width: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accordion section
              StreamBuilder<List<PatientData>>(
                stream: _fetchPatients(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Error loading patients: ${snapshot.error}"),
                    );
                  }

                  final patients = snapshot.data ?? [];
                  final unstablePatients = patients
                      .where((patient) => patient.status == 'unstable')
                      .toList();

                  if (unstablePatients.isEmpty) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.blackTransparent,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 30.0, horizontal: 15.0),
                            child: Text(
                              'Unavailable',
                              style: const TextStyle(
                                fontSize: 50.0,
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
                              'There are no unstable patients!',
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
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Priority Patients',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      // The accordion content wrapped in a scrollable view
                      SingleChildScrollView(
                        child: _buildAccordion(unstablePatients),
                      ),
                    ],
                  );
                },
              ),

              // Spacer to push the bottom section down
              const Spacer(),

              // Fixed bottom section (No Flexible or Wrap here)
              const SizedBox(height: 10),
              const Divider(thickness: 1.0),
              const SizedBox(height: 10),
              // Grid builder section
              ..._buildItems(context, doctorId),
            ],
          ),
        ),
      ),
    );
  }
}
