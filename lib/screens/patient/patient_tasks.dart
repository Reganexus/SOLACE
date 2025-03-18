// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientTasks extends StatefulWidget {
  const PatientTasks({super.key, required this.patientId});
  final String patientId;

  @override
  PatientTasksState createState() => PatientTasksState();
}

class PatientTasksState extends State<PatientTasks> {
  List<Map<String, dynamic>> completedTasks = [];
  List<Map<String, dynamic>> notCompletedTasks = [];
  bool isLoading = false;
  bool showCompleted = true;

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

    try {
      if (mounted) {
        setState(() {
          isLoading = true; // Show loading indicator
        });
      }

      // Fetch the caregiver documents under the patient's tasks subcollection
      final caregiverTasksSnapshot =
          await FirebaseFirestore.instance
              .collection('patient') // Top-level patient collection
              .doc(widget.patientId) // Target patient document
              .collection('tasks') // Tasks subcollection
              .get();

      if (caregiverTasksSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            completedTasks = []; // No tasks found
            notCompletedTasks = [];
            isLoading = false;
          });
        }
        return;
      }

      // Accumulate all tasks from different caregiver documents
      final List<Map<String, dynamic>> loadedCompletedTasks = [];
      final List<Map<String, dynamic>> loadedNotCompletedTasks = [];
      for (var caregiverDoc in caregiverTasksSnapshot.docs) {
        final caregiverData = caregiverDoc.data();
        final caregiverId = caregiverDoc.id;
        final caregiverTasks = List<Map<String, dynamic>>.from(
          caregiverData['tasks'] ?? [],
        );

        DatabaseService db = DatabaseService();
        final String? caregiverRole = await db.getTargetUserRole(caregiverId);
        if (caregiverRole == null) continue;

        final caregiverSnapshot =
            await FirebaseFirestore.instance
                .collection(caregiverRole)
                .doc(caregiverId)
                .get();

        if (caregiverSnapshot.exists) {
          final caregiverName =
              '${caregiverSnapshot['firstName']} ${caregiverSnapshot['lastName']}';

          for (var task in caregiverTasks) {
            final startDate = (task['startDate'] as Timestamp?)?.toDate();
            final endDate = (task['endDate'] as Timestamp?)?.toDate();
            final taskId =
                task['taskId'] ?? 'defaultTaskId'; // Ensure taskId is non-null

            if (startDate == null || endDate == null || taskId.isEmpty) {
              continue;
            }

            final taskData = {
              'caregiverName': caregiverName,
              'title': task['title'],
              'description': task['description'],
              'startDate': startDate,
              'endDate': endDate,
              'isCompleted': task['isCompleted'],
              'taskId': taskId, // Ensure taskId is included
            };

            if (task['isCompleted'] == true) {
              loadedCompletedTasks.add(taskData);
            } else {
              loadedNotCompletedTasks.add(taskData);
            }
          }
        }
      }

      // Sort tasks by start date
      loadedCompletedTasks.sort(
        (a, b) => a['startDate'].compareTo(b['startDate']),
      );
      loadedNotCompletedTasks.sort(
        (a, b) => a['startDate'].compareTo(b['startDate']),
      );

      if (mounted) {
        setState(() {
          completedTasks = loadedCompletedTasks;
          notCompletedTasks = loadedNotCompletedTasks;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading tasks: $e");
      if (mounted) {
        setState(() {
          completedTasks = [];
          notCompletedTasks = [];
          isLoading = false;
        });
      }
    }
  }

  Widget _buildNoTaskState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center, // Center vertically
      crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
      children: const [
        Icon(Icons.event_busy, color: AppColors.black, size: 80),
        SizedBox(height: 20.0),
        Text(
          "Great Work! No Tasks",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.normal,
            color: AppColors.black,
          ),
          textAlign: TextAlign.center,
        )
      ],
    );
  }

  // Function to update isCompleted field in Firestore
  Future<void> updateTaskCompletion(
    String taskId,
    String caregiverId,
    String patientId,
  ) async {
    try {
      debugPrint("Task Id: $taskId");
      debugPrint("Task caregiverId: $caregiverId");
      debugPrint("Task patientId: $patientId");

      DatabaseService db = DatabaseService();
      await db.updateTask(taskId, caregiverId, patientId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task marked as complete successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      fetchPatientTasks(); // Refresh task list
    } catch (e) {
      debugPrint("Error updating task: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark task as complete.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          "View Tasks",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Important for proper alignment
              children: [
                if (showCompleted)
                  IconButton(
                    icon: const Icon(
                      Icons.library_add_check_rounded,
                      size: 28,
                      color: AppColors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        showCompleted = false;
                      });
                    },
                  ),
                if (!showCompleted)
                  IconButton(
                    icon: const Icon(
                      Icons.library_add_check_outlined,
                      size: 28,
                      color: AppColors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        showCompleted = true;
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child: LayoutBuilder(
          // Use LayoutBuilder
          builder: (context, constraints) {
            return isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    if (showCompleted && completedTasks.isNotEmpty) ...[
                      _buildTaskList(completedTasks, 'Completed Tasks'),
                    ],
                    if (!showCompleted && notCompletedTasks.isNotEmpty) ...[
                      _buildTaskList(notCompletedTasks, 'Not Completed Tasks'),
                    ],
                    if ((showCompleted && completedTasks.isEmpty) ||
                        (!showCompleted && notCompletedTasks.isEmpty))
                      SizedBox(
                        height: constraints.maxHeight,
                        width: constraints.maxWidth,
                        child: _buildNoTaskState(),
                      ),
                  ],
                );
          },
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Map<String, dynamic>> tasks, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          padding: const EdgeInsets.only(bottom: 10.0),
          shrinkWrap: true, // Make ListView scrollable within the column
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildTaskCard(task),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final String title = task['title'] ?? 'Untitled Task';
    final String description = task['description'] ?? 'No description';
    final DateTime startDate = task['startDate'];
    final DateTime endDate = task['endDate'];
    final String taskIcon = 'lib/assets/images/shared/vitals/task_black.png';
    final bool isCompleted = task['isCompleted'];

    return GestureDetector(
      onTap: () => _showTaskDetailsDialog(task),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.gray,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(taskIcon, height: 25),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Divider(thickness: 1.0),
            const SizedBox(height: 5),
            const Text(
              "Description",
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.normal,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Start Date",
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(startDate),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.normal,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "End Date",
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(endDate),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.normal,
                color: AppColors.black,
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
