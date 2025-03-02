// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, no_leading_underscores_for_local_identifiers, unnecessary_null_comparison, avoid_print, unnecessary_string_interpolations, prefer_final_fields

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';

class ViewPatientTask extends StatefulWidget {
  final String patientId; // Unique ID of the patient
  final String patientName; // Full name of the patient

  const ViewPatientTask({
    super.key,
    required this.patientId,
    required this.patientName,
  });

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
    _loadTasks();
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

  Future<void> _loadTasks() async {
    print("Fetching tasks for patient: ${widget.patientId}");

    try {
      if (mounted) {
        setState(() {
          isLoading = true; // Show loading indicator
        });
      }

      final patientDoc = await FirebaseFirestore.instance
          .collection('caregiver')
          .doc(widget.patientId)
          .get();

      if (patientDoc.exists) {
        if (mounted) {
          setState(() {
            tasks = List<Map<String, dynamic>>.from(
                patientDoc.data()?['tasks'] ?? []);
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            tasks = [];
            isLoading = false;
          });
        }
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

  Future<void> _addTask(
    String title,
    String description,
    String category,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      String doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (doctorId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No doctor logged in.")),
        );
        return;
      }

      // Generate a unique task ID
      String taskId =
          '${doctorId}_${Timestamp.now().seconds}_${widget.patientId}';

      // Convert DateTime to Timestamp before saving to Firestore
      Timestamp startTimestamp = Timestamp.fromDate(startDate);
      Timestamp endTimestamp = Timestamp.fromDate(endDate);

      // Save the task for the patient
      await databaseService.saveTaskForPatient(
        widget.patientId,
        taskId, // Pass the generated task ID
        title,
        description,
        category,
        startTimestamp,
        endTimestamp,
        doctorId,
      );

      // Save the task for the doctor
      await databaseService.saveTaskForDoctor(
        doctorId,
        taskId, // Pass the same task ID
        title,
        description,
        category,
        startTimestamp,
        endTimestamp,
        widget.patientId,
      );

      // Reload tasks after saving the new one
      _loadTasks();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Task added successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add task: $e")),
      );
    }
  }

  Future<void> _removeTask(String patientId, String taskId) async {
    try {
      debugPrint("Patient ID: $patientId");
      debugPrint("Task ID: $taskId");

      // Fetch the patient document to get the list of tasks
      final patientDoc = await FirebaseFirestore.instance
          .collection('caregiver')
          .doc(patientId)
          .get();

      if (!patientDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Patient not found")),
        );
        return;
      }

      // Get the list of tasks from the patient document
      final tasksList =
          List<Map<String, dynamic>>.from(patientDoc.data()?['tasks'] ?? []);

      // Find the task to remove by taskId, return an empty map if not found
      final taskToRemove = tasksList.firstWhere(
        (task) => task['id'] == taskId,
        orElse: () => {}, // Return an empty map if the task is not found
      );

      if (taskToRemove.isEmpty) {
        debugPrint("Task with ID $taskId not found");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Task not found")),
        );
        return;
      }

      // Remove the task from the Firestore array
      await FirebaseFirestore.instance
          .collection('caregiver')
          .doc(patientId)
          .update({
        'tasks': FieldValue.arrayRemove([taskToRemove]),
      });

      // Show a snackbar to notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task removed successfully!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Error removing task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _showAddTaskDialog() {
    String taskTitle = '';
    String taskDescription = '';
    String selectedCategory = 'Medication'; // Default category
    DateTime taskStartDate = DateTime.now();
    DateTime taskEndDate = DateTime.now()
        .add(Duration(hours: 1)); // Default to 1 hour after start date

    final List<String> categories = [
      'Medication',
      'Heart Rate',
      'Blood Pressure',
      'Blood Oxygen',
      'Temperature',
      'Weight',
      'Pain Assessment',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> _selectDateTime(
                BuildContext context, bool isStartDate) async {
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

            return LayoutBuilder(
              builder: (context, constraints) {
                return AlertDialog(
                  backgroundColor: AppColors.white,
                  title: Text(
                    "Add Task",
                    style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  content: SizedBox(
                    width: constraints.maxWidth * 0.9, // Adjust width here
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Task Title Field
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
                                color: _focusNodes[0].hasFocus
                                    ? AppColors.neon
                                    : AppColors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Task Description Field
                          TextFormField(
                            onChanged: (value) => taskDescription = value,
                            focusNode:
                                _focusNodes[1], // Focus for Task Description
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
                                color: _focusNodes[1].hasFocus
                                    ? AppColors.neon
                                    : AppColors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Category Dropdown
                          DropdownButtonFormField<String>(
                            value:
                                selectedCategory, // The currently selected category
                            focusNode:
                                _focusNodes[2], // Focus for Category Dropdown
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.normal,
                              color: AppColors.black,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Category',
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
                                color: _focusNodes[4].hasFocus
                                    ? AppColors.neon
                                    : AppColors.black,
                              ),
                            ),
                            items: categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(
                                  category,
                                  style: TextStyle(
                                      color: AppColors.black, fontSize: 16),
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setModalState(() {
                                selectedCategory = newValue ??
                                    ''; // Update the selected category
                              });
                            },
                            validator: (val) => val == null || val.isEmpty
                                ? 'Select a category'
                                : null,
                            dropdownColor: AppColors.white,
                          ),

                          const SizedBox(height: 20),

                          // Start Date Field
                          TextFormField(
                            controller: _startDateController,
                            focusNode: _focusNodes[3], // Focus for Start Date
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
                                color: _focusNodes[3].hasFocus
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
                                color: _focusNodes[3].hasFocus
                                    ? AppColors.neon
                                    : AppColors.black,
                              ),
                            ),
                            validator: (val) =>
                                val!.isEmpty || val == 'Select Start Date'
                                    ? 'Start date cannot be empty'
                                    : null,
                            readOnly: true,
                            onTap: () => _selectDateTime(context, true),
                          ),
                          const SizedBox(height: 20),

                          // End Date Field
                          TextFormField(
                            controller: _endDateController,
                            focusNode: _focusNodes[4], // Focus for End Date
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
                                color: _focusNodes[4].hasFocus
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
                                color: _focusNodes[4].hasFocus
                                    ? AppColors.neon
                                    : AppColors.black,
                              ),
                            ),
                            validator: (val) =>
                                val!.isEmpty || val == 'Select End Date'
                                    ? 'End date cannot be empty'
                                    : null,
                            readOnly: true,
                            onTap: () => _selectDateTime(context, false),
                          ),

                          SizedBox(
                            height: 20.0,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  backgroundColor: AppColors.red,
                                ),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 10.0,
                              ),
                              TextButton(
                                onPressed: () {
                                  if (taskTitle.isNotEmpty &&
                                      taskDescription.isNotEmpty &&
                                      taskStartDate != null &&
                                      taskEndDate != null &&
                                      taskStartDate.isBefore(taskEndDate)) {
                                    _addTask(
                                        taskTitle,
                                        taskDescription,
                                        selectedCategory,
                                        taskStartDate,
                                        taskEndDate);
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text("Invalid inputs!")),
                                    );
                                  }
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  backgroundColor: AppColors.neon,
                                ),
                                child: Text(
                                  "Add Task",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> fetchPatientTasks() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('caregiver')
          .doc(widget.patientId) // Use the patientId passed to the widget
          .get();

      if (snapshot.exists) {
        final List<dynamic> tasksData = snapshot.data()?['tasks'] ?? [];
        final List<Map<String, dynamic>> filteredTasks = [];
        final DateTime today = DateTime.now();

        for (var task in tasksData) {
          // Extract task details, handle missing fields
          final String taskId = task['id'] ?? '';
          final String title = task['title'] ?? 'Untitled Task';
          final String category = task['category'] ?? 'General';
          final String description = task['description'] ?? 'No description';
          final DateTime? startDate = task['startDate'] is Timestamp
              ? (task['startDate'] as Timestamp).toDate()
              : null;
          final DateTime? endDate = task['endDate'] is Timestamp
              ? (task['endDate'] as Timestamp).toDate()
              : null;

          if (startDate != null && endDate != null) {
            // Filter tasks by current date range
            if ((today.isAfter(startDate) ||
                    today.isAtSameMomentAs(startDate)) &&
                (today.isBefore(endDate.add(Duration(days: 1))) ||
                    today.isAtSameMomentAs(endDate))) {
              filteredTasks.add({
                'id': taskId,
                'title': title,
                'category': category,
                'description': description,
                'startDate': startDate,
                'endDate': endDate,
                'isCompleted': task['isCompleted'] ?? false,
              });
            }
          }
        }
        if (mounted) {
          setState(() {
            tasks = filteredTasks;
          });
        }
      } else {
        debugPrint("No document found for patientId: ${widget.patientId}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch tasks: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String getIconForCategory(String category) {
    switch (category) {
      case 'Medication':
        return 'lib/assets/images/shared/vitals/medicine_black.png';
      case 'Heart Rate':
        return 'lib/assets/images/shared/vitals/heart_rate_black.png';
      case 'Blood Pressure':
        return 'lib/assets/images/shared/vitals/blood_pressure_black.png';
      case 'Blood Oxygen':
        return 'lib/assets/images/shared/vitals/blood_oxygen_black.png';
      case 'Temperature':
        return 'lib/assets/images/shared/vitals/temperature_black.png';
      case 'Weight':
        return 'lib/assets/images/shared/vitals/weight_black.png';
      case 'Pain Assessment':
        return 'lib/assets/images/shared/vitals/pain_assessment_black.png';
      default:
        return 'lib/assets/images/shared/vitals/task_black.png';
    }
  }

  Stream<DocumentSnapshot> _getPatientTaskStream(String patientId) {
    final collections = [
      'caregiver',
      'doctor',
      'admin',
      'patient',
      'unregistered'
    ];

    return Stream<DocumentSnapshot>.multi((controller) async {
      for (String collection in collections) {
        final stream = FirebaseFirestore.instance
            .collection(collection)
            .doc(patientId)
            .snapshots();
        await for (final snapshot in stream) {
          if (snapshot.exists) {
            controller.add(snapshot);
            return; // Exit once the patient document is found
          }
        }
      }
      controller.addError('Patient not found in any collection.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          "View Tasks for ${widget.patientName}",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _getPatientTaskStream(widget.patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
                child: Text("No tasks available for ${widget.patientName}"));
          }

          // Cast the snapshot data to a Map<String, dynamic>
          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Extract the tasks from the 'tasks' field
          final tasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []);

          // If the tasks list is empty
          if (tasks.isEmpty) {
            return Center(
              child: Text(
                "No tasks available for ${widget.patientName}",
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final String title = task['title'] ?? 'Untitled Task';
                final String description =
                    task['description'] ?? 'No description';
                final DateTime startDate = task['startDate'].toDate();
                final DateTime endDate = task['endDate'].toDate();
                final String category = task['category'] ?? 'General';
                final String taskIcon = getIconForCategory(category);
                final String taskId =
                    task['id']; // Extract the taskId from the task data

                return GestureDetector(
                  onTap: () {
                    // Show the alert dialog modal when the container is tapped
                    showDialog(
                      context: context,
                      builder: (context) => LayoutBuilder(
                        builder: (context, constraints) {
                          return Dialog(
                            backgroundColor: AppColors.white,
                            insetPadding: const EdgeInsets.all(
                                10), // Reduce padding for max width
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    constraints.maxWidth, // Consume max width
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    16.0), // Add padding inside dialog
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 10.0),

                                    // Description
                                    const Text(
                                      "Description",
                                      style: TextStyle(
                                        fontSize: 18,
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
                                    const SizedBox(height: 10.0),

                                    // Start Date
                                    const Text(
                                      "Start Date",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('yyyy-MM-dd HH:mm')
                                          .format(startDate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.normal,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 10.0),

                                    // End Date
                                    const Text(
                                      "End Date",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('yyyy-MM-dd HH:mm')
                                          .format(endDate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.normal,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 20.0),

                                    // Buttons Section
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Remove Task Button
                                        TextButton(
                                          onPressed: () async {
                                            await _removeTask(
                                                widget.patientId, taskId);
                                            Navigator.of(context).pop();
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 15, vertical: 5),
                                            backgroundColor: AppColors.neon,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                        const SizedBox(width: 10.0),

                                        // Close Button
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 15, vertical: 5),
                                            backgroundColor: AppColors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: Card(
                    color: AppColors.white,
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          10.0), // Apply border radius to the Container
                      child: Container(
                        color: AppColors.gray,
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  taskIcon,
                                  height: 30,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(description, style: TextStyle(fontSize: 16)),
                            SizedBox(height: 8),
                            Text(
                              "Start: ${DateFormat('yyyy-MM-dd HH:mm').format(startDate)}",
                              style: TextStyle(color: AppColors.black),
                            ),
                            Text(
                              "End: ${DateFormat('yyyy-MM-dd HH:mm').format(endDate)}",
                              style: TextStyle(color: AppColors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neon,
        onPressed: _showAddTaskDialog,
        child: Icon(
          Icons.add,
          color: AppColors.white,
        ),
      ),
    );
  }
}
