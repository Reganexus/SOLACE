import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:solace/utility/schedule_utility.dart';

class PatientSchedule extends StatefulWidget {
  const PatientSchedule({super.key, required this.patientId});
  final String patientId;

  @override
  PatientScheduleState createState() => PatientScheduleState();
}

class PatientScheduleState extends State<PatientSchedule> {
  List<Map<String, dynamic>> upcomingSchedules = [];
  DatabaseService databaseService = DatabaseService();
  ScheduleUtility scheduleUtility = ScheduleUtility();
  bool _isLoading = false; // Track loading state
  String _errorMessage = ''; // Store error message

  @override
  void initState() {
    super.initState();
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
    //     debugPrint("Removing Past Schedules");
    await scheduleUtility.removePastSchedules(widget.patientId);
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
      _setErrorState('User not logged in.');
      return;
    }

    try {
      // Fetch the caregiver documents under the patient's schedules subcollection
      final caregiverSchedulesSnapshot = await _fetchCaregiverSchedules();

      if (caregiverSchedulesSnapshot.docs.isEmpty) {
        _setSchedulesState([]);
        return;
      }

      final schedules = await _processCaregiverSchedules(
        caregiverSchedulesSnapshot,
      );
      _setSchedulesState(schedules);
    } catch (e) {
      _setErrorState('Failed to fetch schedules: $e');
    }
  }

  Future<QuerySnapshot> _fetchCaregiverSchedules() async {
    return FirebaseFirestore.instance
        .collection('patient')
        .doc(widget.patientId)
        .collection('schedules')
        .get();
  }

  Future<List<Map<String, dynamic>>> _processCaregiverSchedules(
    QuerySnapshot caregiverSchedulesSnapshot,
  ) async {
    final List<Map<String, dynamic>> schedules = [];

    for (var caregiverDoc in caregiverSchedulesSnapshot.docs) {
      final caregiverData =
          caregiverDoc.data()
              as Map<String, dynamic>?; // Safe cast to Map<String, dynamic>
      if (caregiverData == null) continue;

      final caregiverId = caregiverData['caregiverId'];

      final date =
          (caregiverData['date'] as Timestamp?)?.toDate(); // Safe null check

      if (date == null) continue;

      // Fetch caregiver name using caregiverId
      final caregiverName = await _getCaregiverName(caregiverId);

      // Add schedule data to list
      schedules.add({'date': date, 'caregiverName': caregiverName});
    }

    // Sort schedules by date
    schedules.sort((a, b) => a['date'].compareTo(b['date']));
    return schedules;
  }

  Future<String> _getCaregiverName(String caregiverId) async {
    final caregiverRole = await databaseService.fetchAndCacheUserRole(
      caregiverId,
    );
    if (caregiverRole == null) return 'Unknown';

    final caregiverSnapshot =
        await FirebaseFirestore.instance
            .collection(caregiverRole)
            .doc(caregiverId)
            .get();

    if (caregiverSnapshot.exists) {
      final firstName = caregiverSnapshot['firstName'] as String?;
      final lastName = caregiverSnapshot['lastName'] as String?;
      //       debugPrint("Schedule firstName: $firstName");
      //       debugPrint("Schedule lastName: $lastName");

      if (firstName != null && lastName != null) {
        return '$firstName $lastName';
      }
    }
    return 'Unknown';
  }

  void _setSchedulesState(List<Map<String, dynamic>> schedules) {
    if (mounted) {
      setState(() {
        upcomingSchedules = schedules;
        _isLoading = false;
      });
    }
  }

  void _setErrorState(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
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
    return SingleChildScrollView(
      child: Container(
        color: AppColors.white,
        width: double.infinity,
        padding: EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _isLoading
                ? _buildLoadingState()
                : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : upcomingSchedules.isEmpty
                ? _buildNoScheduleState()
                : _buildScheduleList();
          },
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (var i = 0; i < upcomingSchedules.length; i++) ...[
            _buildScheduleCard(upcomingSchedules[i]),
            if (i < upcomingSchedules.length - 1) const SizedBox(height: 10),
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
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 10.0),
                    Text(formattedDate, style: Textstyle.body),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 10.0),
                    Text(formattedTime, style: Textstyle.body),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: AppColors.blackTransparent),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Healthcare Professional",
                  style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(caregiverName, style: Textstyle.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Loader.loaderPurple],
      ),
    );
  }

  // Widget for error state
  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          color: AppColors.whiteTransparent,
          size: 70,
        ),
        const SizedBox(height: 20.0),
        Text(
          _errorMessage,
          style: Textstyle.bodyWhite.copyWith(
            color: AppColors.whiteTransparent,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20.0),
        SizedBox(
          width: 100,
          child: TextButton(
            onPressed: fetchPatientSchedules,
            style: Buttonstyle.buttonPurple,
            child: Text('Retry', style: Textstyle.smallButton),
          ),
        ),
      ],
    );
  }

  // Widget for showing "No schedule yet" message
  Widget _buildNoScheduleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, color: AppColors.black, size: 70),
          const SizedBox(height: 10.0),
          Text(
            "No schedule yet",
            style: Textstyle.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
