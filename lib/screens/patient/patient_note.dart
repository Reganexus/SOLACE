// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/inputdecoration.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:table_calendar/table_calendar.dart';

class PatientNote extends StatefulWidget {
  const PatientNote({super.key, required this.patientId});
  final String patientId;

  @override
  PatientNoteState createState() => PatientNoteState();
}

class PatientNoteState extends State<PatientNote> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService databaseService = DatabaseService();
  final LogService _logService = LogService();
  List<Map<String, dynamic>> notes = [];
  DateTime selectedDay = DateTime.now();
  DateTime? userCreatedDate;
  bool isLoading = true;
  late String patientName = '';

  @override
  void initState() {
    super.initState();
    fetchNotesForDay(selectedDay);
    fetchUserCreationDate();
    _loadPatientName();
    debugPrint("Patient Name: $patientName");
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

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  Future<void> fetchUserCreationDate() async {
    try {
      // Use the user's role to fetch data from the appropriate collection
      final snapshot =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(widget.patientId)
              .get();

      if (snapshot.exists && snapshot.data() != null) {
        final userData = snapshot.data()!;
        final dateCreatedTimestamp = userData['dateCreated'] as Timestamp?;

        if (dateCreatedTimestamp != null) {
          setState(() {
            userCreatedDate = dateCreatedTimestamp.toDate();
          });
        }
      }
    } catch (e) {
      print("Error fetching user creation date: $e");
    }
  }

  Future<void> fetchNotesForDay(DateTime day) async {
    setState(() {
      isLoading = true;
      notes = [];
    });

    try {
      final notesSnapshot =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(widget.patientId)
              .collection('notes')
              .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(day))
              .get();

      if (notesSnapshot.docs.isNotEmpty) {
        setState(() {
          notes =
              notesSnapshot.docs.map((doc) {
                final data = doc.data();
                return {
                  'noteId': doc.id,
                  'timestamp': (data['timestamp'] as Timestamp).toDate(),
                  'note': data['note'],
                  'title': data['title'],
                };
              }).toList();
        });
      }
    } catch (e) {
      print('Error fetching notes: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> addNoteForToday(String title, String noteText) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        showToast("User is not Authenticated");
        return;
      }

      if (user.uid == null) {
        showToast("User is id Null");
        return;
      }

      final String userId = user.uid;
      final DateTime selectedDate = selectedDay;
      final String noteId = '${selectedDate.millisecondsSinceEpoch}';

      final newNote = {
        'timestamp': Timestamp.fromDate(selectedDate),
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'title': title.isNotEmpty ? title : 'Untitled',
        'note': noteText.isNotEmpty ? noteText : 'No content provided',
      };

      final noteRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(widget.patientId)
          .collection('notes')
          .doc(noteId);

      await noteRef.set(newNote);

      await _logService.addLog(
        userId: userId,
        action: "Added note $title to patient $patientName",
      );

      fetchNotesForDay(selectedDay);
      showToast('Note added successfully!');
    } catch (e) {
      showToast('Error adding note: $e');
    }
  }

  Future<void> _deleteNote(Map<String, dynamic> note) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        showToast("User is not Authenticated");
        return;
      }

      if (user.uid == null) {
        showToast("User is id Null");
        return;
      }

      final String userId = user.uid;
      final noteRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(widget.patientId)
          .collection('notes')
          .doc(note['noteId']);

      await noteRef.delete();

      await _logService.addLog(
        userId: userId,
        action: "Deleted note ${note['title']} from patient $patientName",
      );

      fetchNotesForDay(selectedDay);
      showToast('Note deleted successfully!');
    } catch (e) {
      showToast('Error deleting note: $e');
    }
  }

  void _showNoteDetailsDialog(Map<String, dynamic> note, String formattedTime) {
    showDialog(
      context: context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text('Note Details', style: Textstyle.subheader),
              content: SizedBox(
                width:
                    constraints.maxWidth * 0.9, // Applied 90% width constraint
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Time Added",
                        style: Textstyle.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(formattedTime, style: Textstyle.body),
                      const SizedBox(height: 20),
                      Text(
                        "Notes",
                        style: Textstyle.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(note['note'], style: Textstyle.body),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: Buttonstyle.buttonNeon,
                        child: Text('Close', style: Textstyle.smallButton),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await _deleteNote(note);
                          Navigator.of(context).pop();
                        },
                        style: Buttonstyle.buttonRed,
                        child: Text('Delete', style: Textstyle.smallButton),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddNoteDialog() {
    final TextEditingController noteController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    final FocusNode titleFocusNode = FocusNode();
    final FocusNode noteFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text('Add Note for Today', style: Textstyle.subheader),
              content: SizedBox(
                width:
                    constraints.maxWidth * 0.9, // Applied 90% width constraint
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        focusNode: titleFocusNode,
                        decoration: InputDecorationStyles.build(
                          'Title',
                          titleFocusNode,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      TextField(
                        controller: noteController,
                        focusNode: noteFocusNode,
                        maxLines: 1,
                        decoration: InputDecorationStyles.build(
                          'Note',
                          noteFocusNode,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: Buttonstyle.buttonRed,
                        child: Text('Cancel', style: Textstyle.smallButton),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final noteText = noteController.text.trim();
                          final titleText = titleController.text.trim();
                          if (noteText.isNotEmpty && titleText.isNotEmpty) {
                            await addNoteForToday(titleText, noteText);
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Both fields are required!'),
                              ),
                            );
                          }
                        },
                        style: Buttonstyle.buttonNeon,
                        child: Text('Save', style: Textstyle.smallButton),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
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

  Widget _buildNoNotes() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        "No available notes",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontFamily: 'Inter',
          fontWeight: FontWeight.normal,
          color: AppColors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        backgroundColor: AppColors.neon,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text('Notes', style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 400,
              color: AppColors.black.withValues(alpha: 0.8),
              child: TableCalendar(
                focusedDay: selectedDay,
                firstDay:
                    userCreatedDate ??
                    DateTime.now().subtract(
                      const Duration(days: 30),
                    ), // Default to 30 days ago
                lastDay: DateTime.now(),
                selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                enabledDayPredicate: (day) {
                  if (userCreatedDate == null) {
                    return true;
                  }
                  return day.isAfter(
                        userCreatedDate!.subtract(const Duration(days: 1)),
                      ) &&
                      day.isBefore(DateTime.now().add(const Duration(days: 1)));
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    this.selectedDay = selectedDay;
                  });
                  fetchNotesForDay(selectedDay);
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
                  defaultTextStyle: Textstyle.body.copyWith(
                    color: AppColors.white,
                  ),
                  disabledTextStyle: Textstyle.body.copyWith(
                    color: AppColors.gray,
                  ),
                  weekendTextStyle: Textstyle.body.copyWith(
                    color: AppColors.white,
                  ),
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
                  _buildLegendItem(AppColors.neon, "Selected Day"),
                  _buildLegendItem(AppColors.purple, "Today"),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const SizedBox(height: 20.0),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Notes for ${DateFormat('MMM d, y (EEEE)').format(selectedDay)}',
                      style: Textstyle.subheader,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  isLoading
                      ? _buildNoNotes()
                      : notes.isNotEmpty
                      ? ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          final timestamp = note['timestamp'];
                          final formattedTime = DateFormat(
                            'h:mm a',
                          ).format(timestamp); // Time only format

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10.0),
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: AppColors.gray,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note['title'] ?? 'No Title',
                                        style: Textstyle.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5.0),
                                      Text(
                                        note['note'] ?? 'No content available',
                                        style: Textstyle.body,
                                      ), // Default value for null
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _showNoteDetailsDialog(note, formattedTime);
                                  },
                                  child: Icon(Icons.more_vert, size: 24),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                      : _buildNoNotes(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
