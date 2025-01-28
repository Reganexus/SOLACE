import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/database.dart';

class PatientSchedule extends StatefulWidget {
  const PatientSchedule({super.key, required this.currentUserId});
  final String currentUserId;

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
    // Check if there are schedules, if not skip fetching
    if (upcomingSchedules.isEmpty) {
      fetchPatientSchedules();
    }
  }

  Future<void> fetchPatientSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String patientId = user.uid;
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(patientId)
            .get();

        if (snapshot.exists) {
          final List<dynamic> schedulesData = snapshot.data()?['schedule'] ?? [];

          if (schedulesData.isEmpty) {
            // No schedules available, no need to continue
            setState(() {
              _isLoading = false;
              upcomingSchedules = []; // Clear any previously fetched schedules
            });
            return;
          }

          final List<Map<String, dynamic>> schedules = [];
          for (var schedule in schedulesData) {
            final scheduleDate = (schedule['date'] as Timestamp).toDate();
            final time = schedule['time'];
            final caregiverId = schedule['caregiverId'];

            // Fetch caregiver's name and add to the schedule data
            String caregiverName = await db.getUserName(caregiverId);

            schedules.add({
              'date': scheduleDate,
              'time': time,
              'caregiverName': caregiverName,
            });
          }

          schedules.sort((a, b) => a['date'].compareTo(b['date']));

          setState(() {
            upcomingSchedules = schedules;
            _isLoading = false; // Set loading state to false when done
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No data found for the user.';
          });
        }
      } catch (e) {
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
      'December'
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
      'Saturday'
    ];
    return weekdayNames[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage.isNotEmpty
            ? _buildErrorState()
            : upcomingSchedules.isEmpty
            ? _buildNoScheduleState()
            : SingleChildScrollView(
          child: Column(
            children: [
              for (var i = 0; i < upcomingSchedules.length; i++) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: AppColors.gray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDate(upcomingSchedules[i]['date']),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${upcomingSchedules[i]['time'] ?? 'No time available'} ${getWeekdayName(upcomingSchedules[i]['date'])}',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        upcomingSchedules[i]['caregiverName'] ??
                            'Caregiver not found',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < upcomingSchedules.length - 1)
                  const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Widget for loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 20.0),
          Text(
            "Loading... Please Wait",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Widget for error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.black,
            size: 80,
          ),
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
          Icon(
            Icons.event_busy,
            color: AppColors.black,
            size: 80,
          ),
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

