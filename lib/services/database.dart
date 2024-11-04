// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solace/models/my_user.dart';

class DatabaseService {
  final String? uid;

  DatabaseService({this.uid});

  // Collection reference
  final CollectionReference userCollection =
  FirebaseFirestore.instance.collection('users');

  // Stream to get all patients
  Stream<List<UserData>> get patients {
    return userCollection
        .where('userRole', isEqualTo: 'patient')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      // Attach document ID to UserData
      final userData = UserData.fromDocument(doc);
      return userData;
    }).toList());
  }

  // Update user data in Firestore
  Future<void> updateUserData({
    UserRole? userRole,
    String? email,
    String? lastName,
    String? firstName,
    String? middleName,
    String? phoneNumber,
    DateTime? birthday, // Add birthday here
    String? gender,
    String? address,
    bool? isVerified, // New field for verification status
  }) async {
    Map<String, dynamic> updatedData = {};

    if (userRole != null) {
      updatedData['userRole'] = UserData.getUserRoleString(userRole);
    }
    if (email != null) updatedData['email'] = email;
    if (lastName != null) updatedData['lastName'] = lastName;
    if (firstName != null) updatedData['firstName'] = firstName;
    if (middleName != null) updatedData['middleName'] = middleName;
    if (phoneNumber != null) updatedData['phoneNumber'] = phoneNumber;
    if (birthday != null) updatedData['birthday'] = Timestamp.fromDate(birthday);
    if (gender != null) updatedData['gender'] = gender;
    if (address != null) updatedData['address'] = address;
    if (isVerified != null) updatedData['isVerified'] = isVerified; // Add to updated data

    if (updatedData.isNotEmpty) {
      await userCollection.doc(uid).set(updatedData, SetOptions(merge: true));
    }
  }

  Future<void> setUserVerificationStatus(String uid, bool isVerified) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isVerified': isVerified,
      });
      debugPrint('User verification status updated to $isVerified for user $uid');
    } catch (e) {
      debugPrint("Error updating user verification status: ${e.toString()}");
    }
  }

  // Fetch user data by email
  Future<UserData?> getUserDataByEmail(String email) async {
    try {
      QuerySnapshot querySnapshot = await userCollection
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

  // Method to add a vital record
  Future<void> addVitalRecord(String vital, double inputRecord) async {
    if (uid != null) {
      print('To add vital inside: $uid');
      DocumentReference docRef = userCollection
          .doc(uid)
          .collection('vitals')
          .doc(vital);

      CollectionReference recordsRef = docRef.collection('records');

      await recordsRef.add({
        'timestamp': FieldValue.serverTimestamp(),
        'value': inputRecord,
      });

      print('Added vital: $uid');
    } else {
      print('User ID is null. Cannot add vital record.');
    }
    print('Add vital: $vital $inputRecord');
  }

  // Fetch user data from Firestore
  Future<UserData?> getUserData() async {
    try {
      DocumentSnapshot snapshot = await userCollection.doc(uid).get();
      if (snapshot.exists) {
        return UserData.fromDocument(snapshot);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Stream of user list data
  Stream<List<UserData>> get users {
    return userCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserData.fromDocument(doc)).toList();
    });
  }

  // Stream to get user data
  Stream<UserData?>? get userData {
    print('Get userdata: $uid');
    return userCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserData.fromDocument(snapshot);
      } else {
        return null;
      }
    });
  }

  Future<void> saveScheduleForCaregiver(String caregiverId, DateTime scheduledDateTime, String patientId) async {
    // Convert DateTime to Timestamp for Firestore
    final Timestamp timestamp = Timestamp.fromDate(scheduledDateTime);

    await FirebaseFirestore.instance.collection('users').doc(caregiverId).update({
      'schedule': FieldValue.arrayUnion([
        {
          'date': timestamp,
          'time': DateFormat.jm().format(scheduledDateTime), // Format time for display
          'patientId': patientId,
        }
      ]),
    });
  }

  Future<void> saveScheduleForPatient(String patientId, DateTime scheduledDateTime, String caregiverId) async {
    // Convert DateTime to Timestamp for Firestore
    final Timestamp timestamp = Timestamp.fromDate(scheduledDateTime);

    await FirebaseFirestore.instance.collection('users').doc(patientId).update({
      'schedule': FieldValue.arrayUnion([
        {
          'date': timestamp,
          'time': DateFormat.jm().format(scheduledDateTime), // Format time for display
          'caregiverId': caregiverId,
        }
      ]),
    });
  }


  // Fetch the schedule for a user
  Future<List<Map<String, dynamic>>> getScheduleForUser(String userId) async {
    try {
      DocumentSnapshot snapshot = await userCollection.doc(userId).get();
      if (snapshot.exists) {
        return List<Map<String, dynamic>>.from(snapshot.get('schedule') ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching schedule: $e');
      return [];
    }
  }
}
