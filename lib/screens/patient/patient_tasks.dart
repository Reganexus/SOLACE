import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientTasks extends StatefulWidget {
  const PatientTasks({super.key, required this.currentUserId});
  final String currentUserId;

  @override
  _PatientTasksState createState() => _PatientTasksState();
}

class _PatientTasksState extends State<PatientTasks> {
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
      final String patientId = widget.currentUserId; // Use the passed user ID
      try {
        // Query the 'caregiver' collection for the document of the current user
        final snapshot = await FirebaseFirestore.instance
            .collection(
                'caregiver') // Assuming tasks are stored in the 'caregiver' collection
            .doc(patientId) // Fetch the specific caregiver document
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
              'description': task['description'] ?? 'No description available', // Default description if null
              'category': task['category'], // Assuming task has a 'category' field
              'endDate': task['endDate'], // Assuming task has an 'endDate' field (Timestamp)
              'startDate': task['startDate'], // Assuming task has a 'startDate' field (Timestamp)
              'isCompleted': task['isCompleted'], // Assuming task has an 'isCompleted' field
              'timestamp': task['timestamp'], // Assuming task has a 'timestamp' field (Timestamp)
              'icon': task['icon'] ?? 'lib/assets/images/shared/vitals/medicine_black.png', // Default icon if 'icon' is null
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

  void _showTaskModal(
      BuildContext context,
      String taskTitle,
      String taskDescription,
      Timestamp startDate,
      Timestamp endDate,
      ) {
    // Format the start and end dates
    String startFormatted = startDate != null
        ? DateTime.fromMillisecondsSinceEpoch(startDate.seconds * 1000)
        .toLocal()
        .toString()
        : 'No start date available';
    String endFormatted = endDate != null
        ? DateTime.fromMillisecondsSinceEpoch(endDate.seconds * 1000)
        .toLocal()
        .toString()
        : 'No end date available';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(taskTitle),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: $taskDescription'),
              const SizedBox(height: 10),
              Text('Start Date: $startFormatted'),
              const SizedBox(height: 10),
              Text('End Date: $endFormatted'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
      appBar: AppBar(
        title: const Text(
          'Tasks',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage.isNotEmpty
            ? _buildErrorState()
            : tasks.isEmpty
            ? _buildNoTasksState()
            : ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            // Safely check if the values exist
            final task = tasks[index];
            final taskTitle = task['title'];
            final taskIcon = task['icon'];
            final taskDescription = task['description'] ?? 'No description available';

            if (taskTitle == null || taskIcon == null) {
              // If task title or icon is null, skip this task
              return SizedBox.shrink();
            }

            return GestureDetector(
              onTap: () {
                _showTaskModal(
                  context,
                  taskTitle,
                  taskDescription,
                  task['startDate'], // Assuming 'startDate' is a Timestamp field
                  task['endDate'],   // Assuming 'endDate' is a Timestamp field
                );

              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 15.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: AppColors.gray, // Or whatever background color you want
                ),
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
                child: Row(
                  children: [
                    Image.asset(
                      taskIcon,
                      height: 30,
                    ),
                    const SizedBox(width: 10.0),
                    Text(
                      taskTitle,
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'Outfit',
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
