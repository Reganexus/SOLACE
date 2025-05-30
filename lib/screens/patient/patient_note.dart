// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:solace/controllers/notification_service.dart';
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
  final NotificationService notificationService = NotificationService();
  List<Map<String, dynamic>> notes = [];
  DateTime selectedDay = DateTime.now();
  DateTime? userCreatedDate;
  bool isLoading = true;
  late String patientName = '';
  Set<DateTime> noteDates = {};

  @override
  void initState() {
    super.initState();
    fetchNotesForDay(selectedDay);
    _fetchAllNoteDates().then((dates) {
      setState(() {
        noteDates = dates;
      });

      print("Note Dates: $noteDates");
    });

    fetchUserCreationDate();
    _loadPatientName();
  }

  Future<void> _loadPatientName() async {
    final name = await databaseService.fetchUserName(widget.patientId);
    if (mounted) {
      setState(() {
        patientName = name ?? 'Unknown';
      });
    }
  }

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
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
      //     debugPrint("Error fetching user creation date: $e");
    }
  }

  Future<Set<DateTime>> _fetchAllNoteDates() async {
    Set<DateTime> noteDates = {};
    try {
      final notesSnapshot =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(widget.patientId)
              .collection('notes')
              .get();

      for (var doc in notesSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('date')) {
          try {
            final parsedDate = DateFormat('yyyy-MM-dd').parse(data['date']);
            noteDates.add(parsedDate);
          } catch (e) {
            // Handle potential parsing errors
            // debugPrint('Error parsing date: ${data['date']}, error: $e');
          }
        }
      }
    } catch (e) {
      // Handle error fetching all notes
      // debugPrint('Error fetching all note dates: $e');
    }
    return noteDates;
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
      //     debugPrint('Error fetching notes: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> addNoteForToday(String title, String noteText) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        showToast("User is not Authenticated", backgroundColor: AppColors.red);
        return;
      }

      if (user.uid == null) {
        showToast("User is id Null", backgroundColor: AppColors.red);
        return;
      }

      final String userId = widget.patientId;
      final String? role = await databaseService.fetchAndCacheUserRole(
        user.uid,
      );
      final String userRole =
          '${role!.substring(0, 1).toUpperCase()}${role.substring(1)}';
      final DateTime selectedDate = selectedDay;
      final String noteId =
          '${selectedDate.millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch}';
      final String? name = await databaseService.fetchUserName(user.uid);

      final newNote = {
        'timestamp': Timestamp.fromDate(selectedDate),
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'title': title.isNotEmpty ? title : 'Untitled',
        'note': noteText.isNotEmpty ? noteText : '',
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

      await notificationService.sendInAppNotificationToTaggedUsers(
        patientId: widget.patientId,
        currentUserId: user.uid,
        notificationMessage:
            "$userRole $name added a note to patient $patientName.",
        type: "note",
      );

      await notificationService.sendNotificationToTaggedUsers(
        widget.patientId,
        "New Patient Note",
        "$userRole $name added a note to patient $patientName.",
      );

      fetchNotesForDay(selectedDay);
      _fetchAllNoteDates().then((dates) {
        setState(() {
          noteDates = dates;
        });

        print("Note Dates: $noteDates");
      });
      showToast('Note added successfully!');
    } catch (e) {
      showToast('Error adding note: $e', backgroundColor: AppColors.red);
    }
  }

  Future<void> _deleteNote(Map<String, dynamic> note) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        showToast("User is not Authenticated", backgroundColor: AppColors.red);
        return;
      }

      if (user.uid == null) {
        showToast("User is id Null", backgroundColor: AppColors.red);
        return;
      }

      final String userId = user.uid;
      final String? role = await databaseService.fetchAndCacheUserRole(
        user.uid,
      );
      final String userRole =
          '${role!.substring(0, 1).toUpperCase()}${role.substring(1)}';
      final String? name = await databaseService.fetchUserName(user.uid);

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

      await notificationService.sendInAppNotificationToTaggedUsers(
        patientId: widget.patientId,
        currentUserId: user.uid,
        notificationMessage:
            "$userRole $name deleted a note from patient $patientName.",
        type: "note",
      );

      await notificationService.sendNotificationToTaggedUsers(
        widget.patientId,
        "Deleted Patient Note",
        "$userRole $name deleted a note from patient $patientName.",
      );

      fetchNotesForDay(selectedDay);
      _fetchAllNoteDates().then((dates) {
        setState(() {
          noteDates = dates;
        });

        print("Note Dates: $noteDates");
      });
      showToast('Note deleted successfully!');
    } catch (e) {
      showToast('Error deleting note: $e', backgroundColor: AppColors.red);
    }
  }

  Future<void> _updateNote(
    String noteId,
    String updatedTitle,
    String updatedNote,
  ) async {
    try {
      final noteRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(widget.patientId)
          .collection('notes')
          .doc(noteId);

      await noteRef.update({'title': updatedTitle, 'note': updatedNote});

      final user = _auth.currentUser;

      if (user == null) {
        showToast("User is not Authenticated", backgroundColor: AppColors.red);
        return;
      }

      if (user.uid == null) {
        showToast("User is id Null", backgroundColor: AppColors.red);
        return;
      }

      final String? role = await databaseService.fetchAndCacheUserRole(
        user.uid,
      );
      final String userRole =
          '${role!.substring(0, 1).toUpperCase()}${role.substring(1)}';
      final String? name = await databaseService.fetchUserName(user.uid);

      if (user == null) {
        showToast("User is not Authenticated", backgroundColor: AppColors.red);
        return;
      }

      if (user.uid == null) {
        showToast("User is id Null", backgroundColor: AppColors.red);
        return;
      }

      final String userId = user.uid;

      await _logService.addLog(
        userId: userId,
        action: "Updated note $updatedTitle for patient $patientName",
      );

      await notificationService.sendInAppNotificationToTaggedUsers(
        patientId: widget.patientId,
        currentUserId: user.uid,
        notificationMessage:
            "$userRole $name updated a note from patient $patientName.",
        type: "note",
      );

      await notificationService.sendNotificationToTaggedUsers(
        widget.patientId,
        "Updated Patient Note",
        "$userRole $name updated a note from patient $patientName.",
      );

      fetchNotesForDay(selectedDay);
      _fetchAllNoteDates().then((dates) {
        setState(() {
          noteDates = dates;
        });

        print("Note Dates: $noteDates");
      });
      showToast('Note updated successfully!');
    } catch (e) {
      showToast('Error updating note: $e', backgroundColor: AppColors.red);
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
                width: constraints.maxWidth * 0.9,
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
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showEditNoteDialog(note);
                        },
                        style: Buttonstyle.buttonBlue,
                        child: Text('Edit', style: Textstyle.smallButton),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: TextButton(
                        onPressed:
                            () => showDeleteConfirmationDialog(context, note),
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
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return AlertDialog(
                  backgroundColor: AppColors.white,
                  content: SizedBox(
                    width: constraints.maxWidth * 0.9,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Note for Today',
                            style: Textstyle.subheader,
                          ),
                          Text(
                            "Fields marked with * are required.",
                            style: Textstyle.body,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            enabled: isSaving ? false : true,
                            controller: titleController,
                            focusNode: titleFocusNode,
                            maxLength: 50,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(50),
                              FilteringTextInputFormatter.deny(RegExp(r'[\n]')),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                showToast(
                                  'Title is required',
                                  backgroundColor: AppColors.red,
                                );
                              }
                              return null;
                            },
                            decoration: InputDecorationStyles.build(
                              'Title *',
                              titleFocusNode,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          TextFormField(
                            enabled: isSaving ? false : true,
                            controller: noteController,
                            focusNode: noteFocusNode,
                            maxLength: 1000,
                            maxLines: 6,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(1000),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                showToast(
                                  'Note content is required',
                                  backgroundColor: AppColors.red,
                                );
                              }
                              return null;
                            },
                            decoration: InputDecorationStyles.build(
                              'Note *',
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
                            onPressed:
                                isSaving
                                    ? null
                                    : () async {
                                      final titleText =
                                          titleController.text.trim();
                                      final noteText =
                                          noteController.text.trim();

                                      if (titleText.isEmpty &&
                                          noteText.isEmpty) {
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
                            style:
                                isSaving
                                    ? Buttonstyle.buttonGray
                                    : Buttonstyle.buttonRed,
                            child: Text('Cancel', style: Textstyle.smallButton),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            onPressed:
                                isSaving
                                    ? null
                                    : () async {
                                      final noteText =
                                          noteController.text.trim();
                                      final titleText =
                                          titleController.text.trim();
                                      FocusScope.of(context).unfocus();

                                      if (titleText.isEmpty) {
                                        showToast(
                                          'Please provide a title for your note.',
                                          backgroundColor: AppColors.red,
                                        );
                                      } else if (noteText.isEmpty) {
                                        showToast(
                                          'Please provide the content for your note.',
                                          backgroundColor: AppColors.red,
                                        );
                                      } else {
                                        final shouldSave =
                                            await showConfirmationDialog(
                                              context,
                                              'add',
                                            );
                                        if (shouldSave) {
                                          setState(() {
                                            isSaving = true;
                                          });
                                          await addNoteForToday(
                                            titleText,
                                            noteText,
                                          );
                                          setState(() {
                                            isSaving = false;
                                          });
                                          if (mounted) {
                                            Navigator.of(context).pop();
                                          }
                                        }
                                      }
                                    },
                            style: Buttonstyle.buttonNeon,
                            child:
                                isSaving
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.white,
                                            ),
                                      ),
                                    )
                                    : Text(
                                      'Save',
                                      style: Textstyle.smallButton,
                                    ),
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
      },
    );
  }

  void _showEditNoteDialog(Map<String, dynamic> note) {
    final TextEditingController titleController = TextEditingController(
      text: note['title'],
    );
    final TextEditingController noteController = TextEditingController(
      text: note['note'],
    );
    final FocusNode titleFocusNode = FocusNode();
    final FocusNode noteFocusNode = FocusNode();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return AlertDialog(
                  backgroundColor: AppColors.white,
                  content: SizedBox(
                    width: constraints.maxWidth * 0.9,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Edit Note', style: Textstyle.subheader),
                          const SizedBox(height: 20),
                          TextFormField(
                            enabled: isSaving ? false : true,
                            controller: titleController,
                            focusNode: titleFocusNode,
                            maxLength: 50,
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
                            enabled: isSaving ? false : true,
                            controller: noteController,
                            focusNode: noteFocusNode,
                            maxLength: 1000,
                            maxLines: 6,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(1000),
                            ],
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
                            onPressed:
                                isSaving
                                    ? null
                                    : () async {
                                      Navigator.of(context).pop();
                                    },
                            style:
                                isSaving
                                    ? Buttonstyle.buttonGray
                                    : Buttonstyle.buttonRed,
                            child: Text('Cancel', style: Textstyle.smallButton),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            onPressed:
                                isSaving
                                    ? null
                                    : () async {
                                      final noteText =
                                          noteController.text.trim();
                                      final titleText =
                                          titleController.text.trim();

                                      if (titleText.isEmpty) {
                                        showToast(
                                          'Please provide a title for your note.',
                                          backgroundColor: AppColors.red,
                                        );
                                      } else if (noteText.isEmpty) {
                                        showToast(
                                          'Please provide the content for your note.',
                                          backgroundColor: AppColors.red,
                                        );
                                      } else {
                                        final shouldSave =
                                            await showConfirmationDialog(
                                              context,
                                              'edit',
                                            );
                                        if (shouldSave) {
                                          setState(() {
                                            isSaving = true;
                                          });
                                          await _updateNote(
                                            note['noteId'],
                                            titleText,
                                            noteText,
                                          );
                                          setState(() {
                                            isSaving = false;
                                          });
                                          if (mounted) {
                                            Navigator.of(context).pop();
                                          }
                                        }
                                      }
                                    },
                            style: Buttonstyle.buttonNeon,
                            child:
                                isSaving
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.white,
                                            ),
                                      ),
                                    )
                                    : Text(
                                      'Save',
                                      style: Textstyle.smallButton,
                                    ),
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
      },
    );
  }

  Future<bool> showConfirmationDialog(BuildContext context, String flag) async {
    String message = '';
    String buttonText = '';
    if (flag == 'edit') {
      message = 'Are you sure you want to edit this note?';
      buttonText = 'Delete';
    } else if (flag == 'add') {
      message = 'Are you sure you want to add this note?';
      buttonText = 'Add';
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text('Confirmation', style: Textstyle.subheader),
          content: Text(message, style: Textstyle.body),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: Buttonstyle.buttonRed,
                    child: Text('Cancel', style: Textstyle.smallButton),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: Buttonstyle.buttonNeon,
                    child: Text(buttonText, style: Textstyle.smallButton),
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

  Future<void> showDeleteConfirmationDialog(
    BuildContext context,
    Map<String, dynamic> note,
  ) async {
    bool isDeleting = false;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text('Confirmation', style: Textstyle.subheader),
              content: Text(
                'Are you sure you want to delete this note?',
                style: Textstyle.body,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed:
                            isDeleting
                                ? null
                                : () => Navigator.of(dialogContext).pop(false),
                        style:
                            isDeleting
                                ? Buttonstyle.buttonGray
                                : Buttonstyle.buttonNeon,
                        child: Text('Cancel', style: Textstyle.smallButton),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed:
                            isDeleting
                                ? null
                                : () async {
                                  setState(() {
                                    isDeleting = true;
                                  });
                                  await _deleteNote(note);
                                  setState(() {
                                    isDeleting = false;
                                  });
                                  if (mounted) {
                                    Navigator.of(dialogContext).pop(true);
                                  }
                                  if (mounted) Navigator.of(context).pop();
                                },
                        style: Buttonstyle.buttonRed,
                        child:
                            isDeleting
                                ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                )
                                : Text('Confirm', style: Textstyle.smallButton),
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

  Future<bool> showDiscardConfirmationDialog(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        backgroundColor: AppColors.neon,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
      ),
      appBar: AppBar(
        title: Text('Notes', style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        centerTitle: true,
        scrolledUnderElevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 350,
              color: AppColors.black.withValues(alpha: 0.8),
              child: TableCalendar(
                focusedDay: selectedDay,
                firstDay:
                    userCreatedDate ??
                    DateTime.now().subtract(const Duration(days: 30)),
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
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.white,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.white,
                  ),
                  titleTextStyle: Textstyle.subheader.copyWith(
                    color: AppColors.white,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: Textstyle.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  weekendStyle: Textstyle.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final hasNote = noteDates.any(
                      (noteDate) => isSameDay(noteDate, day),
                    );
                    if (hasNote) {
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(
                            alpha: 0.8,
                          ), // Using Colors.orange
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${day.day}',
                          style: Textstyle.body.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      );
                    } else {
                      return null; // Use the default cell rendering
                    }
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.neon.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: Textstyle.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: Textstyle.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    );
                  },
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
                  _buildLegendItem(Colors.orange, "Day with Notes"),
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
                  if (isLoading)
                    _buildNoNotes()
                  else if (notes.isEmpty)
                    _buildNoNotes()
                  else
                    Column(
                      children: [
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            final timestamp = note['timestamp'];
                            final formattedTime = DateFormat(
                              'h:mm a',
                            ).format(timestamp);
                            return GestureDetector(
                              onTap: () {
                                _showNoteDetailsDialog(note, formattedTime);
                              },
                              child: Container(
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
                                            note['note'] ?? '',
                                            style: Textstyle.body,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 70.0),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
