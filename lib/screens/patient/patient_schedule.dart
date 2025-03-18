import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/database.dart';

class PatientSchedule extends StatefulWidget {
  const PatientSchedule({super.key, required this.patientId});
  final String patientId;

  @override
  PatientScheduleState createState() => PatientScheduleState();
}

class PatientScheduleState extends State<PatientSchedule> {
  List<Map<String, dynamic>> upcomingSchedules = [];
  final DatabaseService db = DatabaseService();
  bool _isLoading = false; // Track loading state
  String _errorMessage = ''; // Store error message

  @override
  void initState() {
    super.initState();
    debugPrint("Patient Dashboard Patient ID: ${widget.patientId}");
    refreshSchedules();
  }

  Future<void> refreshSchedules() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = ''; // Clear previous errors
      });

      await removePastSchedules();
      await fetchPatientSchedules();
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to fetch schedules. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Ensure loading is stopped after refresh
        });
      }
    }
  }

  Future<void> removePastSchedules() async {
    debugPrint("Removing Past Schedules");
    await db.removePastSchedules(widget.patientId);
  }

  Future<void> fetchPatientSchedules() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in.';
        });
      }
      return;
    }

    try {
      // Fetch the caregiver documents under the patient's schedules subcollection
      final caregiverSchedulesSnapshot =
          await FirebaseFirestore.instance
              .collection('patient') // Top-level patient collection
              .doc(widget.patientId) // Target patient document
              .collection('schedules') // Schedules subcollection
              .get();

      if (caregiverSchedulesSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            upcomingSchedules = []; // No schedules found
            _isLoading = false;
          });
        }
        return;
      }

      // Accumulate all schedules from different caregiver documents
      final List<Map<String, dynamic>> schedules = [];
      for (var caregiverDoc in caregiverSchedulesSnapshot.docs) {
        final caregiverData = caregiverDoc.data();
        final caregiverId = caregiverDoc.id;
        final caregiverSchedules = List<Map<String, dynamic>>.from(
          caregiverData['schedules'] ?? [],
        );

        // Fetch caregiver details
        final caregiverRole = await db.getTargetUserRole(caregiverId);
        if (caregiverRole == null) continue;

        final caregiverSnapshot =
            await FirebaseFirestore.instance
                .collection(caregiverRole)
                .doc(caregiverId)
                .get();

        if (caregiverSnapshot.exists) {
          final caregiverName =
              '${caregiverSnapshot['firstName']} ${caregiverSnapshot['lastName']}';

          for (var schedule in caregiverSchedules) {
            final date = (schedule['date'] as Timestamp?)?.toDate();
            if (date == null) continue;

            schedules.add({'date': date, 'caregiverName': caregiverName});
          }
        }
      }

      // Sort schedules by date
      schedules.sort((a, b) => a['date'].compareTo(b['date']));
      if (mounted) {
        setState(() {
          upcomingSchedules = schedules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch schedules: $e';
        });
      }
    }
  }

  // Helper function to format date as "Month Day, Year"
  String formatDate(DateTime date) {
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

  // Helper function to get the weekday name
  String getWeekdayName(DateTime date) {
    final weekdayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return weekdayNames[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Schedule',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child:
            _isLoading
                ? _buildLoadingState()
                : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : upcomingSchedules.isEmpty
                ? _buildNoScheduleState()
                : _buildScheduleList(),
      ),
    );
  }

  Widget _buildScheduleList() {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (var i = 0; i < upcomingSchedules.length; i++) ...[
            _buildScheduleCard(upcomingSchedules[i]),
            if (i < upcomingSchedules.length - 1) const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final DateTime date = schedule['date'];
    final String formattedDate = DateFormat('MMMM d, y').format(date);
    final String formattedTime = DateFormat('h:mm a').format(date);
    final String caregiverName =
        schedule['caregiverName'] ?? 'Caregiver not found';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 25),
              const SizedBox(width: 10.0),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.access_time, size: 25),
              const SizedBox(width: 10.0),
              Text(
                formattedTime,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Divider(thickness: 1.0),
          const SizedBox(height: 5),
          const Text(
            "Healthcare Professional",
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          Text(
            caregiverName,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.normal,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Widget for loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [CircularProgressIndicator()],
      ),
    );
  }

  // Widget for error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.black, size: 80),
          const SizedBox(height: 20.0),
          Text(
            _errorMessage,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: AppColors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20.0),
          TextButton(
            onPressed: fetchPatientSchedules,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              backgroundColor: AppColors.neon,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for showing "No schedule yet" message
  Widget _buildNoScheduleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.event_busy, color: AppColors.black, size: 80),
          SizedBox(height: 20.0),
          Text(
            "No schedule yet",
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
}
