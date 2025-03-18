// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, no_leading_underscores_for_local_identifiers, unnecessary_null_comparison, avoid_print, unnecessary_string_interpolations, prefer_final_fields

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';

class ViewPatientTask extends StatefulWidget {
  final String patientId;

  const ViewPatientTask({super.key, required this.patientId});

  @override
  _ViewPatientTaskState createState() => _ViewPatientTaskState();
}

class _ViewPatientTaskState extends State<ViewPatientTask> {
  late DatabaseService databaseService;
  List<Map<String, dynamic>> tasks = [];
  List<FocusNode> _focusNodes = [];
  bool isLoading = true;

  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();

  DateTime? taskStartDate; // Initially null
  DateTime? taskEndDate; // Initially null

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(5, (index) => FocusNode());
    databaseService = DatabaseService(); // Initialize the DatabaseService
    _startDateController.text = 'Select Start Date';
    _endDateController.text = 'Select End Date';

    _fetchPatientTasks();
    _resetDateControllers();
  }

  @override
  void dispose() {
    // Dispose focus nodes to prevent memory leaks
    for (var node in _focusNodes) {
      node.dispose();
    }
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatientTasks() async {
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
            tasks = []; // No tasks found
            isLoading = false;
          });
        }
        return;
      }

      // Accumulate all tasks from different caregiver documents
      final List<Map<String, dynamic>> loadedTasks = [];
      for (var caregiverDoc in caregiverTasksSnapshot.docs) {
        final caregiverData = caregiverDoc.data();
        final caregiverId = caregiverDoc.id;
        final caregiverTasks = List<Map<String, dynamic>>.from(
          caregiverData['tasks'] ?? [],
        );

        // Fetch caregiver details
        final caregiverRole = await databaseService.getTargetUserRole(
          caregiverId,
        );
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

            loadedTasks.add({
              'caregiverName': caregiverName,
              'title': task['title'],
              'description': task['description'],
              'startDate': startDate,
              'endDate': endDate,
              'isCompleted': task['isCompleted'],
              'taskId': taskId, // Ensure taskId is included
            });
          }
        }
      }

      // Sort tasks by start date
      loadedTasks.sort((a, b) => a['startDate'].compareTo(b['startDate']));
      if (mounted) {
        setState(() {
          tasks = loadedTasks;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading tasks: $e");
      if (mounted) {
        setState(() {
          tasks = [];
          isLoading = false;
        });
      }
    }
  }

  void _resetDateControllers() {
    _startDateController.text = 'Select Start Date';
    _endDateController.text = 'Select End Date';
    taskStartDate = null;
    taskEndDate = null;
  }

  Future<void> _removeTask(
    String patientId,
    String taskId,
    String caregiverId,
  ) async {
    try {
      DatabaseService db = DatabaseService();
      await db.removeTask(patientId, taskId, caregiverId); // Remove the task

      // Show snackbar indicating the task was deleted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task deleted successfully'),
          backgroundColor:
              Colors.green, // Optional, set the color of the snackbar
        ),
      );

      // Fetch the updated list of tasks after the removal
      _fetchPatientTasks();
    } catch (e) {
      print("Error removing task: $e");

      // Show snackbar indicating there was an error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete task'),
          backgroundColor:
              Colors.red, // Optional, set the color of the snackbar
        ),
      );
    }
  }

  Future<void> _addTask(
    String title,
    String description,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      String caregiverId = FirebaseAuth.instance.currentUser?.uid ?? '';
      debugPrint("Add task caregiver id: $caregiverId");

      if (caregiverId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("No caregiver logged in.")));
        return;
      }

      // Capitalize title and description
      String capitalizeWords(String input) {
        return input
            .split(' ')
            .map((word) {
              return word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : word;
            })
            .join(' ');
      }

      title = capitalizeWords(title);
      description = capitalizeWords(description);

      // Generate a unique task ID
      String taskId = FirebaseFirestore.instance.collection('_').doc().id;

      // Save the task for the patient
      await databaseService.saveTaskForPatient(
        widget.patientId,
        taskId, // Pass the generated task ID
        title,
        description,
        startDate, // Pass DateTime directly
        endDate, // Pass DateTime directly
        caregiverId,
      );

      // Save the task for the caregiver
      await databaseService.saveTaskForCaregiver(
        caregiverId,
        taskId, // Pass the same task ID
        title,
        description,
        startDate, // Pass DateTime directly
        endDate, // Pass DateTime directly
        widget.patientId,
      );

      // Reload tasks after saving the new one
      _fetchPatientTasks();
      _resetDateControllers();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Task added successfully")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to add task: $e")));
    }
  }

  void _showAddTaskDialog() {
    String taskTitle = '';
    String taskDescription = '';
    DateTime taskStartDate = DateTime.now();
    DateTime taskEndDate = DateTime.now().add(
      Duration(hours: 1),
    ); // Default to 1 hour after start date

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> _selectDateTime(
              BuildContext context,
              bool isStartDate,
            ) async {
              final DateTime initialDate =
                  isStartDate ? taskStartDate : taskEndDate;

              // Date Picker
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: 30)),
                builder: (BuildContext context, Widget? child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppColors.neon,
                        onPrimary: AppColors.white,
                        onSurface: AppColors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                // Time Picker
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(initialDate),
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.neon,
                          onPrimary: AppColors.white,
                          onSurface: AppColors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (pickedTime != null) {
                  final DateTime selectedDateTime = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  setModalState(() {
                    if (isStartDate) {
                      taskStartDate = selectedDateTime;
                      _startDateController.text =
                          '${DateFormat('MMMM dd, yyyy').format(taskStartDate)} at ${DateFormat('h:mm a').format(taskStartDate)}';
                    } else {
                      taskEndDate = selectedDateTime;
                      _endDateController.text =
                          '${DateFormat('MMMM dd, yyyy').format(taskEndDate)} at ${DateFormat('h:mm a').format(taskEndDate)}';
                    }
                  });
                }
              }
            }

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
                    const Text(
                      "Add Task",
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      onChanged: (value) => taskTitle = value,
                      focusNode: _focusNodes[0], // Focus for Task Title
                      decoration: InputDecoration(
                        labelText: "Task Title",
                        filled: true,
                        fillColor: AppColors.gray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.neon,
                            width: 2,
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.normal,
                          color:
                              _focusNodes[0].hasFocus
                                  ? AppColors.neon
                                  : AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Task Description Field
                    TextFormField(
                      onChanged: (value) => taskDescription = value,
                      focusNode: _focusNodes[1], // Focus for Task Description
                      decoration: InputDecoration(
                        labelText: "Task Description",
                        filled: true,
                        fillColor: AppColors.gray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.neon,
                            width: 2,
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.normal,
                          color:
                              _focusNodes[1].hasFocus
                                  ? AppColors.neon
                                  : AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Start Date Field
                    TextFormField(
                      controller: _startDateController,
                      focusNode: _focusNodes[2], // Focus for Start Date
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                        color: AppColors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        filled: true,
                        fillColor: AppColors.gray,
                        suffixIcon: Icon(
                          Icons.calendar_today,
                          color:
                              _focusNodes[2].hasFocus
                                  ? AppColors.neon
                                  : AppColors.black,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.neon,
                            width: 2,
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.normal,
                          color:
                              _focusNodes[3].hasFocus
                                  ? AppColors.neon
                                  : AppColors.black,
                        ),
                      ),
                      validator:
                          (val) =>
                              val!.isEmpty || val == 'Select Start Date'
                                  ? 'Start date cannot be empty'
                                  : null,
                      readOnly: true,
                      onTap: () => _selectDateTime(context, true),
                    ),
                    const SizedBox(height: 10),

                    // End Date Field
                    TextFormField(
                      controller: _endDateController,
                      focusNode: _focusNodes[3], // Focus for End Date
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                        color: AppColors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        filled: true,
                        fillColor: AppColors.gray,
                        suffixIcon: Icon(
                          Icons.calendar_today,
                          color:
                              _focusNodes[3].hasFocus
                                  ? AppColors.neon
                                  : AppColors.black,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.neon,
                            width: 2,
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.normal,
                          color:
                              _focusNodes[3].hasFocus
                                  ? AppColors.neon
                                  : AppColors.black,
                        ),
                      ),
                      validator:
                          (val) =>
                              val!.isEmpty || val == 'Select End Date'
                                  ? 'End date cannot be empty'
                                  : null,
                      readOnly: true,
                      onTap: () => _selectDateTime(context, false),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 5,
                              ),
                              backgroundColor: AppColors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.0),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              if (taskTitle.isNotEmpty &&
                                  taskDescription.isNotEmpty &&
                                  taskStartDate != null &&
                                  taskEndDate != null &&
                                  taskStartDate.isBefore(taskEndDate)) {
                                _addTask(
                                  taskTitle,
                                  taskDescription,
                                  taskStartDate,
                                  taskEndDate,
                                );
                                Navigator.pop(context);
                                _fetchPatientTasks();
                                _resetDateControllers();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Invalid inputs!")),
                                );
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
                            child: Text(
                              "Add Task",
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
      },
    );
  }

  Widget _buildNoTaskState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.event_busy, color: AppColors.black, size: 80),
          SizedBox(height: 20.0),
          Text(
            "No task yet",
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
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : tasks.isEmpty
              ? _buildNoTaskState()
              : _buildTaskList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neon,
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildTaskList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 10.0),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: _buildTaskCard(task),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final String title = task['title'] ?? 'Untitled Task';
    final String description = task['description'] ?? 'No description';
    final DateTime startDate = task['startDate'];
    final DateTime endDate = task['endDate'];
    final String taskIcon = 'lib/assets/images/shared/vitals/task_black.png';

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
    debugPrint("Task $task");
    final String title = task['title'] ?? 'Untitled Task';
    final String taskId = task['taskId'] ?? '';
    debugPrint("Task Title: $title");
    debugPrint("Task ID: $taskId");
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
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  "Do you want to delete this task?",
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
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          if (taskId.isNotEmpty) {
                            String caregiverId =
                                FirebaseAuth.instance.currentUser?.uid ?? '';
                            await _removeTask(
                              widget.patientId,
                              taskId,
                              caregiverId,
                            ); // Remove task and refresh
                            Navigator.of(context).pop(); // Close dialog
                          }
                        },

                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          backgroundColor: AppColors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Remove Task',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pop(); // Close dialog without doing anything
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
