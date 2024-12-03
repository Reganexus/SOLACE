// ignore_for_file: avoid_print, use_build_context_synchronously, unnecessary_null_comparison

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/interventions.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/screens/patient/upcoming_schedules.dart'; // Import UpcomingSchedules

class PatientDashboard extends StatefulWidget {
  final VoidCallback navigateToHistory;

  const PatientDashboard({super.key, required this.navigateToHistory});

  @override
  PatientDashboardState createState() => PatientDashboardState();
}

class PatientDashboardState extends State<PatientDashboard> {
  List<Map<String, dynamic>> upcomingSchedules = [];
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true; // Add a loading flag
  final String patientId =
      FirebaseAuth.instance.currentUser!.uid; // Fetch patientId

  // Create a date format
  final DateFormat dateFormat = DateFormat("MMMM dd, yyyy 'at' h:mm a");

  @override
  void initState() {
    super.initState();
    fetchPatientSchedules();
    fetchPatientTasks();
  }

  void _showTaskModal(
    BuildContext context,
    String patientId, // Patient ID
    String taskId, // Task ID
    String title, // Task Title
    String description, // Task Description
    DateTime startDate, // Task Start Date
    DateTime endDate, // Task End Date
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: SingleChildScrollView(
            // Make content scrollable for long texts
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align to the left
              mainAxisSize: MainAxisSize.min,
              children: [
                // Description
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Description",
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.normal,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),

                // Start Date
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Start Date",
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    dateFormat.format(startDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.normal,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),

                // End Date
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "End Date",
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    dateFormat.format(endDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.normal,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),

                // Buttons Section
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center the buttons
                  children: [
                    // Mark as Done Button
                    TextButton(
                      onPressed: () async {
                        try {
                          // Fetch the patient's document from Firestore
                          final patientDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(patientId)
                              .get();

                          if (patientDoc.exists) {
                            final tasksList = List<Map<String, dynamic>>.from(
                                patientDoc.data()?['tasks'] ?? []);

                            final taskToUpdate = tasksList.firstWhere(
                              (task) => task['id'] == taskId,
                              orElse: () => {},
                            );

                            if (taskToUpdate != null) {
                              // Remove the old task and update it with isCompleted = true
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(patientId)
                                  .update({
                                'tasks': FieldValue.arrayRemove([taskToUpdate])
                              });

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(patientId)
                                  .update({
                                'tasks': FieldValue.arrayUnion([
                                  {
                                    ...taskToUpdate,
                                    'isCompleted':
                                        true, // Update the task as completed
                                  }
                                ])
                              });

                              // Show Snackbar to indicate the task is completed
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Task marked as completed!',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              Navigator.of(context).pop(); // Close the modal
                            } else {
                              debugPrint("Task with ID $taskId not found");
                            }
                          } else {
                            debugPrint("Patient document not found");
                          }
                        } catch (e) {
                          debugPrint("Error marking task as done: $e");
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        backgroundColor: AppColors.neon,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Mark as Done',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),

                    // Close Button
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the modal
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        backgroundColor: AppColors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Get icon for the task category
  String getIconForCategory(String category) {
    switch (category) {
      case 'Medication':
        return 'lib/assets/images/shared/vitals/medicine.png';
      case 'Heart Rate':
        return 'lib/assets/images/shared/vitals/heart_rate.png';
      case 'Blood Pressure':
        return 'lib/assets/images/shared/vitals/blood_pressure.png';
      case 'Blood Oxygen':
        return 'lib/assets/images/shared/vitals/blood_oxygen.png';
      case 'Temperature':
        return 'lib/assets/images/shared/vitals/temperature.png';
      case 'Weight':
        return 'lib/assets/images/shared/vitals/weight.png';
      case 'Pain Assessment':
        return 'lib/assets/images/shared/vitals/pain_assessment.png';
      default:
        return 'lib/assets/images/shared/vitals/task.png';
    }
  }

  // Fetch patient tasks and filter them based on today's date
  Future<void> fetchPatientTasks() async {
    setState(() {
      isLoading = true;
    });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String patientId = user.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();

      if (snapshot.exists) {
        final List<dynamic> tasksData = snapshot.data()?['tasks'] ?? [];
        final List<Map<String, dynamic>> filteredTasks = [];
        final DateTime today = DateTime.now();

        for (var task in tasksData) {
          // Extract the task ID from Firestore, or fall back to a placeholder
          final taskId = task['id'] ?? '';
          if (taskId == '') {
            debugPrint("Task is missing an 'id' field: $task");
          }

          // Ensure that startDate and endDate exist
          if (task['startDate'] != null && task['endDate'] != null) {
            // Parse Firestore Timestamps or keep as DateTime
            final startDate = task['startDate'] is Timestamp
                ? (task['startDate'] as Timestamp).toDate()
                : task['startDate'];
            final endDate = task['endDate'] is Timestamp
                ? (task['endDate'] as Timestamp).toDate()
                : task['endDate'];

            // Ensure the task has necessary fields
            final String title = task['title'] ?? 'No title';
            final String category = task['category'] ?? 'Unknown';
            final String description =
                task['description'] ?? 'No description available';
            final String icon = task['icon'] ??
                'lib/assets/images/shared/vitals/heart_rate.png';

            // Check if today's date is within the task's date range
            if ((today.isAfter(startDate) ||
                    today.isAtSameMomentAs(startDate)) &&
                (today.isBefore(endDate.add(Duration(days: 1))) ||
                    today.isAtSameMomentAs(endDate))) {
              filteredTasks.add({
                'id': taskId, // Use the actual task ID
                'title': title,
                'category': category,
                'description': description,
                'startDate': startDate,
                'endDate': endDate,
                'icon': icon,
                'isCompleted':
                    task['isCompleted'] ?? false, // Include isCompleted flag
              });
            }
          }
        }

        setState(() {
          tasks = filteredTasks;
          isLoading = false;
        });

        // Debug output to verify tasks
        debugPrint(
            "Filtered tasks: ${filteredTasks.map((t) => t['id']).toList()}");
      } else {
        debugPrint("No document found for patientId: $patientId");
        setState(() {
          isLoading = false;
        });
      }
    }
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

          schedules.add({
            'date': scheduleDate,
            'time': time,
          });
        }

        // Sort schedules by the earliest date first
        schedules.sort((a, b) => a['date'].compareTo(b['date']));

        setState(() {
          upcomingSchedules = schedules;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: StreamBuilder<UserData?>(
            stream: DatabaseService(uid: user?.uid).userData,
            builder: (context, snapshot) {
              // Default values for status card
              String status = 'stable';
              String statusMessage =
                  'ⓘ No symptoms detected. Keep up the good work!';
              Color backgroundColor = AppColors.neon;

              if (snapshot.hasData) {
                final userData = snapshot.data!;
                status = userData.status;

                if (status == 'unstable') {
                  statusMessage =
                      '⚠️ Symptoms detected. Please consult your doctor.';
                  backgroundColor = AppColors.red;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Section
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // Status Card
                  GestureDetector(
                    onTap:() {
                      if(status == 'unstable') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => InterventionsView(uid: user!.uid,)),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 30.0, horizontal: 15.0),
                            color: Colors.transparent,
                            child: Text(
                              status == 'stable' ? 'Stable' : 'Unstable',
                              style: const TextStyle(
                                fontSize: 50.0,
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.left,
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
                              statusMessage,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // Clickable Link to History
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        widget.navigateToHistory();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: const Text(
                          'See more about your status',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                            fontSize: 16.0,
                            color: AppColors.black,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30.0),

                  // Schedule Section
                  const Text(
                    'Schedule',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // Schedule Display
                  upcomingSchedules.isNotEmpty
                      ? Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15.0, horizontal: 15.0),
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
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.black),
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                        ),
                                        padding: const EdgeInsets.all(5.0),
                                        child: Center(
                                          child: Text(
                                            upcomingSchedules[0]['date'] != null
                                                ? '${upcomingSchedules[0]['date']!.day}'
                                                : '',
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10.0),
                                      Text(
                                        upcomingSchedules[0]['date'] != null
                                            ? DateFormat('MMMM').format(
                                                upcomingSchedules[0]['date'])
                                            : 'No date available',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    upcomingSchedules[0]['time'] ??
                                        'No time available',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const UpcomingSchedules(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  child: const Text(
                                    'See all upcoming schedules',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.normal,
                                      fontSize: 16.0,
                                      color: AppColors.black,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 15.0),
                          decoration: BoxDecoration(
                            color: AppColors.gray,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            "No upcoming appointments",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18.0,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                  const SizedBox(height: 30.0),

                  // Tasks Section
                  const Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  ListView.builder(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    itemCount: tasks.isEmpty ? 1 : tasks.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      if (tasks.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 15.0),
                          decoration: BoxDecoration(
                            color: AppColors.gray,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            "No tasks for today",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18.0,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        );
                      }

                      final task = tasks[index];
                      final patientId = FirebaseAuth.instance.currentUser!.uid;
                      String taskIcon = getIconForCategory(task['category']);

                      return GestureDetector(
                        onTap: () {
                          _showTaskModal(
                            context,
                            patientId,
                            task['id'],
                            task['title'],
                            task['description'],
                            task['startDate'],
                            task['endDate'],
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20.0,
                              horizontal: 15.0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: AppColors.purple,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      taskIcon,
                                      height: 30,
                                    ),
                                    const SizedBox(width: 10.0),
                                    Expanded(
                                      child: Text(
                                        task['title'],
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontFamily: 'Outfit',
                                          fontSize: 24.0,
                                          fontWeight: FontWeight.bold,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    if (task['isCompleted'] == true)
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.neon,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10.0),
                                Text(
                                  task['description'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontFamily: 'Inter',
                                    fontSize: 16.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
