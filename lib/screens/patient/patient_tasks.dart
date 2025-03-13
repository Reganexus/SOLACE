import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solace/themes/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientTasks extends StatefulWidget {
  const PatientTasks({super.key, required this.patientId});
  final String patientId;

  @override
  PatientTasksState createState() => PatientTasksState();
}

class PatientTasksState extends State<PatientTasks> {
  List<Map<String, dynamic>> tasks = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchPatientTasks();
  }

  Future<void> fetchPatientTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('patient')
            .doc(widget.patientId)
            .get();

        debugPrint("Snapshot: $snapshot");

        if (snapshot.exists) {
          // Extract the tasks from the document
          final List<dynamic> taskData = snapshot.data()?['tasks'] ??
              []; // Assuming 'tasks' is an array in the document
          debugPrint("Task Data: $taskData");
          if (taskData.isEmpty) {
            // No tasks available, handle it here
            setState(() {
              _isLoading = false;
              tasks = []; // Clear any previously fetched tasks
            });
            return;
          }

          // Process the tasks data
          final List<Map<String, dynamic>> tasksList = [];
          for (var task in taskData) {
            tasksList.add({
              'id': task['id'], // Assuming task has an 'id' field
              'title': task['title'], // Assuming task has a 'title' field
              'description': task['description'] ??
                  'No description available', // Default description if null
              'category':
                  task['category'], // Assuming task has a 'category' field
              'endDate': task[
                  'endDate'], // Assuming task has an 'endDate' field (Timestamp)
              'startDate': task[
                  'startDate'], // Assuming task has a 'startDate' field (Timestamp)
              'isCompleted': task[
                  'isCompleted'], // Assuming task has an 'isCompleted' field
              'timestamp': task[
                  'timestamp'], // Assuming task has a 'timestamp' field (Timestamp)
              'icon': task['icon'] ??
                  'lib/assets/images/shared/vitals/medicine_black.png', // Default icon if 'icon' is null
            });
          }

          debugPrint("Task List: $tasksList");

          // Update the state with the fetched tasks
          setState(() {
            tasks = tasksList; // Assign tasks to your state variable
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No tasks found for the user.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch tasks: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Tasks',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : tasks.isEmpty
                    ? _buildNoTasksState()
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final taskTitle = task['title'];
                          final taskIcon = task['icon'];
                          final taskDescription =
                              task['description'] ?? 'No description available';
                          final startDate = task['startDate'];
                          final endDate = task['endDate'];

                          // Format start and end dates
                          final startFormatted = startDate != null
                              ? DateFormat('MMMM d, y \'at\' h:mm a').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                          startDate.seconds * 1000)
                                      .toLocal())
                              : 'No start date available';

                          final endFormatted = endDate != null
                              ? DateFormat('MMMM d, y \'at\' h:mm a').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                          endDate.seconds * 1000)
                                      .toLocal())
                              : 'No end date available';

                          // Skip tasks with missing title or icon
                          if (taskTitle == null || taskIcon == null) {
                            return SizedBox.shrink();
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 15.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: AppColors.gray,
                            ),
                            padding: const EdgeInsets.all(16.0),
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
                                    Text(
                                      taskTitle,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Divider(thickness: 1.0),
                                const SizedBox(height: 10),
                                const Text(
                                  "Description",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  taskDescription,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.normal,
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "Start Date",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  startFormatted,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.normal,
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "End Date",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  endFormatted,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.normal,
                                    color: AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }

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
            onPressed: fetchPatientTasks,
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

  Widget _buildNoTasksState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.assignment_late,
            color: AppColors.black,
            size: 80,
          ),
          SizedBox(height: 20.0),
          Text(
            "No tasks available",
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
