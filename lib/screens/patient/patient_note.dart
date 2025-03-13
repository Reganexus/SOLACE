// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solace/themes/colors.dart';
import 'package:table_calendar/table_calendar.dart';

class PatientNote extends StatefulWidget {
  const PatientNote({super.key, required this.patientId});
  final String patientId;

  @override
  PatientNoteState createState() => PatientNoteState();
}

class PatientNoteState extends State<PatientNote> {
  List<Map<String, dynamic>> notes = [];
  DateTime selectedDay = DateTime.now();
  DateTime? userCreatedDate;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotesForDay(selectedDay);
    fetchUserCreationDate();
  }

  Future<void> fetchUserCreationDate() async {
    try {
      // Use the user's role to fetch data from the appropriate collection
      final snapshot = await FirebaseFirestore.instance
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
      final snapshot = await FirebaseFirestore.instance
          .collection('patient')
          .doc(widget.patientId)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        final userData = snapshot.data()!;

        // Ensure that 'notes' is a List and not null
        final notesArray = userData['notes'] as List<dynamic>?;

        if (notesArray != null) {
          // Filter notes that match the selected day
          final selectedDateString = DateFormat('yyyy-MM-dd').format(day);
          final filteredNotes = notesArray.where((note) {
            final timestamp = (note['timestamp'] as Timestamp).toDate();
            final formattedDate = DateFormat('yyyy-MM-dd').format(timestamp);
            return formattedDate == selectedDateString;
          }).toList();

          setState(() {
            notes = filteredNotes.map((note) {
              return {
                'noteId': note['noteId'],
                'timestamp': (note['timestamp'] as Timestamp).toDate(),
                'note': note['note'],
                'title': note['title'],
              };
            }).toList();
          });
        } else {
          setState(() {
            notes = [];
          });
        }
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
      // Use selectedDay as the reference date for the note
      final DateTime selectedDate = selectedDay;
      final String uniqueId = '${selectedDate.millisecondsSinceEpoch}';

      // Create the new note
      final newNote = {
        'noteId': uniqueId, // Add the unique ID
        'timestamp': Timestamp.fromDate(
            selectedDate), // Use selectedDate for the timestamp
        'date': DateFormat('yyyy-MM-dd')
            .format(selectedDate), // Format the selected date
        'title': title.isNotEmpty ? title : 'Untitled',
        'note': noteText.isNotEmpty ? noteText : 'No content provided',
      };

      // Reference to the user document using their role
      final userRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(widget.patientId);

      // Update the notes field of the user document
      await userRef.update({
        'notes': FieldValue.arrayUnion(
            [newNote]), // Add the new note to the 'notes' array
      });

      fetchNotesForDay(selectedDay);
      print('Note added successfully!');
    } catch (e) {
      print("Error adding note: $e"); // Print any error
    }
  }

  Future<void> _deleteNote(Map<String, dynamic> note) async {
    try {
      // Reference to the user document using their role
      final userRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(widget.patientId);

      // Fetch the user document to get the current notes array
      final userDocSnapshot = await userRef.get();

      if (!userDocSnapshot.exists) {
        print('User document does not exist!');
        return;
      }

      // Get the current notes array
      List<Map<String, dynamic>> notes = List<Map<String, dynamic>>.from(
          userDocSnapshot.data()?['notes'] ?? []);

      // Find the index of the note by noteId
      final noteIndex = notes.indexWhere((n) => n['noteId'] == note['noteId']);

      if (noteIndex != -1) {
        // Remove the note from the list
        notes.removeAt(noteIndex);

        // Update the notes field in Firestore to remove the note
        await userRef.update({'notes': notes});

        // After deleting, fetch updated notes for the day
        fetchNotesForDay(selectedDay);

        print('Note deleted successfully!');
      } else {
        print('Note not found');
      }
    } catch (e) {
      print('Error deleting note: $e'); // Print any error
    }
  }

  void _showNoteDetailsDialog(Map<String, dynamic> note, String formattedTime) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            'Note Details',
            style: const TextStyle(
              fontSize: 24,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 280.0, // Minimum width
              maxWidth: 400.0, // Maximum width
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Time Added",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.normal,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Notes",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    note['note'], // Display the note content as text
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.normal,
                      color: AppColors.black,
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
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
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
                SizedBox(
                  width: 10.0,
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      await _deleteNote(note);
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      backgroundColor: AppColors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
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
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text(
            'Add Note for Today',
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 280.0, // Minimum width
              maxWidth: 400.0, // Maximum width
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    focusNode: titleFocusNode,
                    decoration: _buildInputDecoration('Title', titleFocusNode),
                  ),
                  const SizedBox(height: 10.0),
                  TextField(
                    controller: noteController,
                    focusNode: noteFocusNode,
                    maxLines: 1,
                    decoration: _buildInputDecoration('Note', noteFocusNode),
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
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      backgroundColor: AppColors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
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
                              content: Text('Both fields are required!')),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      backgroundColor: AppColors.neon,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Save',
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
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(String label, FocusNode focusNode) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.gray,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.neon, width: 2)),
      labelStyle: TextStyle(
        fontSize: 16,
        fontFamily: 'Inter',
        fontWeight: FontWeight.normal,
        color: focusNode.hasFocus ? AppColors.neon : AppColors.black,
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
        title: const Text(
          'Notes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            children: [
              TableCalendar(
                focusedDay: selectedDay,
                firstDay: userCreatedDate ??
                    DateTime.now().subtract(
                        const Duration(days: 30)), // Default to 30 days ago
                lastDay: DateTime.now(),
                selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                enabledDayPredicate: (day) {
                  if (userCreatedDate == null) {
                    return true; // Temporarily enable all dates for testing
                  }
                  return day.isAfter(
                          userCreatedDate!.subtract(const Duration(days: 1))) &&
                      day.isBefore(DateTime.now().add(const Duration(days: 1)));
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    this.selectedDay = selectedDay;
                  });
                  fetchNotesForDay(selectedDay);
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.neon,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.purple,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: Icon(Icons.chevron_left_rounded),
                  rightChevronIcon: Icon(Icons.chevron_right_rounded),
                ),
              ),
              const SizedBox(height: 20.0),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Notes for ${DateFormat('MMM d, y (EEEE)').format(selectedDay)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 20.0),
              isLoading
                  ? Container(
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
                    )
                  : notes.isNotEmpty
                      ? ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            final timestamp = note['timestamp'];
                            final formattedTime = DateFormat('h:mm a')
                                .format(timestamp); // Time only format

                            return GestureDetector(
                              onTap: () =>
                                  _showNoteDetailsDialog(note, formattedTime),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10.0),
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
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
                                            note['title'] ??
                                                'No Title', // Default value for null
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 5.0),
                                          // Check if 'note' exists and provide a default value if it's null
                                          Text(
                                            note['note'] ??
                                                'No content available',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.normal,
                                              color: AppColors.black,
                                            ),
                                          ), // Default value for null
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.more_vert,
                                      size: 30,
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
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
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
