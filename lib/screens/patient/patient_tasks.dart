// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:solace/utility/task_utility.dart';

class PatientTasks extends StatefulWidget {
  const PatientTasks({super.key, required this.patientId});
  final String patientId;

  @override
  PatientTasksState createState() => PatientTasksState();
}

class PatientTasksState extends State<PatientTasks> {
  DatabaseService databaseService = DatabaseService();
  TaskUtility taskUtility = TaskUtility();
  List<Map<String, dynamic>> completedTasks = [];
  List<Map<String, dynamic>> notCompletedTasks = [];
  bool isLoading = false;
  bool showCompleted = false;

  @override
  void initState() {
    super.initState();
    fetchPatientTasks();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchPatientTasks() async {
    print("Fetching tasks for patient: ${widget.patientId}");

    if (!mounted) {
      return; // Prevent unnecessary operations if widget is not mounted
    }

    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      // Fetch all task documents under the patient's tasks subcollection
      final patientTasksSnapshot =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(widget.patientId)
              .collection('tasks')
              .get();

      print("Fetched ${patientTasksSnapshot.docs.length} task documents.");

      if (patientTasksSnapshot.docs.isEmpty) {
        print("No tasks found under patient ${widget.patientId}.");
        _updateTasks([], []);
        return;
      }

      final loadedCompletedTasks = <Map<String, dynamic>>[];
      final loadedNotCompletedTasks = <Map<String, dynamic>>[];

      for (final taskDoc in patientTasksSnapshot.docs) {
        final taskData = taskDoc.data();
        final startDate = (taskData['startDate'] as Timestamp?)?.toDate();
        final endDate = (taskData['endDate'] as Timestamp?)?.toDate();

        debugPrint("taskData: $taskData");
        debugPrint("startDate: $startDate");
        debugPrint("endDate: $endDate");

        if (startDate == null || endDate == null) {
          print("Skipping invalid task: ${taskDoc.id}");
          continue;
        }

        final task = {
          'title': taskData['title'] ?? 'No Title',
          'description': taskData['description'] ?? '',
          'startDate': startDate,
          'endDate': endDate,
          'isCompleted': taskData['isCompleted'] ?? false,
          'taskId': taskDoc.id,
        };

        if (task['isCompleted'] == true) {
          loadedCompletedTasks.add(task);
        } else {
          loadedNotCompletedTasks.add(task);
        }
      }

      // Sort tasks by start date
      loadedCompletedTasks.sort(
        (a, b) => a['startDate'].compareTo(b['startDate']),
      );
      loadedNotCompletedTasks.sort(
        (a, b) => a['startDate'].compareTo(b['startDate']),
      );

      _updateTasks(loadedCompletedTasks, loadedNotCompletedTasks);
    } catch (e) {
      print("Error loading tasks: $e");
      _updateTasks([], []);
    }
  }

  void _updateTasks(
    List<Map<String, dynamic>> completed,
    List<Map<String, dynamic>> notCompleted,
  ) {
    if (mounted) {
      setState(() {
        completedTasks = completed;
        notCompletedTasks = notCompleted;
        isLoading = false;
      });
    }
  }

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  Widget _buildNoTaskState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_busy,
            color: AppColors.whiteTransparent,
            size: 70,
          ),
          const SizedBox(height: 10.0),
          Text(
            "Great Work! No Tasks",
            style: Textstyle.bodyWhite.copyWith(
              color: AppColors.whiteTransparent,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> updateTaskCompletion(
    String taskId,
    String caregiverId,
    String patientId,
  ) async {
    try {
      debugPrint("Task Id: $taskId");
      debugPrint("Caregiver Id: $caregiverId");
      debugPrint("Patient Id: $patientId");

      // Fetch the roles for both caregiver and patient
      final caregiverRole = await databaseService.fetchAndCacheUserRole(
        caregiverId,
      );
      final patientRole = await databaseService.fetchAndCacheUserRole(
        patientId,
      );

      if (caregiverRole == null || patientRole == null) {
        debugPrint("Failed to fetch roles. Caregiver or patient role is null.");
        showToast("Failed to mark task as complete. Roles not found.", 
            backgroundColor: AppColors.red);
        return;
      }

      // Mark the task as completed for the patient
      await taskUtility.updateTask(
        taskId: taskId,
        userId: patientId,
        collectionName: patientRole,
        subCollectionName: 'tasks',
        updates: {'isCompleted': true},
      );

      await taskUtility.updateTask(
        taskId: taskId,
        userId: caregiverId,
        collectionName: caregiverRole,
        subCollectionName: 'tasks',
        updates: {'isCompleted': true},
      );

      showToast('Task marked as complete successfully.');

      fetchPatientTasks(); // Refresh the task list
    } catch (e) {
      debugPrint("Error updating task: $e");

      showToast('Failed to mark task as complete.', 
          backgroundColor: AppColors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 700,
      color: AppColors.black.withValues(alpha: 0.8),
      width: double.infinity,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Move the button outside the hasTasks condition
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextButton(
                style: showCompleted
                    ? Buttonstyle.buttonNeon
                    : Buttonstyle.buttonPurple,
                onPressed: () {
                  setState(() {
                    showCompleted = !showCompleted;
                  });
                },
                child: Row(
                  children: [
                    Text(
                      showCompleted
                          ? 'Show Incomplete'
                          : 'Show Completed',
                      style: Textstyle.bodySmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      showCompleted
                          ? Icons.library_add_check_rounded
                          : Icons.library_add_check_outlined,
                      size: 20,
                      color: AppColors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Render tasks or no-task state
          if (isLoading)
            _buildLoadingState()
          else if (completedTasks.isEmpty && notCompletedTasks.isEmpty)
            Expanded(child: Center(child: _buildNoTaskState()))
          else if (showCompleted)
            _buildTaskList(completedTasks)
          else
            _buildTaskList(notCompletedTasks),
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

  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    return Expanded(
      child: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final String title = task['title'] ?? 'Untitled Task';
    final String description = task['description'] ?? 'No description';
    final DateTime startDate = task['startDate'];
    final DateTime endDate = task['endDate'];
    final bool isCompleted = task['isCompleted'];
    final formattedStartDate = DateFormat(
      'MMMM dd, yyyy h:mm a',
    ).format(startDate);
    final formattedEndDate = DateFormat('MMMM dd, yyyy h:mm a').format(endDate);

    return GestureDetector(
      onTap: () => _showTaskDetailsDialog(task),
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Textstyle.body.copyWith(
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : AppColors.red,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      isCompleted ? 'Complete' : 'Incomplete',
                      style: Textstyle.bodySmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.blackTransparent),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description, style: Textstyle.body),
                  const SizedBox(height: 10),
                  Text(
                    "Start Date",
                    style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(formattedStartDate, style: Textstyle.body),
                  const SizedBox(height: 5),
                  Text(
                    "End Date",
                    style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(formattedEndDate, style: Textstyle.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetailsDialog(Map<String, dynamic> task) {
    final String taskId = task['taskId'] ?? '';
    final String description = task['description'];
    final bool isCompleted = task['isCompleted'];
    final String patientId = widget.patientId;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  isCompleted ? description : "Mark task as complete?",
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    if (!isCompleted)
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            if (taskId.isNotEmpty) {
                              String caregiverId =
                                  FirebaseAuth.instance.currentUser?.uid ?? '';
                              updateTaskCompletion(
                                taskId,
                                caregiverId,
                                patientId,
                              );
                              debugPrint("Completing Task");
                              Navigator.of(context).pop();
                            }
                          },
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
                          child: const Text(
                            'Complete',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (!isCompleted) const SizedBox(width: 10.0),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          backgroundColor:
                              isCompleted ? AppColors.neon : AppColors.red,
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
}
