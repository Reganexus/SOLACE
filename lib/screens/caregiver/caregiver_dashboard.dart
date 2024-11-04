// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';
import 'package:accordion/accordion.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solace/models/my_user.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  CaregiverDashboardState createState() => CaregiverDashboardState();
}

class CaregiverDashboardState extends State<CaregiverDashboard> {
  final ValueNotifier<int?> _openSectionIndex = ValueNotifier<int?>(null);
  final ScrollController _scrollController = ScrollController();
  final String caregiverId = FirebaseAuth.instance.currentUser?.uid ?? '';

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

  void _handleOpenSection(int index) {
    _openSectionIndex.value = index;
    _scrollToSection(index);
  }

  void _handleCloseSection() {
    _openSectionIndex.value = null;
  }

  static const headerStyle = TextStyle(
    color: Colors.black,
    fontSize: 16,
    fontFamily: 'Inter',
    fontWeight: FontWeight.bold,
  );

  static const contentStyle = TextStyle(
    color: Colors.black,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: 'Inter',
  );

  void _scrollToSection(int index) {
    double sectionHeight = 100.0;
    double headerHeight = 80.0;

    double targetOffset = headerHeight + (index * sectionHeight);

    _scrollController.animateTo(
      targetOffset - (MediaQuery.of(context).size.height / 3),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    var status = await Permission.phone.status;
    if (status.isDenied) {
      await Permission.phone.request();
      status = await Permission.phone.status;
    }

    if (status.isGranted) {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        print('Could not launch $launchUri');
      }
    } else {
      print('Permission denied to make calls.');
    }
  }

  Future<void> _scheduleAppointment(String caregiverId, String patientId) async {
    final DateTime today = DateTime.now();
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(today.year, today.month + 3),
    );

    if (selectedDate != null) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        // Combine the date and time into a single DateTime object
        final DateTime scheduledDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        try {
          // Save both the date and time to Firestore
          await _databaseService.saveScheduleForCaregiver(caregiverId, scheduledDateTime, patientId);
          await _databaseService.saveScheduleForPatient(patientId, scheduledDateTime, caregiverId);
          print("Schedule saved for both caregiver and patient.");
        } catch (e) {
          print("Failed to save schedule: $e");
        }
      } else {
        print("No time selected.");
      }
    } else {
      print("No date selected.");
    }
  }


  Widget _buildActionButton(String label, String iconPath, Color bgColor, VoidCallback onPressed) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Row(
          children: [
            Image.asset(iconPath, height: 20, width: 20),
            const SizedBox(width: 5),
            Text(
              label,
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
      body: Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StreamBuilder<List<UserData?>>(
                stream: _databaseService.patients,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error loading patients: ${snapshot.error}"));
                  }

                  final patients = snapshot.data ?? [];

                  return SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
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
                        Accordion(
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
                          headerPadding: const EdgeInsets.symmetric(
                              vertical: 7, horizontal: 15),
                          children: patients.map((patient) {
                            return AccordionSection(
                              onOpenSection: () => _handleOpenSection(patients.indexOf(patient)),
                              onCloseSection: _handleCloseSection,
                              headerBackgroundColor: AppColors.gray,
                              headerBackgroundColorOpened: AppColors.neon,
                              contentBackgroundColor: AppColors.gray,
                              contentBorderColor: AppColors.gray,
                              contentHorizontalPadding: 20,
                              contentVerticalPadding: 10,
                              headerPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                              leftIcon: CircleAvatar(
                                backgroundImage: AssetImage(
                                    'lib/assets/images/shared/placeholder.png'), // Default placeholder
                                radius: 18.0,
                              ),
                              rightIcon: ValueListenableBuilder<int?>(
                                // Updated
                                valueListenable: _openSectionIndex,
                                builder: (context, value, child) {
                                  return Icon(
                                    Icons.keyboard_arrow_down,
                                    color: value == patients.indexOf(patient)
                                        ? AppColors.white
                                        : AppColors.black,
                                    size: 20,
                                  );
                                },
                              ),
                              isOpen: _openSectionIndex.value == patients.indexOf(patient),
                              header: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: ValueListenableBuilder<int?>(
                                  valueListenable: _openSectionIndex,
                                  builder: (context, value, child) {
                                    return Text(
                                      '${patient?.firstName ?? 'Unknown'} ${patient?.lastName ?? 'Unknown'}',
                                      style: headerStyle.copyWith(
                                        color: value == patients.indexOf(patient)
                                            ? AppColors.white
                                            : AppColors.black,
                                        fontSize: 18.0,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.normal,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Identified Conditions',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  // Provide a default message if conditions are not available
                                  Text("No identified conditions available", style: contentStyle),
                                  const SizedBox(height: 20.0),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      // When calling _scheduleAppointment, use patient.uid
                                      _buildActionButton(
                                        'Schedule',
                                        'lib/assets/images/shared/functions/schedule.png',
                                        AppColors.darkblue,
                                            () => _scheduleAppointment(caregiverId, patient?.uid ?? ''), // No null assertion
                                      ),
                                      const SizedBox(width: 10),
                                      _buildActionButton(
                                        'Call',
                                        'lib/assets/images/shared/functions/call.png',
                                        AppColors.red,
                                            () => _makeCall(patient?.phoneNumber ?? ''), // No null assertion
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
