// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps, unreachable_switch_default

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:solace/models/my_patient.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/controllers/messaging_service.dart';
import 'package:solace/services/log_service.dart';

class DatabaseService {
  final String? uid;
  final LogService _logService = LogService();

  DatabaseService({this.uid});

  // Method to dynamically get the collection reference based on user role
  String getCollectionForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.nurse:
        return 'nurse';
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

      final currentCollection = getCollectionForRole(currentRole);
      final newCollection = getCollectionForRole(newRole);

      // Move the user document to the new collection if the role is changing
      if (currentCollection != newCollection) {
        // Get the user's current document
        final currentDoc =
            await FirebaseFirestore.instance
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
                'userRole':
                    newRole.toString().split('.').last, // Update the role
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
            .update({'userRole': newRole.toString().split('.').last});
      }

      print('Updated user role for $userId to ${newRole.toString()}');
    } catch (e) {
      print('Error updating user role: $e');
    }
  }

  Future<UserRole?> _getUserRoleById(String userId) async {
    // Check all user role collections for the user
    for (UserRole role in UserRole.values) {
      final collection = getCollectionForRole(role);
      final userDoc =
          await FirebaseFirestore.instance
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
      final userDoc =
          await FirebaseFirestore.instance
              .collection(collection)
              .doc(userId)
              .get();
      if (userDoc.exists) {
        return role;
      }
    }
    return null; // User role not found
  }

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
      final collectionRef = FirebaseFirestore.instance.collection(
        collectionName,
      );

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
    String uid,
    bool isVerified,
    String userRole,
  ) async {
    try {
      final String collectionName = userRole; // Generate the collection name
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(uid)
          .update({'isVerified': isVerified});
      debugPrint(
        'User verification status updated to $isVerified for user $uid in $collectionName',
      );
    } catch (e) {
      debugPrint("Error updating user verification status: ${e.toString()}");
    }
  }

  Future<UserData?> getUserDataByEmail(email) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      User? user = auth.currentUser;

      if (user == null) {
        throw Exception("No user is currently signed in.");
      }

      final String uid = user.uid;
      final DatabaseService db = DatabaseService();

      String? userRole = await db.getTargetUserRole(uid);
      if (userRole == null || userRole.isEmpty) {
        return null;
      }

      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection(userRole)
              .where('email', isEqualTo: email)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserData.fromDocument(querySnapshot.docs.first);
      }

      return null;
    } catch (e) {
      print("Error fetching user data by email: ${e.toString()}");
      return null;
    }
  }

  // Fetch the users by role
  Stream<List<UserData>> getUsersByRole(String role) {
    return FirebaseFirestore.instance.collection(role).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return UserData.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> deleteUser(String userId) async {
    try {
      // 1. Identify and delete the Firestore user document from the appropriate collection
      UserData? userData = await getUserById(userId);

      String? collectionName = await getTargetUserRole(userId);

      if (userData != null) {
        await FirebaseFirestore.instance
            .collection(collectionName!)
            .doc(userId)
            .delete();
        print(
          "User document deleted from Firestore collection: $collectionName.",
        );
      } else {
        print("User document not found in any collection.");
        return;
      }

      // 2. Delete records in the 'tracking' collection related to the user
      final batch = FirebaseFirestore.instance.batch();
      final trackingDocs =
          await FirebaseFirestore.instance
              .collection('tracking')
              .where('userId', isEqualTo: userId)
              .get();

      for (var doc in trackingDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print("Related tracking records deleted.");

      // Add log entry
      await _logService.addLog(
        userId: uid??'',
        action: 'Deleted user $userId',
        relatedUsers: userId,
      );
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  Future<String> getProfileImageUrl(String userId, UserRole userRole) async {
    try {
      // Use the role-based collection based on the user's role
      String collection = userRole.toString().split('.').last;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
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
      CollectionReference patientCollection = FirebaseFirestore.instance
          .collection('patient');

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
      DocumentReference vitalDocRef = patientCollection
          .doc(patientId)
          .collection('vitals')
          .doc(vital);

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

      String? userRole = await getTargetUserRole(uid!);

      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance.collection(userRole!).doc(uid).get();

      if (snapshot.exists) {
        return UserData.fromDocument(snapshot);
      }

      print("No document found for UID: $uid");
      return null; // Handle missing document case
    } catch (e) {
      print('Error fetching user data for UID $uid: $e');
      return null;
    }
  }

  Future<UserData?> getUserById(String userId) async {
    if (userId.isEmpty) {
      debugPrint('User ID is empty. Cannot fetch user data.');
      return null;
    }

    try {
      debugPrint("Fetching user data for ID: $userId");

      // Retrieve the user's role to determine the collection name
      String? collectionName = await getTargetUserRole(userId);
      if (collectionName == null) {
        debugPrint("User role could not be determined for user ID: $userId");
        return null;
      }

      // Fetch the user document from Firestore
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection(collectionName)
              .doc(userId)
              .get();

      // Check if the document exists and convert it into UserData
      if (docSnapshot.exists) {
        debugPrint("User data found for ID: $userId");
        return UserData.fromDocument(docSnapshot);
      }

      debugPrint("No document found for user ID: $userId");
      return null;
    } catch (e, stackTrace) {
      debugPrint("Error fetching user by ID $userId: $e");
      debugPrint("Stack trace: $stackTrace");
      return null;
    }
  }

  Stream<UserData?>? _userDataStream;

  Stream<UserData?>? get userData {
    if (_userDataStream == null) {
      debugPrint('Fetching user data for UID: $uid');
      _userDataStream = Stream.fromFuture(() async {
        if (uid == null) {
          debugPrint('UID is null. Cannot fetch user data.');
          return null;
        }

        try {
          // Use getTargetUserRole to determine the collection
          final role = await getTargetUserRole(uid!);
          if (role == null) {
            debugPrint('User role could not be determined for UID: $uid');
            return null;
          }

          debugPrint('User role: $role. Fetching document...');
          final snapshot =
              await FirebaseFirestore.instance.collection(role).doc(uid).get();

          if (snapshot.exists) {
            debugPrint('User data found in role: $role');
            return UserData.fromDocument(snapshot);
          } else {
            debugPrint('No user data found for UID: $uid in role: $role');
            return null;
          }
        } catch (e, stackTrace) {
          debugPrint('Error fetching user data for UID: $uid - $e');
          debugPrint('Stack trace: $stackTrace');
          return null;
        }
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
      // List of collections to check
      List<String> collections = [
        'patient',
        'caregiver',
        'admin',
        'doctor',
        'nurse',
        'unregistered',
      ];

      // Loop through each collection to find the user document
      for (String collection in collections) {
        var userDoc =
            await FirebaseFirestore.instance
                .collection(collection)
                .doc(userId)
                .get();

        if (userDoc.exists) {
          // Safely retrieve data and userRole field
          final data = userDoc.data() ?? {};
          return data['userRole'] as String?; // Ensure userRole is a String
        }
      }

      // If no matching document is found
      return null;
    } catch (e) {
      debugPrint('Error fetching target user role: $e');
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
      notificationMessage = notificationMessage.replaceFirst(
        'New task',
        'Task Assigned',
      );
    }

    try {
      // Get the user's role
      String? userRole = await getTargetUserRole(userId);

      // Add the notification to the appropriate user document in the collection
      await FirebaseFirestore.instance.collection(userRole!).doc(userId).update(
        {
          'notifications': FieldValue.arrayUnion([
            {
              'notificationId': notificationId,
              'message': notificationMessage,
              'timestamp': timestamp,
              'type': type,
              'read': false, // Default to unread
            },
          ]),
        },
      );
      print('Notification added for userId: $userId in $userRole');
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  Future<void> saveMedicineForPatient(
    String patientId,
    String medicineId,
    String medicineTitle,
    String dosage,
    String usage,
    String doctorId,
  ) async {
    // Fetch doctor name
    final String? doctorRole = await getTargetUserRole(doctorId);
    final doctorSnapshot =
        await FirebaseFirestore.instance
            .collection(doctorRole!)
            .doc(doctorId)
            .get();

    String doctorName = '';
    if (doctorSnapshot.exists) {
      final data = doctorSnapshot.data()!;
      final firstName = data['firstName']?.trim() ?? '';
      final lastName = data['lastName']?.trim() ?? '';
      doctorName = '$firstName $lastName'.trim();
    }

    final medicineData = {
      "medicineId": medicineId,
      "medicineName": medicineTitle,
      "dosage": dosage,
      "usage": usage,
    };

    try {
      final patientMedicinesRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(patientId)
          .collection('medicines')
          .doc(doctorId);

      final patientMedicinesDoc = await patientMedicinesRef.get();

      if (patientMedicinesDoc.exists) {
        await patientMedicinesRef.update({
          'medicines': FieldValue.arrayUnion([medicineData]),
        });
      } else {
        await patientMedicinesRef.set({
          'medicines': [medicineData],
        });
      }

      // Send in-app notification
      await addNotification(
        patientId,
        "New medicine $medicineTitle assigned by Dr. $doctorName.",
        'medicine',
      );
    } catch (e) {
      throw Exception('Error saving medicine for patient: $e');
    }
  }

  Future<void> saveMedicineForDoctor(
    String doctorId,
    String medicineId,
    String medicineTitle,
    String dosage,
    String usage,
    String patientId,
  ) async {
    // Fetch patient name
    final patientSnapshot =
        await FirebaseFirestore.instance
            .collection('patient')
            .doc(patientId)
            .get();

    String patientName = '';
    if (patientSnapshot.exists) {
      final data = patientSnapshot.data()!;
      final firstName = data['firstName']?.trim() ?? '';
      final lastName = data['lastName']?.trim() ?? '';
      patientName = '$firstName $lastName'.trim();
    }

    final medicineData = {
      "medicineId": medicineId,
      "medicineName": medicineTitle,
      "dosage": dosage,
      "usage": usage,
    };

    try {
      final String? doctorRole = await getTargetUserRole(doctorId);
      if (doctorRole == null) {
        throw Exception('User role not found for doctor.');
      }

      final doctorMedicinesRef = FirebaseFirestore.instance
          .collection(doctorRole)
          .doc(doctorId)
          .collection('medicines')
          .doc(patientId);

      final doctorMedicinesDoc = await doctorMedicinesRef.get();

      if (doctorMedicinesDoc.exists) {
        await doctorMedicinesRef.update({
          'medicines': FieldValue.arrayUnion([medicineData]),
        });
      } else {
        await doctorMedicinesRef.set({
          'medicines': [medicineData],
        });
      }

      // Send in-app notification
      await addNotification(
        doctorId,
        "You assigned $medicineTitle to $patientName.",
        'medicine',
      );

      // Fetch doctor's FCM token
      final doctorSnapshot =
          await FirebaseFirestore.instance
              .collection(doctorRole)
              .doc(doctorId)
              .get();

      if (doctorSnapshot.exists) {
        final doctorData = doctorSnapshot.data()!;
        final fcmToken = doctorData['fcmToken'];

        if (fcmToken != null) {
          // Send push notification
          await MessagingService.sendFCMMessage(
            fcmToken,
            "Medicine Assignment",
            "You assigned $medicineTitle to $patientName.",
          );
        } else {
          debugPrint("Doctor's FCM token not found.");
        }
      }
    } catch (e) {
      throw Exception('Error saving medicine for doctor: $e');
    }
  }

  Future<void> removeMedicine(
    String patientId,
    String medicineId,
    String caregiverId,
  ) async {
    try {
      final patientMedicinesRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(patientId)
          .collection('medicines');

      final patientMedicinesDoc = await patientMedicinesRef.get();
      if (patientMedicinesDoc.docs.isEmpty) {
        throw Exception('No tasks found for the patient');
      }

      for (var doc in patientMedicinesDoc.docs) {
        final medicines = List.from(doc['medicines']);
        final medicineIndex = medicines.indexWhere(
          (task) => task['medicineId'] == medicineId,
        );

        if (medicineIndex != -1) {
          medicines.removeAt(medicineIndex);
          await patientMedicinesRef.doc(doc.id).update({
            'medicines': medicines,
          });
          break;
        }
      }

      final String? collection = await getTargetUserRole(caregiverId);
      final caregiverMedicinesRef = FirebaseFirestore.instance
          .collection(collection!)
          .doc(caregiverId)
          .collection('medicines');

      final caregiverMedicinesDoc = await caregiverMedicinesRef.get();
      if (caregiverMedicinesDoc.docs.isEmpty) {
        throw Exception('No medicines found for the caregiver');
      }

      for (var doc in caregiverMedicinesDoc.docs) {
        final medicines = List.from(doc['medicines']);
        final medicineIndex = medicines.indexWhere(
          (task) => task['medicineId'] == medicineId,
        );

        if (medicineIndex != -1) {
          medicines.removeAt(medicineIndex);
          await caregiverMedicinesRef.doc(doc.id).update({
            'medicines': medicines,
          });
          break;
        }
      }
    } catch (e) {
      throw Exception('Failed to remove medicine: $e');
    }
  }

  Future<void> saveTaskForPatient(
    String patientId,
    String taskId,
    String taskTitle,
    String taskDescription,
    DateTime startDate,
    DateTime endDate,
    String caregiverId,
  ) async {
    final Timestamp startTimestamp = Timestamp.fromDate(startDate);
    final Timestamp endTimestamp = Timestamp.fromDate(endDate);

    // Fetch caregiver name
    final String? userRole = await getTargetUserRole(caregiverId);
    final caregiverSnapshot =
        await FirebaseFirestore.instance
            .collection(userRole!)
            .doc(caregiverId)
            .get();

    String caregiverName = '';
    if (caregiverSnapshot.exists) {
      final data = caregiverSnapshot.data()!;
      final firstName = data['firstName']?.trim() ?? '';
      final lastName = data['lastName']?.trim() ?? '';
      caregiverName = '$firstName $lastName'.trim();
    }

    final taskData = {
      "caregiverName": caregiverName,
      "taskId": taskId,
      "title": taskTitle,
      "description": taskDescription,
      "startDate": startTimestamp,
      "endDate": endTimestamp,
      "isCompleted": false,
    };

    try {
      final patientTasksRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(patientId)
          .collection('tasks')
          .doc(caregiverId);

      final caregiverTasksDoc = await patientTasksRef.get();

      if (caregiverTasksDoc.exists) {
        await patientTasksRef.update({
          'tasks': FieldValue.arrayUnion([taskData]),
        });
      } else {
        await patientTasksRef.set({
          'tasks': [taskData],
        });
      }
    } catch (e) {
      throw Exception('Failed to save task for patient: $e');
    }
  }

  Future<void> saveTaskForCaregiver(
    String caregiverId,
    String taskId,
    String taskTitle,
    String taskDescription,
    DateTime startDate,
    DateTime endDate,
    String patientId,
  ) async {
    final Timestamp startTimestamp = Timestamp.fromDate(startDate);
    final Timestamp endTimestamp = Timestamp.fromDate(endDate);

    // Fetch patient name
    final patientSnapshot =
        await FirebaseFirestore.instance
            .collection('patient')
            .doc(patientId)
            .get();

    String patientName = '';
    if (patientSnapshot.exists) {
      final data = patientSnapshot.data()!;
      final firstName = data['firstName']?.trim() ?? '';
      final lastName = data['lastName']?.trim() ?? '';
      patientName = '$firstName $lastName'.trim();
    }

    final taskData = {
      "patientName": patientName,
      "taskId": taskId,
      "title": taskTitle,
      "description": taskDescription,
      "startDate": startTimestamp,
      "endDate": endTimestamp,
      "isCompleted": false,
    };

    try {
      final String? userRole = await getTargetUserRole(caregiverId);
      if (userRole == null) {
        throw Exception('User role not found for caregiver.');
      }

      final caregiverTasksRef = FirebaseFirestore.instance
          .collection(userRole)
          .doc(caregiverId)
          .collection('tasks') // Optional if you want a subcollection
          .doc(patientId);

      final caregiverTasksDoc = await caregiverTasksRef.get();

      if (caregiverTasksDoc.exists) {
        await caregiverTasksRef.update({
          'tasks': FieldValue.arrayUnion([taskData]),
        });
      } else {
        await caregiverTasksRef.set({
          'tasks': [taskData],
        });
      }

      await addNotification(
        caregiverId,
        "You assigned a task to $patientName: $taskTitle (${startDate.toLocal()} to ${endDate.toLocal()}).",
        'task',
      );
    } catch (e) {
      throw Exception('Failed to save task for caregiver: $e');
    }
  }

  Future<void> removeTask(
    String patientId,
    String taskId,
    String caregiverId,
  ) async {
    try {
      // Reference to the patient's task collection
      final patientTasksRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(patientId)
          .collection('medicines');

      // Fetch patient tasks and remove the task
      final patientTasksDoc = await patientTasksRef.get();
      if (patientTasksDoc.docs.isEmpty) {
        throw Exception('No medicines found for the patient');
      }

      for (var doc in patientTasksDoc.docs) {
        final tasks = List.from(doc['tasks']);
        final taskIndex = tasks.indexWhere((task) => task['taskId'] == taskId);

        if (taskIndex != -1) {
          tasks.removeAt(taskIndex);
          await patientTasksRef.doc(doc.id).update({'tasks': tasks});
          break; // Task found and removed, break out of the loop
        }
      }

      final String? collection = await getTargetUserRole(caregiverId);
      // Reference to the caregiver's task collection (use caregiverId instead of patientId)
      final caregiverTasksRef = FirebaseFirestore.instance
          .collection(collection!) // Get the caregiver's collection
          .doc(caregiverId) // Use caregiverId here
          .collection('tasks');

      // Fetch caregiver tasks and remove the task
      final caregiverTasksDoc = await caregiverTasksRef.get();
      if (caregiverTasksDoc.docs.isEmpty) {
        throw Exception('No tasks found for the caregiver');
      }

      for (var doc in caregiverTasksDoc.docs) {
        final tasks = List.from(doc['tasks']);
        final taskIndex = tasks.indexWhere((task) => task['taskId'] == taskId);

        if (taskIndex != -1) {
          tasks.removeAt(taskIndex);
          await caregiverTasksRef.doc(doc.id).update({'tasks': tasks});
          break; // Task found and removed, break out of the loop
        }
      }
    } catch (e) {
      throw Exception('Failed to remove task: $e');
    }
  }

  Future<void> updateTask(
    String taskId,
    String caregiverId,
    String patientId,
  ) async {
    try {
      // Update task in the patient's task collection
      final patientTasksRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(patientId)
          .collection('tasks');

      final patientTasksSnapshot = await patientTasksRef.get();
      if (patientTasksSnapshot.docs.isEmpty) {
        throw Exception('No tasks found for the patient');
      }

      bool taskUpdated = false;

      for (var doc in patientTasksSnapshot.docs) {
        final tasks = List.from(doc['tasks']);
        final taskIndex = tasks.indexWhere((task) => task['taskId'] == taskId);

        if (taskIndex != -1) {
          tasks[taskIndex]['isCompleted'] = true;
          await patientTasksRef.doc(doc.id).update({'tasks': tasks});
          taskUpdated = true;
          break; // Task found and updated
        }
      }

      if (!taskUpdated) {
        throw Exception('Task not found in patient\'s collection');
      }

      // Update task in the caregiver's task collection
      final String? caregiverRole = await getTargetUserRole(caregiverId);
      if (caregiverRole == null) {
        throw Exception('Caregiver role not found');
      }

      final caregiverTasksRef = FirebaseFirestore.instance
          .collection(caregiverRole)
          .doc(caregiverId)
          .collection('tasks');

      final caregiverTasksSnapshot = await caregiverTasksRef.get();
      if (caregiverTasksSnapshot.docs.isEmpty) {
        throw Exception('No tasks found for the caregiver');
      }

      taskUpdated = false;

      for (var doc in caregiverTasksSnapshot.docs) {
        final tasks = List.from(doc['tasks']);
        final taskIndex = tasks.indexWhere((task) => task['taskId'] == taskId);

        if (taskIndex != -1) {
          tasks[taskIndex]['isCompleted'] = true;
          await caregiverTasksRef.doc(doc.id).update({'tasks': tasks});
          taskUpdated = true;
          break; // Task found and updated
        }
      }

      if (!taskUpdated) {
        throw Exception('Task not found in caregiver\'s collection');
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> saveScheduleForCaregiver(
    String caregiverId,
    DateTime scheduledDateTime,
    String patientId,
    String scheduleId, // Add scheduleId parameter
  ) async {
    final Timestamp timestamp = Timestamp.fromDate(scheduledDateTime);

    // Fetch patient name
    final patientSnapshot =
        await FirebaseFirestore.instance
            .collection('patient')
            .doc(patientId)
            .get();

    String patientName = '';
    if (patientSnapshot.exists) {
      final data = patientSnapshot.data()!;
      final firstName = data['firstName']?.trim() ?? '';
      final lastName = data['lastName']?.trim() ?? '';
      patientName = '$firstName $lastName'.trim();
    }

    final scheduleData = {
      'scheduleId': scheduleId, // Use the passed scheduleId
      'date': timestamp,
      'patientId': patientId,
      'patientName': patientName,
    };

    try {
      final String? collection = await getTargetUserRole(caregiverId);
      if (collection == null) {
        throw Exception('User role not found for caregiver.');
      }

      final caregiverSchedulesRef = FirebaseFirestore.instance
          .collection(collection)
          .doc(caregiverId)
          .collection('schedules')
          .doc(patientId);

      final patientScheduleDoc = await caregiverSchedulesRef.get();

      if (patientScheduleDoc.exists) {
        await caregiverSchedulesRef.update({
          'schedules': FieldValue.arrayUnion([scheduleData]),
        });
      } else {
        await caregiverSchedulesRef.set({
          'schedules': [scheduleData],
        });
      }
    } catch (e) {
      throw Exception('Failed to save schedule for caregiver: $e');
    }
  }

  Future<void> saveScheduleForPatient(
    String patientId,
    DateTime scheduledDateTime,
    String caregiverId,
    String scheduleId, // Add scheduleId parameter
  ) async {
    final Timestamp timestamp = Timestamp.fromDate(scheduledDateTime);

    // Fetch caregiver name
    final String? userRole = await getTargetUserRole(caregiverId);
    final caregiverSnapshot =
        await FirebaseFirestore.instance
            .collection(userRole!)
            .doc(caregiverId)
            .get();

    String caregiverName = '';
    if (caregiverSnapshot.exists) {
      final data = caregiverSnapshot.data()!;
      final firstName = data['firstName']?.trim() ?? '';
      final lastName = data['lastName']?.trim() ?? '';
      caregiverName = '$firstName $lastName'.trim();
    }

    final scheduleData = {
      'scheduleId': scheduleId, // Use the passed scheduleId
      'date': timestamp,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
    };

    try {
      final patientSchedulesRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(patientId)
          .collection('schedules')
          .doc(caregiverId);

      final caregiverScheduleDoc = await patientSchedulesRef.get();

      if (caregiverScheduleDoc.exists) {
        await patientSchedulesRef.update({
          'schedules': FieldValue.arrayUnion([scheduleData]),
        });
      } else {
        await patientSchedulesRef.set({
          'schedules': [scheduleData],
        });
      }
    } catch (e) {
      throw Exception('Failed to save schedule for patient: $e');
    }
  }

  Future<void> removePastSchedules(String userId) async {
    debugPrint("Removing past schedules for userId: $userId");

    try {
      // Get current UTC time
      DateTime nowUtc = DateTime.now();
      debugPrint('Current UTC time: $nowUtc');

      // Get user role and collection path
      final String? collection = await getTargetUserRole(userId);
      if (collection == null) {
        debugPrint('User role not found for userId: $userId');
        return;
      }

      debugPrint("remove past schedules collection: $collection");

      // Fetch all caregiver documents in the user's schedules collection
      final QuerySnapshot userSchedulesSnapshot =
          await FirebaseFirestore.instance
              .collection(collection)
              .doc(userId)
              .collection('schedules')
              .get();

      debugPrint(
        "Schedules snapshot contains ${userSchedulesSnapshot.docs.length} documents.",
      );

      if (userSchedulesSnapshot.docs.isEmpty) {
        debugPrint('No schedules found for userId: $userId');
        return;
      }

      // Iterate through caregiver documents
      for (QueryDocumentSnapshot caregiverDoc in userSchedulesSnapshot.docs) {
        final String caregiverId = caregiverDoc.id;
        debugPrint("Processing caregiver document ID: $caregiverId");

        // Retrieve the schedules array from the document
        final Map<String, dynamic>? caregiverData =
            caregiverDoc.data() as Map<String, dynamic>?;
        if (caregiverData == null || !caregiverData.containsKey('schedules')) {
          debugPrint("No schedules array found for caregiver $caregiverId.");
          continue;
        }

        List<Map<String, dynamic>> schedules = List<Map<String, dynamic>>.from(
          caregiverData['schedules'],
        );
        debugPrint('Original schedules for caregiver $caregiverId: $schedules');

        List<Map<String, dynamic>> schedulesToKeep = [];
        List<String> removedScheduleIds = [];

        // Filter schedules: Keep future schedules, collect IDs of past schedules
        for (var schedule in schedules) {
          final Timestamp? scheduleTimestamp = schedule['date'] as Timestamp?;
          if (scheduleTimestamp != null) {
            final DateTime scheduleDateTime = scheduleTimestamp.toDate();
            if (scheduleDateTime.isBefore(nowUtc)) {
              debugPrint('Schedule is in the past: ${schedule['scheduleId']}');
              removedScheduleIds.add(schedule['scheduleId']);
            } else {
              schedulesToKeep.add(schedule); // Keep future schedules
            }
          } else {
            debugPrint('Schedule has a null date: $schedule');
            schedulesToKeep.add(schedule); // Keep schedules with null dates
          }
        }

        debugPrint(
          'Schedules to keep for caregiver $caregiverId: $schedulesToKeep',
        );
        debugPrint(
          'Removed schedule IDs for caregiver $caregiverId: $removedScheduleIds',
        );

        // Update the caregiver document with the filtered schedules
        await caregiverDoc.reference.update({'schedules': schedulesToKeep});
        debugPrint('Updated schedules for caregiver $caregiverId');
      }

      debugPrint('Completed removing past schedules for userId: $userId');
    } catch (e) {
      debugPrint('Error while removing past schedules for userId $userId: $e');
    }
  }

  Future<void> addContact(
    String userId,
    String category,
    Map<String, dynamic> contactData,
  ) async {
    debugPrint("Add Contact function userid: $userId");

    final userDocRef = FirebaseFirestore.instance
        .collection('patient')
        .doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDocRef);
      if (!snapshot.exists) {
        throw Exception("User document does not exist");
      }

      // Get the current contacts or initialize them if not present
      Map<String, dynamic> contacts = Map<String, dynamic>.from(
        snapshot.data()?['contacts'] ?? {'relative': [], 'nurse': []},
      );

      // Ensure the category exists as a list
      if (contacts[category] == null) {
        contacts[category] = [];
      }

      // Add the new contact to the specified category
      (contacts[category] as List).add(contactData);

      // Update the document with the updated contacts
      transaction.update(userDocRef, {'contacts': contacts});
    });
  }

  Future<void> editContact(
    String userId,
    String previousCategory,
    Map<String, dynamic> updatedContact,
    String oldPhoneNumber,
  ) async {
    debugPrint(
      "Edit Contact: userId: $userId, previousCategory: $previousCategory, oldPhoneNumber: $oldPhoneNumber",
    );

    final userDocRef = FirebaseFirestore.instance
        .collection('patient')
        .doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDocRef);
      if (!snapshot.exists) {
        throw Exception("User document does not exist.");
      }

      Map<String, dynamic> contacts = Map<String, dynamic>.from(
        snapshot.data()?['contacts'] ?? {'relative': [], 'nurse': []},
      );

      // Ensure categories are initialized
      if (contacts[previousCategory] == null) {
        contacts[previousCategory] = [];
      }
      if (contacts[updatedContact['category']] == null) {
        contacts[updatedContact['category']] = [];
      }

      // Remove the contact from the previous category
      final previousContactList = List<Map<String, dynamic>>.from(
        contacts[previousCategory],
      );
      final contactIndex = previousContactList.indexWhere(
        (contact) =>
            contact['number'] != null && contact['number'] == oldPhoneNumber,
      );

      if (contactIndex != -1) {
        debugPrint(
          "Removing contact from previous category: $previousCategory",
        );
        previousContactList.removeAt(contactIndex);
        contacts[previousCategory] = previousContactList;
      } else {
        throw Exception(
          "Contact not found in previous category: $previousCategory.",
        );
      }

      // Add the updated contact to the new category
      final updatedCategory = updatedContact['category'];
      final updatedContactList = List<Map<String, dynamic>>.from(
        contacts[updatedCategory],
      );
      debugPrint("Adding contact to new category: $updatedCategory");
      updatedContactList.add(updatedContact);
      contacts[updatedCategory] = updatedContactList;

      // Update the document with the modified contacts
      transaction.update(userDocRef, {'contacts': contacts});
    });

    debugPrint("Contact successfully updated and moved to new category.");
  }

  Future<void> deleteContact(
    String userId,
    String category,
    String phoneNumberToDelete,
  ) async {
    debugPrint(
      "Delete Contact: userId: $userId, category: $category, phoneNumberToDelete: $phoneNumberToDelete",
    );

    final userDocRef = FirebaseFirestore.instance
        .collection('patient')
        .doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDocRef);
      if (!snapshot.exists) {
        throw Exception("User document does not exist.");
      }

      Map<String, dynamic> contacts = Map<String, dynamic>.from(
        snapshot.data()?['contacts'] ?? {'relative': [], 'nurse': []},
      );

      if (contacts[category] == null) {
        contacts[category] = [];
      }

      final contactList = List<Map<String, dynamic>>.from(contacts[category]);
      final updatedContactList =
          contactList.where((contact) {
            return contact['number'] != null &&
                contact['number'] != phoneNumberToDelete;
          }).toList();

      if (contactList.length == updatedContactList.length) {
        throw Exception(
          "Contact with phone number $phoneNumberToDelete not found in category: $category.",
        );
      }

      contacts[category] = updatedContactList;

      transaction.update(userDocRef, {'contacts': contacts});
    });

    debugPrint("Contact successfully deleted.");
  }

  // Check if the user exists by UID
  Future<bool> checkUserExists(String userId) async {
    try {
      if (userId.isEmpty) {
        debugPrint('Invalid userId: Cannot be empty');
        return false;
      }

      // Get the user role using the helper function
      final userRole = await getTargetUserRole(userId);
      if (userRole == null) {
        debugPrint('Could not determine user role for userId: $userId');
        return false;
      }

      debugPrint('Checking existence for userId: $userId in role: $userRole');

      // Fetch the user document
      final userDoc =
          await FirebaseFirestore.instance
              .collection(userRole)
              .doc(userId)
              .get();

      final exists = userDoc.exists;
      debugPrint('User existence for userId $userId in $userRole: $exists');
      return exists;
    } catch (e, stackTrace) {
      debugPrint('Error checking user existence for userId $userId: $e');
      debugPrint('Stack trace: $stackTrace');
      return false; // Assume the user doesn't exist if an error occurs
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
      var userDoc =
          await FirebaseFirestore.instance
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

  Future<String> getUserName(String userId, UserRole userRole) async {
    try {
      final userCollection = getCollectionForRole(userRole);
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
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
      // Check for empty phone number
      if (phoneNumber.isEmpty) {
        debugPrint('Invalid phoneNumber: Cannot be empty');
        return false;
      }

      debugPrint('Checking uniqueness of phoneNumber: $phoneNumber');

      // Ensure the current user is logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('No user is currently signed in.');
        return false;
      }

      final String uid = currentUser.uid;

      // Get the current user's role
      final String? userRole = await getTargetUserRole(uid);
      if (userRole == null) {
        debugPrint('Could not determine user role for current user');
        return false;
      }

      // Query the user's role collection for the phone number
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection(userRole)
              .where('phoneNumber', isEqualTo: phoneNumber)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Ensure the phone number doesn't belong to the current user
        final isCurrentUser = querySnapshot.docs.any((doc) => doc.id == uid);

        if (!isCurrentUser) {
          debugPrint('Phone number $phoneNumber already exists in $userRole');
          return false; // Phone number is not unique
        }
      }

      debugPrint('Phone number $phoneNumber is unique in $userRole');
      return true; // Phone number is unique
    } catch (e, stackTrace) {
      debugPrint('Error checking phone number uniqueness: $e');
      debugPrint('Stack trace: $stackTrace');
      return false; // Assume not unique in case of error
    }
  }

  Future<List<String>> fetchSymptoms(String userId, UserRole userRole) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('patient')
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
    return FirebaseFirestore.instance
        .collection(collection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserData.fromDocument(doc)).toList(),
        );
  }

  Stream<List<UserData>> get patients {
    return FirebaseFirestore.instance
        .collection(
          'patient',
        ) // Replace 'patients' with your actual collection name
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserData.fromDocument(doc))
              .toList();
        });
  }

  Future<UserData?> getUserDataById(String uid) async {
    try {
      // Attempt to determine the user's role using getTargetUserRole
      final String? userRole = await getTargetUserRole(uid);

      if (userRole == null) {
        debugPrint('Unable to determine role for user with UID: $uid');
        return null;
      }

      // Query the user's document in the determined role-based collection
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection(userRole).doc(uid).get();

      if (userDoc.exists) {
        debugPrint('User with UID $uid found in the $userRole collection.');
        return UserData.fromDocument(userDoc);
      }

      debugPrint('User with UID $uid not found in the $userRole collection.');
      return null; // User not found in the determined collection
    } catch (e, stackTrace) {
      debugPrint('Error fetching user data for UID $uid: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<PatientData?> getPatientData(String patientId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(patientId)
              .get();

      if (doc.exists) {
        debugPrint('Document found for patientId: $patientId');
        return PatientData.fromDocument(doc);
      } else {
        debugPrint('No document exists for patientId: $patientId');
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching patient data for Patient ID $patientId: $e");
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
    String? address,
    String? will,
    String? fixedWishes,
    String? organDonation,
    String? profileImageUrl,
    DateTime? birthday,
    String? caseTitle,
    String? caseDescription,
    String? status,
  }) async {
    try {
      // Get the appropriate collection for the user role
      final collectionName = getCollectionForRole(UserRole.patient);

      // Get the Firestore reference
      final collectionRef = FirebaseFirestore.instance.collection(
        collectionName,
      );

      // Prepare the data map
      Map<String, dynamic> updatedData = {};

      // Add userRole
      updatedData['userRole'] = 'patient';

      // Add patient details to the map
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
      if (address?.isNotEmpty ?? false) updatedData['address'] = address;

      // Add case-related data
      if (caseTitle?.isNotEmpty ?? false) updatedData['caseTitle'] = caseTitle;
      if (caseDescription?.isNotEmpty ?? false) {
        updatedData['caseDescription'] = caseDescription;
      }
      if (status?.isNotEmpty ?? false) updatedData['status'] = status;

      // Perform the update only if there's data to update
      if (updatedData.isNotEmpty) {
        await collectionRef.doc(uid).set(updatedData, SetOptions(merge: true));
        print("Patient data added successfully in collection: $collectionName");
      } else {
        print("No data provided to add patient.");
      }
    } catch (e) {
      print("Error adding patient data: $e");
      throw Exception("Failed to add patient data");
    }
  }
}
