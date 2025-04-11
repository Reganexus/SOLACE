// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, no_leading_underscores_for_local_identifiers, unnecessary_null_comparison, avoid_print, unnecessary_string_interpolations, prefer_final_fields

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/inputdecoration.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:solace/utility/task_utility.dart';

class ViewPatientTask extends StatefulWidget {
  final String patientId;

  const ViewPatientTask({super.key, required this.patientId});

  @override
  _ViewPatientTaskState createState() => _ViewPatientTaskState();
}

class _ViewPatientTaskState extends State<ViewPatientTask> {
  final LogService _logService = LogService();
  final DatabaseService databaseService = DatabaseService();
  final TaskUtility taskUtility = TaskUtility();
  List<Map<String, dynamic>> tasks = [];
  List<FocusNode> _focusNodes = [];
  bool isLoading = true;

  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();

  DateTime? taskStartDate;
  DateTime? taskEndDate;
  late String patientName = '';

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(5, (index) => FocusNode());
    _titleController.text = '';
    _descriptionController.text = '';
    _startDateController.text = 'Select Start Date/Time';
    _endDateController.text = 'Select End Date/Time';

    _fetchPatientTasks();
    _resetDateControllers();
    _loadPatientName();
    debugPrint("Patient Name: $patientName");
  }

  @override
  void dispose() {
    // Dispose focus nodes to prevent memory leaks
    for (var node in _focusNodes) {
      node.dispose();
    }
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientName() async {
    final name = await databaseService.fetchUserName(widget.patientId);
    if (mounted) {
      setState(() {
        patientName = name ?? 'Unknown';
      });
    }
    debugPrint("Patient Name: $patientName");
  }

  Future<void> _fetchPatientTasks() async {
    print("Fetching tasks for patient: ${widget.patientId}");

    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final tasksRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(widget.patientId)
          .collection('tasks');

      final taskSnapshots = await tasksRef.get();

      if (taskSnapshots.docs.isEmpty) {
        if (mounted) {
          setState(() {
            tasks = [];
            isLoading = false;
          });
        }
        return;
      }

      final List<Map<String, dynamic>> loadedTasks =
          taskSnapshots.docs
              .map((doc) {
                final data = doc.data();
                final startDate = (data['startDate'] as Timestamp?)?.toDate();
                final endDate = (data['endDate'] as Timestamp?)?.toDate();
                final isCompleted = data['isCompleted'] ?? false;

                return {
                  'taskId': doc.id,
                  'title': data['title'],
                  'description': data['description'],
                  'startDate': startDate,
                  'endDate': endDate,
                  'isCompleted': isCompleted,
                };
              })
              .where((task) => task['startDate'] != null)
              .toList();

      loadedTasks.sort((a, b) => a['startDate']!.compareTo(b['startDate']!));

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
    _titleController.text = '';
    _descriptionController.text = '';
    _startDateController.text = 'Select Start Date/Time';
    _endDateController.text = 'Select End Date/Time';
    taskStartDate = null;
    taskEndDate = null;
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

  String getTaskNameById(String taskId) {
    final task = tasks.firstWhere(
      (med) => med['taskId'] == taskId,
      orElse: () => {'taskName': 'Unknown Task'},
    );
    return task['taskName'] ?? 'Unknown Task';
  }

  Future<void> _removeTask(
    String patientId,
    String taskId,
    String caregiverId,
  ) async {
    try {
      // Fetch the roles for both caregiver and patient
      final caregiverRole = await databaseService.fetchAndCacheUserRole(
        caregiverId,
      );
      final patientRole = await databaseService.fetchAndCacheUserRole(
        patientId,
      );

      // Check if the roles were successfully fetched
      if (caregiverRole == null || patientRole == null) {
        debugPrint("Failed to fetch roles. Caregiver or patient role is null.");
        showToast(
          "Failed to remove task. Roles not found.",
          backgroundColor: AppColors.red,
        );
        return;
      }

      // Remove the task for the patient
      await taskUtility.removeTask(
        userId: patientId,
        taskId: taskId,
        collectionName: patientRole,
        subCollectionName: 'tasks',
      );

      // Remove the task for the caregiver
      await taskUtility.removeTask(
        userId: caregiverId,
        taskId: taskId,
        collectionName: caregiverRole,
        subCollectionName: 'tasks',
      );

      await _logService.addLog(
        userId: caregiverId,
        action:
            "Removed Medicine ${getTaskNameById(taskId)} from patient $patientName",
      );

      showToast('Task deleted successfully');
      _fetchPatientTasks();
    } catch (e) {
      debugPrint("Error removing task: $e");
      showToast('Failed to delete task: $e', backgroundColor: AppColors.red);
    }
  }

  Future<void> _addTask(
    String title,
    String description,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get the caregiver ID (logged-in user)
      String caregiverId = FirebaseAuth.instance.currentUser?.uid ?? '';
      debugPrint("Add task caregiver id: $caregiverId");

      if (caregiverId.isEmpty) {
        showToast("No caregiver logged in.", backgroundColor: AppColors.red);
        return;
      }

      // Capitalize the title and description
      String capitalizeWords(String input) {
        return input
            .split(' ')
            .map(
              (word) =>
                  word.isNotEmpty
                      ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                      : word,
            )
            .join(' ');
      }

      title = capitalizeWords(title);
      description = capitalizeWords(description);

      // Generate a unique task ID
      String taskId = FirebaseFirestore.instance.collection('_').doc().id;

      // Fetch the roles for both caregiver and patient
      final caregiverRole = await databaseService.fetchAndCacheUserRole(
        caregiverId,
      );
      final patientRole = await databaseService.fetchAndCacheUserRole(
        widget.patientId,
      );

      if (caregiverRole == null || patientRole == null) {
        debugPrint("Failed to fetch roles. Caregiver or patient role is null.");
        showToast(
          "Failed to add task. Roles not found.",
          backgroundColor: AppColors.red,
        );
        return;
      }

      // Save the task for the patient
      await taskUtility.saveTask(
        userId: widget.patientId,
        taskId: taskId,
        collectionName: patientRole,
        subCollectionName: 'tasks',
        taskTitle: title,
        taskDescription: description,
        startDate: startDate,
        endDate: endDate,
      );

      // Save the task for the caregiver
      await taskUtility.saveTask(
        userId: caregiverId,
        taskId: taskId,
        collectionName: caregiverRole,
        subCollectionName: 'tasks',
        taskTitle: title,
        taskDescription: description,
        startDate: startDate,
        endDate: endDate,
      );

      _fetchPatientTasks();
      _resetDateControllers();
      await _logService.addLog(
        userId: caregiverId,
        action: "Added Task $title to patient $patientName",
      );

      showToast("Task added successfully");
    } catch (e) {
      debugPrint("Error adding task: $e");

      showToast("Failed to add task: $e", backgroundColor: AppColors.red);
    }
  }

  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _selectDateTime(
    BuildContext context,
    bool isStartDate,
    Function(String) setError, // Pass a callback to set error messages
  ) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate =
        isStartDate ? (taskStartDate ?? now) : (taskEndDate ?? now);

    // Date Picker
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(Duration(days: 30)),
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

    if (pickedDate != null) {
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
        // Combine date and time
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Validation for start date
        if (isStartDate) {
          if (selectedDateTime.isBefore(now.add(Duration(minutes: 15)))) {
            setError(
              "Start date and time must be at least 15 minutes from now.",
            );
            return;
          }
          if (mounted) {
            setState(() {
              taskStartDate = selectedDateTime;
              _startDateController.text =
                  '${DateFormat('MMMM dd, yyyy').format(taskStartDate!)} at ${DateFormat('h:mm a').format(taskStartDate!)}';
              setError(""); // Clear error
            });
          }
          debugPrint("Start Date Updated: $taskStartDate");
        } else {
          // Validation for end date
          if (taskStartDate == null) {
            setError("Please select a start date first.");
            return;
          }
          if (selectedDateTime.isBefore(
            taskStartDate!.add(Duration(minutes: 30)),
          )) {
            setError(
              "End date and time must be at least 30 minutes after the start date.",
            );
            return;
          }
          if (mounted) {
            setState(() {
              taskEndDate = selectedDateTime;
              _endDateController.text =
                  '${DateFormat('MMMM dd, yyyy').format(taskEndDate!)} at ${DateFormat('h:mm a').format(taskEndDate!)}';
              setError(""); // Clear error
            });
          }
          debugPrint("End Date Updated: $taskEndDate");
        }
      }
    }
  }

  void _showAddTaskDialog() {
    _titleController.clear();
    _descriptionController.clear();
    _startDateController.clear();
    _endDateController.clear();
    String errorMessage = ""; // Track error messages
    final FocusNode titleFocusNode = FocusNode();
    final FocusNode descriptionFocusNode = FocusNode();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              child: SingleChildScrollView(
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
                      Text("Add Task", style: Textstyle.subheader),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titleController,
                        focusNode: titleFocusNode,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(50),
                          FilteringTextInputFormatter.deny(RegExp(r'[\n]')),
                        ],
                        decoration: InputDecorationStyles.build(
                          'Title',
                          titleFocusNode,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: _descriptionController,
                        focusNode: descriptionFocusNode,
                        maxLines: 3,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(200),
                        ],
                        decoration: InputDecorationStyles.build(
                          'Task Description',
                          descriptionFocusNode,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Start Date Field
                      TextFormField(
                        controller: _startDateController,
                        focusNode: _focusNodes[2],
                        readOnly: true,
                        decoration: InputDecorationStyles.build(
                          "Start Date/Time",
                          _focusNodes[2],
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.calendar_today,
                              color: AppColors.black,
                            ),
                            onPressed:
                                () => _selectDateTime(
                                  context,
                                  true,
                                  (error) =>
                                      setModalState(() => errorMessage = error),
                                ),
                          ),
                        ),
                        onTap:
                            () => _selectDateTime(
                              context,
                              true,
                              (error) =>
                                  setModalState(() => errorMessage = error),
                            ),
                      ),
                      const SizedBox(height: 20),

                      // End Date Field
                      TextFormField(
                        controller: _endDateController,
                        focusNode: _focusNodes[3],
                        readOnly: true,
                        decoration: InputDecorationStyles.build(
                          "End Date/Time",
                          _focusNodes[3],
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.calendar_today,
                              color: AppColors.black,
                            ),
                            onPressed:
                                () => _selectDateTime(
                                  context,
                                  false,
                                  (error) =>
                                      setModalState(() => errorMessage = error),
                                ),
                          ),
                        ),
                        onTap:
                            () => _selectDateTime(
                              context,
                              false,
                              (error) =>
                                  setModalState(() => errorMessage = error),
                            ),
                      ),

                      // Error Message Display
                      if (errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          errorMessage,
                          style: Textstyle.bodySmall.copyWith(
                            color: AppColors.red,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                final titleText = _titleController.text.trim();
                                final descriptionText =
                                    _descriptionController.text.trim();
                                final startText = _startDateController.text;
                                final endText = _endDateController.text;

                                if (titleText.isEmpty &&
                                    descriptionText.isEmpty &&
                                    startText.isEmpty &&
                                    endText.isEmpty) {
                                  Navigator.of(context).pop();
                                } else {
                                  final shouldDiscard =
                                      await showDiscardConfirmationDialog(
                                        context,
                                      );
                                  if (shouldDiscard) {
                                    Navigator.of(context).pop();
                                  }
                                }
                              },
                              style: Buttonstyle.buttonRed,
                              child: Text(
                                "Cancel",
                                style: Textstyle.smallButton,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                String taskTitle = _titleController.text.trim();
                                String taskDescription =
                                    _descriptionController.text.trim();

                                if (taskTitle.isEmpty) {
                                  showToast(
                                    "Please provide a title for the task.",
                                    backgroundColor: AppColors.red,
                                  );
                                } else if (taskDescription.isEmpty) {
                                  showToast(
                                    "Please provide the task description.",
                                    backgroundColor: AppColors.red,
                                  );
                                } else if (taskStartDate == null) {
                                  showToast(
                                    "Please specify the starting date/time of the task.",
                                    backgroundColor: AppColors.red,
                                  );
                                } else if (taskEndDate == null) {
                                  showToast(
                                    "Please specify the ending date/time of the task.",
                                    backgroundColor: AppColors.red,
                                  );
                                } else if (taskStartDate!.isAfter(
                                  taskEndDate!,
                                )) {
                                  showToast(
                                    "The starting date/time must be set before ending date/time.",
                                    backgroundColor: AppColors.red,
                                  );
                                } else {
                                  _addTask(
                                    taskTitle,
                                    taskDescription,
                                    taskStartDate!,
                                    taskEndDate!,
                                  );
                                  Navigator.pop(context);
                                  _fetchPatientTasks();
                                  _resetDateControllers();
                                }
                              },
                              style: Buttonstyle.buttonNeon,
                              child: Text(
                                "Add Task",
                                style: Textstyle.smallButton,
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
  }

  Future<bool> showDiscardConfirmationDialog(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text('Discard Changes?', style: Textstyle.subheader),
          content: Text(
            'You have unsaved changes. Do you want to discard them?',
            style: Textstyle.body,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: Buttonstyle.buttonNeon,
                    child: Text('Cancel', style: Textstyle.smallButton),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: Buttonstyle.buttonRed,
                    child: Text('Discard', style: Textstyle.smallButton),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Widget _buildNoTaskState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, color: AppColors.black, size: 70),
          SizedBox(height: 10.0),
          Text("No task yet", style: Textstyle.body),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text("View Tasks", style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        centerTitle: true,
        scrolledUnderElevation: 0.0,
      ),
      body:
          isLoading
              ? Center(child: Loader.loaderPurple)
              : tasks.isEmpty
              ? _buildNoTaskState()
              : _buildTaskList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: AppColors.neon,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildTaskList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
    final bool isCompleted = task['isCompleted'];
    final formattedStartDate = DateFormat(
      'MMMM dd, yyyy h:mm a',
    ).format(startDate);
    final formattedEndDate = DateFormat('MMMM dd, yyyy h:mm a').format(endDate);

    return GestureDetector(
      onTap: () => _showTaskDetailsDialog(task),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.gray,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Textstyle.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : AppColors.red,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      isCompleted ? 'Complete' : 'Incomplete',
                      style: Textstyle.bodySmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Description",
                    style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(description, style: Textstyle.body),
                  const SizedBox(height: 5),
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
                Text(title, style: Textstyle.subheader),
                const SizedBox(height: 10.0),
                Text("Do you want to delete this task?", style: Textstyle.body),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pop(); // Close dialog without doing anything
                        },
                        style: Buttonstyle.buttonNeon,
                        child: Text('Cancel', style: Textstyle.smallButton),
                      ),
                    ),
                    const SizedBox(width: 10.0),
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
                        style: Buttonstyle.buttonRed,
                        child: Text(
                          'Delete Task',
                          style: Textstyle.smallButton,
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
