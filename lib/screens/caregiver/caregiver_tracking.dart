// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solace/themes/colors.dart';
import 'package:table_calendar/table_calendar.dart';

class CaregiverTracking extends StatefulWidget {
  const CaregiverTracking({super.key});

  @override
  CaregiverTrackingState createState() => CaregiverTrackingState();
}

class CaregiverTrackingState extends State<CaregiverTracking> {
  List<Map<String, dynamic>> upcomingSchedules = [];
  DateTime selectedDay = DateTime.now();
  bool isLoading = true; // Add a loading state

  @override
  void initState() {
    super.initState();
    fetchUpcomingSchedules();
  }

  Future<void> fetchUpcomingSchedules() async {
    setState(() {
      isLoading = true; // Set loading state to true
    });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String caregiverId = user.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(caregiverId)
          .get();

      if (snapshot.exists) {
        final List<dynamic> schedulesData = snapshot.data()?['schedule'] ?? [];

        final List<Map<String, dynamic>> schedules = [];
        for (var schedule in schedulesData) {
          final scheduleDate = (schedule['date'] as Timestamp).toDate();
          final time = schedule['time']; // Ensure your Firestore has this
          final patientId = schedule['patientId'];

          // Fetch patient details to get address and phone number
          final patientSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(patientId)
              .get();

          if (patientSnapshot.exists) {
            final patientData = patientSnapshot.data()!;
            schedules.add({
              'date': scheduleDate,
              'time': time, // Assuming time is stored in your Firestore
              'patientId': patientId,
              'address': patientData['address'],
              'phoneNumber': patientData['phoneNumber'],
              'patientName':
                  '${patientData['firstName']} ${patientData['lastName']}',
            });
          }
        }

        schedules.sort((a, b) => a['date'].compareTo(b['date']));

        setState(() {
          upcomingSchedules = schedules;
          isLoading = false; // Set loading state to false once data is loaded
        });
      }
    }
  }

  void _showAppointmentDetails(BuildContext context, Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white, // Set background color
          title: Text(
            schedule['patientName'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM d, y').format(schedule['date']),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      schedule['time'] ?? 'Time not available',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        schedule['address'] ?? 'Address not available',
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      schedule['phoneNumber'] ?? 'Phone not available',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                backgroundColor: AppColors.neon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: isLoading // Show loading indicator when data is being fetched
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // Wrap the entire content in SingleChildScrollView
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TableCalendar(
                      focusedDay: selectedDay,
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 90)),
                      selectedDayPredicate: (day) {
                        return upcomingSchedules.any((schedule) =>
                            DateFormat('yyyy-MM-dd').format(schedule['date']) ==
                            DateFormat('yyyy-MM-dd').format(day));
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          this.selectedDay = selectedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.neon,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.purple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        leftChevronIcon: Icon(Icons.arrow_back),
                        rightChevronIcon: Icon(Icons.arrow_forward),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    SizedBox(
                      width: double.infinity,
                      child: const Text(
                        'Upcoming Appointments',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    // Remove Expanded and let the ListView take up space naturally
                    upcomingSchedules.isNotEmpty
                        ? ListView.builder(
                            physics:
                                const NeverScrollableScrollPhysics(), // Prevent scrolling within the list
                            shrinkWrap:
                                true, // Allows ListView to take only the required height
                            itemCount: upcomingSchedules.length,
                            itemBuilder: (context, index) {
                              final schedule = upcomingSchedules[index];
                              final date = schedule['date'] as DateTime;

                              return GestureDetector(
                                onTap: () {
                                  _showAppointmentDetails(context, schedule);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 15.0),
                                  margin: const EdgeInsets.only(bottom: 10.0),
                                  decoration: BoxDecoration(
                                    color: AppColors.gray,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.black),
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                            ),
                                            padding: const EdgeInsets.all(5.0),
                                            child: Center(
                                              child: Text(
                                                DateFormat('d').format(date),
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10.0),
                                          Text(
                                            DateFormat('MMMM').format(date),
                                            style: const TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 10.0),
                                      Text(
                                        schedule['time'] ??
                                            'Time not available',
                                        style: const TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(child: Text('No upcoming appointments')),
                  ],
                ),
              ),
            ),
    );
  }
}
