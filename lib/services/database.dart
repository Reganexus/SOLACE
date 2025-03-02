// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps, unreachable_switch_default

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solace/models/my_user.dart';

class DatabaseService {
  final String? uid;

  DatabaseService({this.uid});

  // Method to dynamically get the collection reference based on user role
  String _getCollectionForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.caregiver:
        return 'caregiver';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.patient:
        return 'patient';
      case UserRole.unregistered:
        return 'unregistered';
      default:
        throw Exception('Unhandled UserRole: $role');
    }
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      // Determine the current role's collection
      final currentRole = await _getUserRoleById(userId);

      if (currentRole == null) {
        throw Exception('User role not found for ID: $userId');
      }

      final currentCollection = _getCollectionForRole(currentRole);
      final newCollection = _getCollectionForRole(newRole);

      // Move the user document to the new collection if the role is changing
      if (currentCollection != newCollection) {
        // Get the user's current document
        final currentDoc = await FirebaseFirestore.instance
            .collection(currentCollection)
            .doc(userId)
            .get();

        if (currentDoc.exists) {
          final userData = currentDoc.data();

          // Add the document to the new collection
          await FirebaseFirestore.instance
              .collection(newCollection)
              .doc(userId)
              .set({
            ...userData!,
            'userRole': newRole.toString().split('.').last, // Update the role
          });

          // Delete the document from the old collection
          await FirebaseFirestore.instance
              .collection(currentCollection)
              .doc(userId)
              .delete();
        }
      } else {
        // Update the role within the same collection if no move is needed
        await FirebaseFirestore.instance
            .collection(currentCollection)
            .doc(userId)
            .update({
          'userRole': newRole.toString().split('.').last,
        });
      }

      print('Updated user role for $userId to ${newRole.toString()}');
    } catch (e) {
      print('Error updating user role: $e');
    }
  }

  Future<UserRole?> _getUserRoleById(String userId) async {
    // Check all user role collections for the user
    for (UserRole role in UserRole.values) {
      final collection = _getCollectionForRole(role);
      final userDoc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .get();
      if (userDoc.exists) {
        return role;
      }
    }
    return null; // Return null if the user is not found
  }

  Future<UserRole?> getUserRole(String userId) async {
    for (UserRole role in UserRole.values) {
      final collection = getCollectionForRole(role);
      final userDoc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .get();
      if (userDoc.exists) {
        return role;
      }
    }
    return null; // User role not found
  }

  String getCollectionForRole(UserRole userRole) {
    switch (userRole) {
      case UserRole.admin:
        return 'admin';
      case UserRole.caregiver:
        return 'caregiver';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.patient:
        return 'patient';
      case UserRole.unregistered:
        return 'unregistered';
      default:
        throw Exception('Unhandled UserRole: $userRole');
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData({
    required UserRole userRole,
    String? email,
    String? lastName,
    String? firstName,
    String? middleName,
    String? phoneNumber,
    DateTime? birthday,
    String? gender,
    String? address,
    String? profileImageUrl,
    bool? isVerified,
    bool? newUser,
    DateTime? dateCreated,
    String? religion,
    int? age,
    String? will,
    String? fixedWishes,
    String? organDonation,
  }) async {
    try {
      // Get the appropriate collection for the user role
      final collectionName = getCollectionForRole(userRole);

      // Get the Firestore reference
      final collectionRef =
          FirebaseFirestore.instance.collection(collectionName);

      // Prepare the updated data
      Map<String, dynamic> updatedData = {};

      if (email != null) updatedData['email'] = email;
      if (lastName != null) updatedData['lastName'] = lastName;
      if (firstName != null) updatedData['firstName'] = firstName;
      if (middleName != null) updatedData['middleName'] = middleName;
      if (phoneNumber != null) updatedData['phoneNumber'] = phoneNumber;

      if (birthday != null) {
        updatedData['birthday'] = Timestamp.fromDate(birthday);

        // Calculate the age if not provided
        if (age == null) {
          final now = DateTime.now();
          int years = now.year - birthday.year;
          if (now.month < birthday.month ||
              (now.month == birthday.month && now.day < birthday.day)) {
            years--;
          }
          updatedData['age'] = years;
        } else {
          updatedData['age'] = age; // Use the passed age if provided
        }
      }

      if (gender != null) updatedData['gender'] = gender;
      if (address != null) updatedData['address'] = address;
      if (profileImageUrl != null) {
        updatedData['profileImageUrl'] = profileImageUrl;
      }
      if (isVerified != null) updatedData['isVerified'] = isVerified;
      if (newUser != null) updatedData['newUser'] = newUser;
      if (dateCreated != null) {
        updatedData['dateCreated'] = Timestamp.fromDate(dateCreated);
      }
      if (religion != null) updatedData['religion'] = religion;
      if (will?.isNotEmpty ?? false) updatedData['will'] = will;
      if (fixedWishes?.isNotEmpty ?? false) {
        updatedData['fixedWishes'] = fixedWishes;
      }
      if (organDonation?.isNotEmpty ?? false) {
        updatedData['organDonation'] = organDonation;
      }

      // Perform the update only if there's data to update
      if (updatedData.isNotEmpty) {
        await collectionRef.doc(uid).set(updatedData, SetOptions(merge: true));
        print("User data updated successfully in collection: $collectionName");
      } else {
        print("No updates provided for user data.");
      }
    } catch (e) {
      print("Error updating user data: $e");
      throw Exception("Failed to update user data");
    }
  }

  Future<void> setUserVerificationStatus(
      String uid, bool isVerified, String userRole) async {
    try {
      final String collectionName = userRole; // Generate the collection name
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(uid)
          .update({
        'isVerified': isVerified,
      });
      debugPrint(
          'User verification status updated to $isVerified for user $uid in $collectionName');
    } catch (e) {
      debugPrint("Error updating user verification status: ${e.toString()}");
    }
  }

  // Fetch user data by email
  Future<UserData?> getUserDataByEmail(String email) async {
    try {
      // List of collections to search
      final List<String> collections = [
        'caregiver',
        'admin',
        'doctor',
        'patient',
        'unregistered'
      ];

      for (String collection in collections) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection(collection)
            .where('email', isEqualTo: email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // If found, return the user data from the appropriate collection
          return UserData.fromDocument(querySnapshot.docs.first);
        }
      }
      // If not found in any collection, return null
      return null;
    } catch (e) {
      print("Error fetching user data by email: ${e.toString()}");
      return null;
    }
  }

  // Fetch the users by role
  Stream<List<UserData>> getUsersByRole(String role) {
    return FirebaseFirestore.instance
        .collection(role)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserData.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> deleteUser(String userId) async {
    try {
      // 1. Identify and delete the Firestore user document from the appropriate collection
      UserData? userData = await getUserById(userId);

      var collectionName = getTargetUserRole(userId).toString();

      if (userData != null) {
        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(userId)
            .delete();
        print(
            "User document deleted from Firestore collection: $collectionName.");
      } else {
        print("User document not found in any collection.");
        return;
      }

      // 2. Delete records in the 'tracking' collection related to the user
      final batch = FirebaseFirestore.instance.batch();
      final trackingDocs = await FirebaseFirestore.instance
          .collection('tracking')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in trackingDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print("Related tracking records deleted.");
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  Future<String> getProfileImageUrl(String userId, UserRole userRole) async {
    try {
      // Use the role-based collection based on the user's role
      String collection = userRole.toString().split('.').last;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Return the profileImageUrl or an empty string if not found
        return userDoc['profileImageUrl'] ?? '';
      }

      // Return an empty string if the document doesn't exist
      return '';
    } catch (e) {
      print("Error fetching profile image URL: $e");
      return ''; // Return an empty string in case of an error
    }
  }

  // Method to add a vital record
  Future<void> addVitalRecord({
    required String caregiverId, // ID of the caregiver managing this patient
    required String patientId, // ID of the patient
    required String
        vital, // Type of vital (e.g., "heart rate", "blood pressure")
    required double inputRecord, // Vital record value
  }) async {
    try {
      print('Adding vital record for patient: $patientId');

      // Get a reference to the patient collection
      CollectionReference patientCollection =
          FirebaseFirestore.instance.collection('patients');

      // Check if the patient document exists
      DocumentSnapshot patientDoc =
          await patientCollection.doc(patientId).get();

      if (!patientDoc.exists) {
        print('Patient does not exist. Creating new patient record.');

        // Create a new patient document with the caregiver ID
        await patientCollection.doc(patientId).set({
          'caregiverId': caregiverId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Add the vital record under the patient's 'vitals' collection
      DocumentReference vitalDocRef =
          patientCollection.doc(patientId).collection('vitals').doc(vital);

      CollectionReference recordsRef = vitalDocRef.collection('records');

      await recordsRef.add({
        'timestamp': FieldValue.serverTimestamp(),
        'value': inputRecord,
      });

      print('Added vital record for patient: $patientId');
    } catch (e) {
      print('Error adding vital record for patient: $e');
    }
  }

  // Fetch user data from Firestore
  Future<UserData?> getUserData() async {
    try {
      print("Fetching data for UID: $uid");
      final collections = [
        'caregiver',
        'admin',
        'doctor',
        'patient',
        'unregistered'
      ];

      for (String collection in collections) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection(collection)
            .doc(uid)
            .get();

        if (snapshot.exists) {
          return UserData.fromDocument(snapshot);
        }
      }

      print("No document found for UID: $uid");
      return null; // Handle missing document case
    } catch (e) {
      print('Error fetching user data for UID $uid: $e');
      return null;
    }
  }

  Future<UserData?> getUserById(String userId) async {
    try {
      final collectionName = getTargetUserRole(userId).toString();

      // Attempt to fetch the user document
      final docSnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        return UserData.fromDocument(docSnapshot);
      }

      // Return null if the user is not found in any collection
      return null;
    } catch (e) {
      print("Error fetching user by ID: $e");
      return null;
    }
  }

  Stream<UserData?>? _userDataStream;

  Stream<UserData?>? get userData {
    if (_userDataStream == null) {
      print('Get userdata: $uid');
      final collections = [
        'caregiver',
        'admin',
        'doctor',
        'patient',
        'unregistered'
      ];

      _userDataStream = Stream.fromFuture(() async {
        for (final collection in collections) {
          print('Checking in collection: $collection');
          final snapshot = await FirebaseFirestore.instance
              .collection(collection)
              .doc(uid)
              .get();

          if (snapshot.exists) {
            print('User found in collection: $collection');
            return UserData.fromDocument(snapshot);
          }
        }
        print('User not found in any collection');
        return null; // User not found in any collection
      }());
    }
    return _userDataStream;
  }

  static Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      // Get a reference to the storage bucket and file
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      // Upload the file
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg', // Explicitly specify the file type
        ),
      );

      // Wait for the upload to complete and get the download URL
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl; // Return the URL
    } catch (e) {
      // Catch specific Firebase errors if needed
      throw Exception("Error uploading profile image: $e");
    }
  }

  Future<String?> getTargetUserRole(String userId) async {
    try {
      List<String> collections = [
        'caregiver',
        'admin',
        'doctor',
        'patient',
        'unregistered'
      ];

      for (String collection in collections) {
        var userDoc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(userId)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          return data['userRole']; // Assuming the userRole field exists
        }
      }

      return null; // User not found
    } catch (e) {
      print('Error fetching target user role: $e');
      return null;
    }
  }

  Future<void> addNotification(
    String userId,
    String notificationMessage,
    String type,
  ) async {
    final timestamp = Timestamp.now();
    final notificationId =
        DateTime.now().millisecondsSinceEpoch.toString(); // Unique ID

    // Adjust the notification message if it is for a task
    if (type == 'task' && notificationMessage.contains("assigned by Dr.")) {
      notificationMessage =
          notificationMessage.replaceFirst('New task', 'Task Assigned');
    }

    try {
      // Get the user's role
      String? userRole = await getTargetUserRole(userId);

      if (userRole == null) {
        print('Error: Could not determine user role for userId: $userId');
        return;
      }

      // Pluralize the user role to match Firestore collection naming
      String userCollection = userRole;

      // Add the notification to the appropriate user document in the collection
      await FirebaseFirestore.instance
          .collection(userCollection)
          .doc(userId)
          .update({
        'notifications': FieldValue.arrayUnion([
          {
            'notificationId': notificationId,
            'message': notificationMessage,
            'timestamp': timestamp,
            'type': type,
            'read': false, // Default to unread
          }
        ]),
      });
      print('Notification added for userId: $userId in $userCollection');
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  Future<void> saveTaskForPatient(
    String patientId,
    String taskId,
    String taskTitle,
    String taskDescription,
    String category,
    Timestamp startDate,
    Timestamp endDate,
    String doctorId,
  ) async {
    final timestamp = Timestamp.now();

    // Fetch doctor's name from the doctors collection
    final doctorSnapshot = await FirebaseFirestore.instance
        .collection('doctor')
        .doc(doctorId)
        .get();
    String doctorName = '';
    if (doctorSnapshot.exists) {
      final data = doctorSnapshot.data() as Map<String, dynamic>;
      doctorName =
          '${data['firstName']?.trim() ?? ''} ${data['lastName']?.trim() ?? ''}'
              .trim();
    }

    // Convert Timestamps to Date Strings
    final String startDateString =
        '${startDate.toDate().year}-${startDate.toDate().month.toString().padLeft(2, '0')}-${startDate.toDate().day.toString().padLeft(2, '0')}';
    final String endDateString =
        '${endDate.toDate().year}-${endDate.toDate().month.toString().padLeft(2, '0')}-${endDate.toDate().day.toString().padLeft(2, '0')}';

    try {
      // Add task to the patient's document in the caregivers collection
      await FirebaseFirestore.instance
          .collection('caregiver')
          .doc(patientId)
          .update({
        'tasks': FieldValue.arrayUnion([
          {
            'id': taskId,
            'title': taskTitle,
            'description': taskDescription,
            'category': category,
            'timestamp': timestamp,
            'startDate': startDate,
            'endDate': endDate,
            'isCompleted': false,
          }
        ]),
      });

      // Send notifications
      await addNotification(
        patientId,
        "New task assigned by Dr. $doctorName: $taskTitle ($startDateString to $endDateString).",
        'task',
      );
      await addNotification(
        doctorId,
        "You assigned a task to patient: $taskTitle ($startDateString to $endDateString).",
        'task',
      );
    } catch (e) {
      throw Exception('Error saving task for patient: $e');
    }
  }

  Future<void> saveTaskForDoctor(
    String doctorId,
    String taskId,
    String taskTitle,
    String taskDescription,
    String category,
    dynamic startDate,
    dynamic endDate,
    String patientId,
  ) async {
    final timestamp = Timestamp.now();

    // Fetch patient's name from the caregivers collection
    final patientSnapshot = await FirebaseFirestore.instance
        .collection('caregiver')
        .doc(patientId)
        .get();
    String patientName = '';
    if (patientSnapshot.exists) {
      final data = patientSnapshot.data() as Map<String, dynamic>;
      patientName =
          '${data['firstName']?.trim() ?? ''} ${data['lastName']?.trim() ?? ''}'
              .trim();
    }

    Timestamp startTimestamp =
        startDate is Timestamp ? startDate : Timestamp.fromDate(startDate);
    Timestamp endTimestamp =
        endDate is Timestamp ? endDate : Timestamp.fromDate(endDate);

    final String startDateString =
        '${startTimestamp.toDate().year}-${startTimestamp.toDate().month.toString().padLeft(2, '0')}-${startTimestamp.toDate().day.toString().padLeft(2, '0')}';
    final String endDateString =
        '${endTimestamp.toDate().year}-${endTimestamp.toDate().month.toString().padLeft(2, '0')}-${endTimestamp.toDate().day.toString().padLeft(2, '0')}';

    try {
      // Add task to the doctor's document in the doctors collection
      await FirebaseFirestore.instance
          .collection('doctor')
          .doc(doctorId)
          .update({
        'assignedTasks': FieldValue.arrayUnion([
          {
            'id': taskId,
            'title': taskTitle,
            'description': taskDescription,
            'category': category,
            'timestamp': timestamp,
            'startDate': startTimestamp,
            'endDate': endTimestamp,
            'patientId': patientId,
            'startDateString': startDateString,
            'endDateString': endDateString,
          }
        ]),
      });

      // Send notification to the doctor
      await addNotification(
        doctorId,
        "You assigned a task to $patientName: $taskTitle ($startDateString to $endDateString).",
        'task',
      );
    } catch (e) {
      throw Exception('Error saving task for doctor: $e');
    }
  }

// Remove task for the patient
  Future<void> removeTaskForPatient(String patientId, String taskId) async {
    try {
      final collection = FirebaseFirestore.instance.collection('caregiver');
      final snapshot = await collection.doc(patientId).get();
      if (snapshot.exists) {
        final tasks =
            List<Map<String, dynamic>>.from(snapshot.get('tasks') ?? []);
        tasks.removeWhere((task) => task['id'] == taskId);
        await collection.doc(patientId).update({'tasks': tasks});
      }

      await addNotification(patientId, 'Task removed', 'task');
    } catch (e) {
      throw Exception('Error removing task: $e');
    }
  }

  Future<void> removeTaskForDoctor(String doctorId, String taskId) async {
    try {
      final collection = FirebaseFirestore.instance.collection('doctor');
      final snapshot = await collection.doc(doctorId).get();

      if (snapshot.exists) {
        // Get the current tasks and filter out the one with the matching taskId
        final tasks = List<Map<String, dynamic>>.from(
            snapshot.get('assignedTasks') ?? []);
        tasks.removeWhere((task) => task['id'] == taskId);

        // Update the tasks field with the filtered list
        await collection.doc(doctorId).update({'assignedTasks': tasks});
      }

      // Optionally send a notification about task removal
      await addNotification(doctorId, 'Task removed from your tasks', 'task');
    } catch (e) {
      throw Exception('Error removing task for doctor: $e');
    }
  }

  // Fetch tasks for a user (both doctor and patient)
  Future<List<Map<String, dynamic>>> getTasksForUser(
      String userId, UserRole userRole) async {
    String collectionName;
    switch (userRole) {
      case UserRole.caregiver:
        collectionName = 'caregiver';
        break;
      case UserRole.doctor:
        collectionName = 'doctor';
        break;
      case UserRole.admin:
        collectionName = 'admin';
        break;
      case UserRole.patient:
        collectionName = 'patient';
        break;
      case UserRole.unregistered:
        collectionName = 'unregistered';
        break;
      default:
        throw Exception('Unhandled UserRole: $userRole');
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(userId)
          .get();
      if (snapshot.exists) {
        return List<Map<String, dynamic>>.from(snapshot.get('tasks') ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  Future<void> saveScheduleForDoctor(
      String doctorId, DateTime scheduledDateTime, String patientId) async {
    final Timestamp timestamp = Timestamp.fromDate(scheduledDateTime);

    // Fetch patient name from the 'caregivers' collection
    final patientSnapshot = await FirebaseFirestore.instance
        .collection('caregiver')
        .doc(patientId)
        .get();

    String patientName = '';
    if (patientSnapshot.exists) {
      patientName = patientSnapshot.data()?['firstName']?.trim() ?? '';
      String lastName = patientSnapshot.data()?['lastName']?.trim() ?? '';
      patientName = '$patientName $lastName'.trim();
    }

    // Format date and time
    String formattedDateTime =
        DateFormat('MMMM dd, yyyy h:mm a').format(scheduledDateTime);

    // Save schedule for the doctor in the 'doctors' collection
    await FirebaseFirestore.instance.collection('doctor').doc(doctorId).update({
      'schedule': FieldValue.arrayUnion([
        {
          'date': timestamp,
          'time': DateFormat.jm().format(scheduledDateTime),
          'patientId': patientId,
          'patientName': patientName,
        }
      ]),
    });

    // Add schedule notification for the doctor
    await addNotification(
      doctorId,
      "Scheduled visit for patient $patientName at $formattedDateTime.",
      'schedule',
    );
  }

  Future<void> saveScheduleForPatient(
      String patientId, DateTime scheduledDateTime, String doctorId) async {
    final Timestamp timestamp = Timestamp.fromDate(scheduledDateTime);

    // Fetch doctor name from the 'doctors' collection
    final doctorSnapshot = await FirebaseFirestore.instance
        .collection('doctor')
        .doc(doctorId)
        .get();

    String doctorName = '';
    if (doctorSnapshot.exists) {
      doctorName = doctorSnapshot.data()?['firstName']?.trim() ?? '';
      String lastName = doctorSnapshot.data()?['lastName']?.trim() ?? '';
      doctorName = '$doctorName $lastName'.trim();
    }

    // Format date and time
    String formattedDateTime =
        DateFormat('MMMM dd, yyyy h:mm a').format(scheduledDateTime);

    // Save schedule for the patient in the 'caregivers' collection
    await FirebaseFirestore.instance
        .collection('caregiver')
        .doc(patientId)
        .update({
      'schedule': FieldValue.arrayUnion([
        {
          'date': timestamp,
          'time': DateFormat.jm().format(scheduledDateTime),
          'doctorId': doctorId,
          'doctorName': doctorName,
        }
      ]),
    });

    // Add schedule notification for the patient
    await addNotification(
      patientId,
      "Scheduled appointment with doctor $doctorName at $formattedDateTime.",
      'schedule',
    );
  }

  // Fetch the schedule for a user
  Future<List<Map<String, dynamic>>> getScheduleForUser(
      String userId, String userRole) async {
    try {
      final collection = _getCollectionForRole(userRole as UserRole);
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .get();

      if (snapshot.exists) {
        return List<Map<String, dynamic>>.from(snapshot.get('schedule') ?? []);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
      return [];
    }
  }

  Future<void> removePastSchedules(String userId, String userRole) async {
    final currentDateOnly =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    try {
      final collection = _getCollectionForRole(userRole as UserRole);

      // Get the user document
      final userDoc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        debugPrint('User document does not exist.');
        return;
      }

      // Get the schedule data
      final schedulesData = userDoc.data()?['schedule'] ?? [];
      debugPrint("SchedulesData: $schedulesData");

      // Loop through each schedule and check if it's passed today
      for (var schedule in schedulesData) {
        if (schedule['date'] != null) {
          final scheduleTimestamp = schedule['date'] as Timestamp;
          final scheduleDate = scheduleTimestamp.toDate();
          final scheduleDateOnly =
              DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day);

          if (scheduleDateOnly.isBefore(currentDateOnly)) {
            await _removeScheduleFromUser(userId, userRole, schedule);
          } else {
            debugPrint(
                "Schedule is today or in the future, not removing: $scheduleDateOnly");
          }
        } else {
          debugPrint('No date found for schedule: $schedule');
        }
      }
    } catch (e) {
      debugPrint('Error removing past schedules: $e');
    }
  }

  Future<void> _removeScheduleFromUser(
      String userId, String userRole, Map<String, dynamic> schedule) async {
    try {
      final collection = _getCollectionForRole(userRole as UserRole);

      if (schedule['date'] != null) {
        final scheduleTimestamp = schedule['date'] as Timestamp;

        debugPrint("schedule timestamp: $scheduleTimestamp");
        debugPrint("schedule date: ${scheduleTimestamp.toDate()}");

        final scheduleToRemove = {
          'date': scheduleTimestamp,
          'doctorId': schedule['doctorId'],
          'time': schedule['time'],
          'patientId':
              schedule['patientId'], // Ensure all relevant fields are present
        };

        await FirebaseFirestore.instance
            .collection(collection)
            .doc(userId)
            .update({
          'schedule': FieldValue.arrayRemove([scheduleToRemove]),
        });

        debugPrint('Removed past schedule for user $userId');
      } else {
        debugPrint('No date found for schedule: $schedule');
      }
    } catch (e) {
      debugPrint('Error removing schedule: $e');
    }
  }

  Future<void> sendFriendRequest(
      String currentUserId, String targetUserId) async {
    final timestamp = FieldValue.serverTimestamp();

    try {
      // Prevent sending a friend request to yourself
      if (currentUserId == targetUserId) {
        print('Error: Cannot send a friend request to yourself.');
        return;
      }

      // Fetch the current user's role
      String? currentUserRole = await getTargetUserRole(currentUserId);
      debugPrint("Send Friend Request Current User Role: $currentUserRole");
      if (currentUserRole == null) {
        print('Error: Current user role not found.');
        return;
      }

      // Fetch the target user's role
      String? targetUserRole = await getTargetUserRole(targetUserId);
      if (targetUserRole == null) {
        print('Error: Target user role not found.');
        return;
      }

      // Append 's' to roles to match collection names
      final currentUserCollection = currentUserRole;
      final targetUserCollection = targetUserRole;

      // Fetch the current user's name
      final currentUserSnapshot = await FirebaseFirestore.instance
          .collection(currentUserCollection)
          .doc(currentUserId)
          .get();

      String currentUserName = '';
      if (currentUserSnapshot.exists) {
        currentUserName =
            currentUserSnapshot.data()?['firstName']?.trim() ?? '';
        String lastName = currentUserSnapshot.data()?['lastName']?.trim() ?? '';
        currentUserName = '$currentUserName $lastName'.trim();
      }

      // Send the friend request
      await FirebaseFirestore.instance
          .collection(targetUserCollection)
          .doc(targetUserId)
          .update({
        'contacts.requests.$currentUserId': {'timestamp': timestamp},
      });

      print('Friend request sent from $currentUserId to $targetUserId');

      // Add notification for the target user
      await addNotification(
        targetUserId,
        "You have a new friend request from $currentUserName.",
        'friend_request',
      );
    } catch (e) {
      debugPrint('Error sending friend request: $e');
    }
  }

  Future<void> acceptFriendRequest(
      String currentUserId, String senderUserId) async {
    final timestamp = FieldValue.serverTimestamp();

    try {
      // Fetch roles dynamically
      String? currentUserRole = await getTargetUserRole(currentUserId);
      String? senderUserRole = await getTargetUserRole(senderUserId);

      if (currentUserRole == null || senderUserRole == null) {
        print('Error: User roles not found.');
        return;
      }

      // Convert roles to plural collection names
      String currentUserCollection = currentUserRole;
      String senderUserCollection = senderUserRole;

      // Fetch current user name
      final currentUserSnapshot = await FirebaseFirestore.instance
          .collection(currentUserCollection)
          .doc(currentUserId)
          .get();

      String currentUserName = '';
      if (currentUserSnapshot.exists) {
        currentUserName =
            currentUserSnapshot.data()?['firstName']?.trim() ?? '';
        String lastName = currentUserSnapshot.data()?['lastName']?.trim() ?? '';
        currentUserName = '$currentUserName $lastName'.trim();
      }

      // Transaction to accept the friend request
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final currentUserRef = FirebaseFirestore.instance
            .collection(currentUserCollection)
            .doc(currentUserId);
        final senderUserRef = FirebaseFirestore.instance
            .collection(senderUserCollection)
            .doc(senderUserId);

        transaction.update(currentUserRef, {
          'contacts.requests.$senderUserId': FieldValue.delete(),
          'contacts.friends.$senderUserId': {'timestamp': timestamp},
        });

        transaction.update(senderUserRef, {
          'contacts.friends.$currentUserId': {'timestamp': timestamp},
        });
      });

      print('Accepted friend request from $senderUserId for $currentUserId');

      // Add notification for the sender
      await addNotification(
        senderUserId,
        "Your friend request to $currentUserName has been accepted.",
        'friend_request',
      );
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
    }
  }

  Future<void> declineFriendRequest(
      String currentUserId, String senderUserId) async {
    try {
      // Fetch current user's role
      String? currentUserRole = await getTargetUserRole(currentUserId);
      if (currentUserRole == null) {
        print('Error: Current user role not found.');
        return;
      }

      String currentUserCollection = currentUserRole;

      await FirebaseFirestore.instance
          .collection(currentUserCollection)
          .doc(currentUserId)
          .update({'contacts.requests.$senderUserId': FieldValue.delete()});

      print('Declined friend request from $senderUserId for $currentUserId');
    } catch (e) {
      print('Error declining friend request: $e');
    }
  }

  Future<void> removeFriend(String currentUserId, String friendUserId) async {
    try {
      // Fetch roles dynamically
      String? currentUserRole = await getTargetUserRole(currentUserId);
      String? friendUserRole = await getTargetUserRole(friendUserId);

      if (currentUserRole == null || friendUserRole == null) {
        print('Error: User roles not found.');
        return;
      }

      String currentUserCollection = currentUserRole;
      String friendUserCollection = friendUserRole;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final currentUserRef = FirebaseFirestore.instance
            .collection(currentUserCollection)
            .doc(currentUserId);
        final friendUserRef = FirebaseFirestore.instance
            .collection(friendUserCollection)
            .doc(friendUserId);

        transaction.update(currentUserRef,
            {'contacts.friends.$friendUserId': FieldValue.delete()});
        transaction.update(friendUserRef,
            {'contacts.friends.$currentUserId': FieldValue.delete()});
      });

      print('Removed friend $friendUserId from $currentUserId');
    } catch (e) {
      print('Error removing friend: $e');
    }
  }

// Check if the user exists by UID
  Future<bool> checkUserExists(String userId) async {
    try {
      List<String> collections = [
        'caregiver',
        'admin',
        'doctor',
        'patient',
        'unregistered'
      ];

      for (String collection in collections) {
        var userDoc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(userId)
            .get();
        if (userDoc.exists) {
          return true; // User found
        }
      }

      return false; // User not found in any collection
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

// Check if the user is already a friend
  Future<bool> isUserFriend(String currentUserId, String targetUserId) async {
    try {
      // Fetch current user's role
      String? currentUserRole = await getTargetUserRole(currentUserId);
      if (currentUserRole == null) {
        print('Error: Current user role not found.');
        return false;
      }

      // Convert role to plural collection name
      String currentUserCollection = currentUserRole;

      // Fetch user document
      var userDoc = await FirebaseFirestore.instance
          .collection(currentUserCollection)
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        var friends = userDoc.data()?['contacts']?['friends'];
        return friends != null && friends.containsKey(targetUserId);
      }
      return false;
    } catch (e) {
      print('Error checking if user is a friend: $e');
      return false;
    }
  }

// Check if the user already has a pending friend request
  Future<bool> hasPendingRequest(
      String currentUserId, String targetUserId) async {
    try {
      // Fetch the target user's role (receiver's role)
      String? targetUserRole = await getTargetUserRole(targetUserId);
      if (targetUserRole == null) {
        debugPrint('Error: Target user role not found for user $targetUserId');
        return false;
      }

      debugPrint("Checking pending request for target user id: $targetUserId");
      debugPrint("Target user role: $targetUserRole");

      // Convert role to plural collection name
      String targetUserCollection = targetUserRole;

      // Fetch the target user's document
      var userDoc = await FirebaseFirestore.instance
          .collection(targetUserCollection)
          .doc(targetUserId)
          .get();

      if (userDoc.exists) {
        var contacts = userDoc.data()?['contacts'];
        debugPrint("Contacts for target user: $contacts");
        if (contacts == null) {
          debugPrint('No contacts field found for user $targetUserId');
          return false;
        }

        var requests = contacts['requests'];

        debugPrint('Requests for target user: $requests');
        if (requests == null) {
          debugPrint(
              'No requests field found in contacts for user $targetUserId');
          return false;
        }

        // Check if the currentUserId (sender) is in the requests map
        bool requestExists = requests.containsKey(currentUserId);
        debugPrint(
            'Pending request from $currentUserId to $targetUserId: $requestExists');
        return requestExists;
      } else {
        debugPrint('User document not found for $targetUserId');
      }
      return false;
    } catch (e) {
      debugPrint('Error checking for pending request: $e');
      return false;
    }
  }

  Future<String> getUserName(String userId, UserRole userRole) async {
    try {
      final userCollection = _getCollectionForRole(userRole);
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection(userCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Concatenate firstName, middleName, and lastName
        String firstName = userDoc['firstName'] ?? '';
        String middleName = userDoc['middleName'] ?? '';
        String lastName = userDoc['lastName'] ?? '';

        // Combine parts with proper spacing
        String fullName =
            '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName';

        return fullName.trim().isEmpty ? 'Unknown' : fullName.trim();
      } else {
        throw Exception("User not found");
      }
    } catch (e) {
      print("Error getting user name: $e");
      return 'Error'; // Return 'Error' if an exception occurs
    }
  }

  Future<bool> isPhoneNumberUnique(String phoneNumber) async {
    try {
      // Collections to check (caregivers, admins, doctors)
      List<String> collections = [
        'caregiver',
        'admin',
        'doctor',
        'patient',
        'unregistered'
      ];

      for (String collection in collections) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection(collection)
            .where('phoneNumber', isEqualTo: phoneNumber)
            .get();

        // If the phone number exists in any collection, return false
        if (querySnapshot.docs.isNotEmpty) {
          return false;
        }
      }

      // If not found in any collection, it's unique
      return true;
    } catch (e) {
      print("Error checking phone number uniqueness: $e");
      return false; // Assume not unique in case of error
    }
  }

  Future<List<String>> fetchSymptoms(String userId, UserRole userRole) async {
    try {
      final userCollection = _getCollectionForRole(userRole);
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection(userCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Retrieve symptoms field from the document
        final symptoms = userDoc['symptoms'] as List<dynamic>?;
        if (symptoms != null) {
          return symptoms.map((symptom) => symptom.toString()).toList();
        }
      }
      return []; // Return an empty list if no symptoms found or doc does not exist
    } catch (e) {
      print('Error fetching symptoms: $e');
      return [];
    }
  }

  Stream<List<UserData?>> fetchUsersByRole(UserRole role) {
    final collection = getCollectionForRole(role);
    return FirebaseFirestore.instance.collection(collection).snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => UserData.fromDocument(doc)).toList());
  }

  Stream<List<UserData>> get patients {
    return FirebaseFirestore.instance
        .collection(
            'patient') // Replace 'patients' with your actual collection name
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserData.fromDocument(doc)).toList();
    });
  }

  Future<UserData?> getUserDataById(String uid) async {
    List<String> roles = [
      'admin',
      'doctor',
      'caregiver',
      'patient',
      'unregistered'
    ];
    for (String role in roles) {
      final String collectionName = role;
      final doc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserData.fromDocument(doc); // Found the user
      }
    }
    debugPrint('User with UID $uid not found in any role-based collection.');
    return null; // User not found
  }

  Future<Map<String, dynamic>?> getPatientData(String uid) async {
    try {
      debugPrint("Get Patient Data uid: $uid");
      // Specify the collection you want to get data from, in this case, 'patients'
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance
          .collection(
              'patient') // Ensure your collection name is 'patients' (plural)
          .doc(uid) // Use the UID to fetch the specific patient
          .get();

      if (patientDoc.exists) {
        // If the patient data exists, return it as a Map
        return patientDoc.data() as Map<String, dynamic>;
      } else {
        // If no patient data exists, return null
        return null;
      }
    } catch (e) {
      print("Error fetching patient data: $e");
      return null;
    }
  }

  Future<void> addPatientData({
    required String uid,
    String? firstName,
    String? lastName,
    String? middleName,
    int? age,
    String? gender,
    String? religion,
    String? will,
    String? fixedWishes,
    String? organDonation,
    String? profileImageUrl,
    DateTime? birthday,
  }) async {
    try {
      // Get the appropriate collection for the user role
      final collectionName = getCollectionForRole(UserRole.patient);

      // Get the Firestore reference
      final collectionRef =
          FirebaseFirestore.instance.collection(collectionName);

      // Prepare the updated data
      Map<String, dynamic> updatedData = {};

      if (firstName != null) updatedData['firstName'] = firstName;
      if (lastName != null) updatedData['lastName'] = lastName;
      if (middleName != null) updatedData['middleName'] = middleName;

      if (birthday != null) {
        updatedData['birthday'] = Timestamp.fromDate(birthday);

        // Calculate the age if not provided
        if (age == null) {
          final now = DateTime.now();
          int years = now.year - birthday.year;
          if (now.month < birthday.month ||
              (now.month == birthday.month && now.day < birthday.day)) {
            years--;
          }
          updatedData['age'] = years;
        } else {
          updatedData['age'] = age; // Use the passed age if provided
        }
      }

      if (gender != null) updatedData['gender'] = gender;
      if (religion != null) updatedData['religion'] = religion;
      if (will?.isNotEmpty ?? false) updatedData['will'] = will;
      if (fixedWishes?.isNotEmpty ?? false) {
        updatedData['fixedWishes'] = fixedWishes;
      }
      if (organDonation?.isNotEmpty ?? false) {
        updatedData['organDonation'] = organDonation;
      }
      if (profileImageUrl != null) {
        updatedData['profileImageUrl'] = profileImageUrl;
      }

      // Perform the update only if there's data to update
      if (updatedData.isNotEmpty) {
        await collectionRef.doc(uid).set(updatedData, SetOptions(merge: true));
        print(
            "Patient data updated successfully in collection: $collectionName");
      } else {
        print("No updates provided for patient data.");
      }
    } catch (e) {
      print("Error updating patient data: $e");
      throw Exception("Failed to update patient data");
    }
  }
}
