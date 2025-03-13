import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solace/themes/colors.dart';
import 'package:table_calendar/table_calendar.dart';

class CaregiverSchedule extends StatefulWidget {
  const CaregiverSchedule({super.key});

  @override
  CaregiverScheduleState createState() => CaregiverScheduleState();
}

class CaregiverScheduleState extends State<CaregiverSchedule> {
  List<Map<String, dynamic>> upcomingSchedules = [];
  DateTime selectedDay = DateTime.now();
  bool isLoading = true; // Add a loading state

  @override
  void initState() {
    super.initState();
    fetchUpcomingSchedules();
  }

  Future<void> fetchUpcomingSchedules() async {
    try {
      setState(() {
        isLoading = true;
      });

      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final String uid = user.uid;
        final doctorSnapshot = await FirebaseFirestore.instance
            .collection('doctor')
            .doc(uid)
            .get();

        if (doctorSnapshot.exists) {
          final schedulesData =
              doctorSnapshot.data()?['schedule'] as List<dynamic>? ?? [];
          if (schedulesData.isEmpty) {
            setState(() {
              upcomingSchedules = [];
              isLoading = false;
            });
            return;
          }

          // Batch fetch patient details
          final patientIds = schedulesData.map((s) => s['patientId']).toSet();
          final patientSnapshots = await FirebaseFirestore.instance
              .collection('caregiver')
              .where(FieldPath.documentId, whereIn: patientIds.toList())
              .get();

          final patientMap = {
            for (var doc in patientSnapshots.docs) doc.id: doc.data()
          };

          final schedules = schedulesData.map((schedule) {
            final patientData = patientMap[schedule['patientId']];
            final scheduleDate = (schedule['date'] as Timestamp).toDate();

            return {
              'date': scheduleDate,
              'time': schedule['time'] ?? 'Time not available',
              'patientId': schedule['patientId'],
              'address': patientData?['address'] ?? 'Address not available',
              'phoneNumber':
                  patientData?['phoneNumber'] ?? 'Phone not available',
              'patientName': patientData != null
                  ? '${patientData['firstName']} ${patientData['lastName']}'
                  : 'Unknown Patient',
            };
          }).toList();

          schedules.sort((a, b) => a['date'].compareTo(b['date']));

          setState(() {
            upcomingSchedules = schedules;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showAppointmentDetails(
      BuildContext context, Map<String, dynamic> schedule) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.neon,
              ),
            )
          : upcomingSchedules.isEmpty
              ? _buildNoScheduleState() // Display "No schedule yet" widget during loading
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
                    child: Column(
                      children: [
                        TableCalendar(
                          focusedDay: selectedDay,
                          firstDay: DateTime.now(),
                          lastDay: DateTime.now().add(const Duration(days: 90)),
                          selectedDayPredicate: (day) {
                            return upcomingSchedules.any((schedule) =>
                                DateFormat('yyyy-MM-dd')
                                    .format(schedule['date']) ==
                                DateFormat('yyyy-MM-dd').format(day));
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            if (mounted) {
                              setState(() {
                                this.selectedDay = selectedDay;
                              });
                            }
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
                            leftChevronIcon: Icon(Icons.chevron_left_rounded),
                            rightChevronIcon: Icon(Icons.chevron_right_rounded),
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
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
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
                                            border:
                                                Border.all(color: Colors.black),
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
                                      schedule['time'] ?? 'Time not available',
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
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNoScheduleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.event_busy_rounded,
            color: AppColors.black,
            size: 80,
          ),
          SizedBox(height: 20.0),
          Text(
            "No Schedule Yet",
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
