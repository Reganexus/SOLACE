import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/utility/schedule_utility.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';

class CaregiverSchedule extends StatefulWidget {
  const CaregiverSchedule({super.key});

  @override
  CaregiverScheduleState createState() => CaregiverScheduleState();
}

class CaregiverScheduleState extends State<CaregiverSchedule> {
  DatabaseService databaseService = DatabaseService();
  ScheduleUtility scheduleUtility = ScheduleUtility();
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
    await scheduleUtility.removePastSchedules(caregiverId);
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
      String? userRole = await db.fetchAndCacheUserRole(uid);

      if (userRole == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      // Fetch schedules from the caregiver's schedules subcollection
      final scheduleSnapshots =
          await FirebaseFirestore.instance
              .collection(userRole) // Caregiver collection
              .doc(uid) // Caregiver document
              .collection('schedules') // Caregiver's schedules collection
              .get();

      debugPrint(
        'Schedules fetched: ${scheduleSnapshots.docs.map((doc) => doc.data()).toList()}',
      );

      if (scheduleSnapshots.docs.isEmpty) {
        if (mounted) {
          setState(() {
            upcomingSchedules = [];
            isLoading = false;
          });
        }
        return;
      }

      // Process the schedules
      List<Map<String, dynamic>> schedules = [];
      for (var doc in scheduleSnapshots.docs) {
        final scheduleData = doc.data();
        final DateTime date =
            (scheduleData['date'] as Timestamp?)?.toDate() ?? DateTime.now();

        final String? patientId = scheduleData['patientId'] as String?;

        if (patientId != null) {
          // Check if the patient still exists
          final patientSnapshot =
              await FirebaseFirestore.instance
                  .collection('patient')
                  .doc(patientId)
                  .get();

          if (patientSnapshot.exists) {
            final patientDetails = patientSnapshot.data()!;
            final String patientName =
                '${patientDetails['firstName']} ${patientDetails['lastName']}';
            final String address =
                patientDetails['address'] ?? 'Address not available';

            // Add the schedule with patient details
            schedules.add({
              'date': date,
              'patientId': patientId,
              'scheduleId': doc.id,
              'address': address,
              'patientName': patientName,
            });
          } else {
            // If the patient no longer exists, delete the schedule
            await FirebaseFirestore.instance
                .collection(userRole) // Caregiver collection
                .doc(uid) // Caregiver document
                .collection('schedules') // Schedules subcollection
                .doc(doc.id) // Schedule document
                .delete();
          }
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
              title: Text(schedule['patientName'], style: Textstyle.heading),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppColors.black,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMMM d, y').format(schedule['date']),
                          style: Textstyle.body,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: AppColors.black),
                        const SizedBox(width: 8),
                        Text(time, style: Textstyle.body),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.black),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            patientData?['address'] ?? 'Address not available',
                            style: Textstyle.body,
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
                  style: Buttonstyle.buttonNeon,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close', style: Textstyle.smallButton),
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
              : _buildSchedulesList(),
    );
  }

  Widget _buildNoScheduleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: AppColors.black,
            size: 80,
          ),
          const SizedBox(height: 20.0),
          Text("No Schedule Yet", style: Textstyle.body),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(child: Loader.loaderNeon);
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        Container(
          height: 400,
          color: AppColors.black.withValues(alpha: 0.8),
          child: TableCalendar(
            focusedDay: selectedDay,
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            selectedDayPredicate: (day) {
              return upcomingSchedules.any(
                (schedule) =>
                    DateFormat('yyyy-MM-dd').format(schedule['date']) ==
                    DateFormat('yyyy-MM-dd').format(day),
              );
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (mounted) {
                setState(() {
                  this.selectedDay = selectedDay;
                });
              }
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppColors.neon.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: Textstyle.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: Textstyle.body.copyWith(color: AppColors.white),
              disabledTextStyle: Textstyle.body.copyWith(color: AppColors.gray),
              weekendTextStyle: Textstyle.body.copyWith(color: AppColors.white),
              todayTextStyle: Textstyle.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
              outsideTextStyle: Textstyle.body.copyWith(
                color: AppColors.blackTransparent,
              ), // Dimmed color for outside days
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.white,
              ), // Light color for chevrons
              rightChevronIcon: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.white,
              ), // Light color for chevrons
              titleTextStyle: Textstyle.subheader.copyWith(
                color: AppColors.white,
              ), // Light color for title
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: Textstyle.bodySmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ), // Light color for weekdays
              weekendStyle: Textstyle.bodySmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ), // Light color for weekends
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          color: AppColors.black.withValues(alpha: 0.9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLegendItem(AppColors.neon, "Schedules"),
              _buildLegendItem(AppColors.purple, "Today"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 20, height: 20, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: Textstyle.bodySmall.copyWith(color: AppColors.white),
        ),
      ],
    );
  }

  Widget _buildUpcomingSchedules() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              'Upcoming Appointments',
              style: Textstyle.subheader,
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 10.0),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.black),
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            padding: const EdgeInsets.all(5.0),
                            child: Center(
                              child: Text(
                                day,
                                style: Textstyle.bodySuperSmall.copyWith(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Text(month, style: Textstyle.bodySmall),
                        ],
                      ),
                      const SizedBox(width: 10.0),
                      Text(time, style: Textstyle.bodySmall),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesList() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildCalendar(),
          const SizedBox(height: 20.0),
          _buildUpcomingSchedules(),
        ],
      ),
    );
  }
}
