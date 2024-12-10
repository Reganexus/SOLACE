// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solace/themes/colors.dart';
import 'package:table_calendar/table_calendar.dart';

class CaregiverTracking extends StatefulWidget {
  const CaregiverTracking({super.key});

  @override
  CaregiverTrackingState createState() => CaregiverTrackingState();
}

class CaregiverTrackingState extends State<CaregiverTracking> {
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
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
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
    }
  }

  Future<void> fetchNotesForDay(DateTime day) async {
    setState(() {
      isLoading = true;
      notes = [];
    });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String caregiverId = user.uid;

      // Fetch the user document containing the notes array
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(caregiverId)
          .get();

      // Check if the document exists and contains notes
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
            notes = filteredNotes
                .map((note) => {
                      'noteId': note['noteId'], // Include the noteId field
                      'timestamp': (note['timestamp'] as Timestamp).toDate(),
                      'note': note['note'],
                      'title': note['title'],
                    })
                .toList();
          });
        } else {
          setState(() {
            notes = [];
          });
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showAddNoteDialog() {
    final TextEditingController noteController = TextEditingController();
    final TextEditingController titleController =
        TextEditingController(); // New title controller

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text(
            'Add Note for Today',
            style: const TextStyle(
              fontSize: 24,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title TextField
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10.0),
              // Note TextField
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
            TextButton(
              onPressed: () async {
                final noteText = noteController.text.trim();
                final titleText =
                    titleController.text.trim(); // Get the title text
                if (noteText.isNotEmpty && titleText.isNotEmpty) {
                  await addNoteForToday(
                      titleText, noteText); // Pass both title and note
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
          ],
        );
      },
    );
  }

  Future<void> addNoteForToday(String title, String noteText) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String caregiverId = user.uid;

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

        // Reference to the user document
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(caregiverId);

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
    } else {
      print("User is not authenticated.");
    }
  }

  void _showNoteDetailsDialog(Map<String, dynamic> note, String formattedTime) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            'Note Details - $formattedTime',
            style: const TextStyle(
              fontSize: 24,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Time: $formattedTime',
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 10.0),
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
            TextButton(
              onPressed: () async {
                await _deleteNote(note);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
          ],
        );
      },
    );
  }

  Future<void> _deleteNote(Map<String, dynamic> note) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String caregiverId = user.uid;

      try {
        // Reference to the user document
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(caregiverId);

        // Fetch the user document to get the current notes array
        final userDocSnapshot = await userRef.get();

        if (!userDocSnapshot.exists) {
          print('User document does not exist!');
          return;
        }

        // Get the current notes array
        var notes = List<Map<String, dynamic>>.from(
            userDocSnapshot.data()?['notes'] ?? []);

        // Find the index of the note by noteId
        final noteIndex =
            notes.indexWhere((n) => n['noteId'] == note['noteId']);

        if (noteIndex != -1) {
          // Remove the note from the list
          notes.removeAt(noteIndex);

          // Update the notes field in Firestore to remove the note
          await userRef.update({
            'notes': notes, // Update the notes array without the deleted note
          });

          // After deleting, fetch updated notes for the day
          fetchNotesForDay(selectedDay);

          print('Note deleted successfully!');
        } else {
          print('Note not found');
        }
      } catch (e) {
        print('Error deleting note: $e'); // Print any error
      }
    } else {
      print('User is not authenticated.');
    }
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border:
                      Border.all(color: AppColors.blackTransparent, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TableCalendar(
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
                    return day.isAfter(userCreatedDate!
                            .subtract(const Duration(days: 1))) &&
                        day.isBefore(
                            DateTime.now().add(const Duration(days: 1)));
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
                    outsideDaysVisible:
                        false, // Hide dates outside the current month
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronIcon: Icon(Icons.arrow_back),
                    rightChevronIcon: Icon(Icons.arrow_forward),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Notes for ${DateFormat('MMM d, y (EEEE)').format(selectedDay)}',
                  style: const TextStyle(
                    fontSize: 18,
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
                                padding: const EdgeInsets.all(15.0),
                                decoration: BoxDecoration(
                                  color: AppColors.gray,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Check if 'title' exists and provide a default value if it's null
                                    Text(
                                      note['title'] ??
                                          'No Title', // Default value for null
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5.0),
                                    // Check if 'note' exists and provide a default value if it's null
                                    Text(note['note'] ??
                                        'No content available'), // Default value for null
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
