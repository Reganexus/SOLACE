import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';
import 'package:table_calendar/table_calendar.dart';

class CaregiverSchedule extends StatefulWidget {
  const CaregiverSchedule({super.key});

  @override
  CaregiverScheduleState createState() => CaregiverScheduleState();
}

class CaregiverScheduleState extends State<CaregiverSchedule> {
  final DatabaseService db = DatabaseService();
  late final String caregiverId;
  List<Map<String, dynamic>> upcomingSchedules = [];
  DateTime selectedDay = DateTime.now();
  bool isLoading = true; // Add a loading state

  @override
  void initState() {
    super.initState();
    caregiverId = FirebaseAuth.instance.currentUser?.uid ?? '';
    refreshSchedules();
  }

  Future<void> refreshSchedules() async {
    try {
      setState(() {
        isLoading = true; // Ensure loading is shown at the start
      });

      await removePastSchedules();
      await fetchUpcomingSchedules();
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; // Ensure loading is hidden at the end
        });
      }
    }
  }

  Future<void> removePastSchedules() async {
    debugPrint("Removing Past Schedules");
    await db.removePastSchedules(caregiverId);
  }

  Future<void> fetchUpcomingSchedules() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      DatabaseService db = DatabaseService();
      final String uid = user.uid;
      String? userRole = await db.getTargetUserRole(uid);

      if (userRole == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      // Fetch all patient documents in the caregiver's 'schedules' subcollection
      final scheduleSnapshots =
          await FirebaseFirestore.instance
              .collection(userRole) // Caregiver collection
              .doc(uid) // Caregiver document
              .collection('schedules') // Caregiver's schedules collection
              .get();

      if (scheduleSnapshots.docs.isEmpty) {
        if (mounted) {
          setState(() {
            upcomingSchedules = [];
            isLoading = false;
          });
        }
        return;
      }

      // Extract schedules from each patient document
      List<Map<String, dynamic>> schedules = [];
      for (var doc in scheduleSnapshots.docs) {
        final patientId = doc.id;
        final patientData = doc.data();
        final patientSchedules = List<Map<String, dynamic>>.from(
          patientData['schedules'] ?? [],
        );

        // Fetch patient details
        final patientSnapshot =
            await FirebaseFirestore.instance
                .collection('patient')
                .doc(patientId)
                .get();

        if (patientSnapshot.exists) {
          final patientDetails = patientSnapshot.data()!;
          final patientName =
              '${patientDetails['firstName']} ${patientDetails['lastName']}';
          final patientAddress =
              patientDetails['address'] ?? 'Address not available';

          // Map schedules with patient details
          schedules.addAll(
            patientSchedules.map((schedule) {
              return {
                'date':
                    (schedule['date'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                'patientId': patientId,
                'address': patientAddress,
                'patientName': patientName,
              };
            }).toList(),
          );
        }
      }

      // Sort schedules by date
      schedules.sort((a, b) => a['date'].compareTo(b['date']));
      if (mounted) {
        setState(() {
          upcomingSchedules = schedules;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showAppointmentDetails(
    BuildContext context,
    Map<String, dynamic> schedule,
  ) async {
    try {
      final String patientId = schedule['patientId'];
      final patientSnapshot =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(patientId)
              .get();

      if (patientSnapshot.exists) {
        final patientData = patientSnapshot.data();
        final time = DateFormat('h:mm a').format(schedule['date']);

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: AppColors.white,
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
                        Text(time, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            patientData?['address'] ?? 'Address not available',
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
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
      } else {
        debugPrint('Patient data not found');
      }
    } catch (e) {
      debugPrint('Error fetching patient data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body:
          isLoading
              ? _buildLoadingState() // Show loading indicator
              : upcomingSchedules.isEmpty
              ? _buildNoScheduleState() // Show "No schedules" if list is empty
              : _buildSchedulesList()
    );
  }

  Widget _buildNoScheduleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.event_busy_rounded, color: AppColors.black, size: 80),
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

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(color: AppColors.neon),
    );
  }

  Widget _buildSchedulesList() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child: Column(
          children: [
            TableCalendar(
              focusedDay: selectedDay,
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              selectedDayPredicate: (day) {
                return upcomingSchedules.any(
                      (schedule) =>
                  DateFormat(
                    'yyyy-MM-dd',
                  ).format(schedule['date']) ==
                      DateFormat('yyyy-MM-dd').format(day),
                );
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (mounted) {
                  if (mounted) {
                    setState(() {
                      this.selectedDay = selectedDay;
                    });
                  }
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
                final String day = DateFormat('d').format(date);
                final String month = DateFormat('MMMM').format(date);
                final String time = DateFormat('h:mm a').format(date);

                return GestureDetector(
                  onTap: () {
                    _showAppointmentDetails(context, schedule);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 15.0,
                    ),
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
                                  color: Colors.black,
                                ),
                                borderRadius: BorderRadius.circular(
                                  5.0,
                                ),
                              ),
                              padding: const EdgeInsets.all(5.0),
                              child: Center(
                                child: Text(
                                  day,
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
                              month,
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          time,
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
            ),
          ],
        ),
      ),
    );
  }
}
