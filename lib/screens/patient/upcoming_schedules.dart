import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/database.dart';

class UpcomingSchedules extends StatefulWidget {
  const UpcomingSchedules({super.key});

  @override
  _UpcomingSchedulesState createState() => _UpcomingSchedulesState();
}

class _UpcomingSchedulesState extends State<UpcomingSchedules> {
  List<Map<String, dynamic>> upcomingSchedules = [];
  final DatabaseService db = DatabaseService();

  @override
  void initState() {
    super.initState();
    fetchPatientSchedules();
  }

  Future<void> fetchPatientSchedules() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String patientId = user.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();

      if (snapshot.exists) {
        final List<dynamic> schedulesData = snapshot.data()?['schedule'] ?? [];

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
        title: const Text('Upcoming Schedules'),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            children: [
              for (var i = 0; i < upcomingSchedules.length; i++) ...[
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
                        upcomingSchedules[i]['caregiverName'] ?? 'Caregiver not found',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < upcomingSchedules.length - 1) // Add gap except after the last item
                  const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
