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

  Future<bool> checkUserExists() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.exists;
  }

  // Update user data in Firestore
  Future<void> updateUserData({
    UserRole? userRole,
    String? email,
    String? lastName,
    String? firstName,
    String? middleName,
    String? phoneNumber,
    DateTime? birthday,
    String? gender,
    String? address,
    bool? isVerified,
  }) async {
    Map<String, dynamic> updatedData = {};

    if (userRole != null) {
      updatedData['userRole'] = UserData.getUserRoleString(
          userRole); // This should convert the UserRole enum to string
    }
    if (email != null) updatedData['email'] = email;
    if (lastName != null) updatedData['lastName'] = lastName;
    if (firstName != null) updatedData['firstName'] = firstName;
    if (middleName != null) updatedData['middleName'] = middleName;
    if (phoneNumber != null) updatedData['phoneNumber'] = phoneNumber;
    if (birthday != null) {
      updatedData['birthday'] = Timestamp.fromDate(birthday);
    }
    if (gender != null) updatedData['gender'] = gender;
    if (address != null) updatedData['address'] = address;
    if (isVerified != null) {
      updatedData['isVerified'] = isVerified; // Add to updated data
    }

    if (updatedData.isNotEmpty) {
      await userCollection.doc(uid).set(updatedData, SetOptions(merge: true));
    }
  }

  Future<void> setUserVerificationStatus(String uid, bool isVerified) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isVerified': isVerified,
      });
      debugPrint(
          'User verification status updated to $isVerified for user $uid');
    } catch (e) {
      debugPrint("Error updating user verification status: ${e.toString()}");
    }
  }

  // Fetch user data by email
  Future<UserData?> getUserDataByEmail(String email) async {
    try {
      QuerySnapshot querySnapshot =
          await userCollection.where('email', isEqualTo: email).get();

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
      DocumentReference docRef =
          userCollection.doc(uid).collection('vitals').doc(vital);

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

  Future<void> saveScheduleForCaregiver(
      String caregiverId, DateTime scheduledDateTime, String patientId) async {
    // Convert DateTime to Timestamp for Firestore
    final Timestamp timestamp = Timestamp.fromDate(scheduledDateTime);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(caregiverId)
        .update({
      'schedule': FieldValue.arrayUnion([
        {
          'date': timestamp,
          'time': DateFormat.jm()
              .format(scheduledDateTime), // Format time for display
          'patientId': patientId,
        }
      ]),
    });
  }

  Future<void> saveScheduleForPatient(
      String patientId, DateTime scheduledDateTime, String caregiverId) async {
    // Convert DateTime to Timestamp for Firestore
    final Timestamp timestamp = Timestamp.fromDate(scheduledDateTime);

    await FirebaseFirestore.instance.collection('users').doc(patientId).update({
      'schedule': FieldValue.arrayUnion([
        {
          'date': timestamp,
          'time': DateFormat.jm()
              .format(scheduledDateTime), // Format time for display
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

  Future<void> sendFriendRequest(
      String currentUserId, String targetUserId) async {
    var currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    var targetUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .get();

    // If the contacts field is null, initialize it for the current user
    if (currentUserDoc.exists) {
      var currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      if (currentUserData['contacts'] == null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'contacts': {
            'friends': [],
            'pending': [],
            'requests': [],
          },
        });
      }
    }

    // If the contacts field is null, initialize it for the target user
    if (targetUserDoc.exists) {
      var targetUserData = targetUserDoc.data() as Map<String, dynamic>;
      if (targetUserData['contacts'] == null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .update({
          'contacts': {
            'friends': [],
            'pending': [],
            'requests': [],
          },
        });
      }
    }

    // Check if a request has already been sent from the current user to the target user
    var currentUserPending =
        currentUserDoc.data()?['contacts']['pending'] ?? [];
    var targetUserRequests =
        targetUserDoc.data()?['contacts']['requests'] ?? [];

    bool alreadySent =
        currentUserPending.any((item) => item['userId'] == targetUserId);
    bool alreadyRequested =
        targetUserRequests.any((item) => item['userId'] == currentUserId);

    if (alreadySent || alreadyRequested) {
      throw Exception("Friend request already sent or received.");
    }

    // Proceed with sending the friend request to the target user
    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .update({
      'contacts.requests': FieldValue.arrayUnion([
        {
          'userId': currentUserId,
          'dateRequested': Timestamp.now(),
        }
      ])
    });

    // Add the request to the requestor's pending list
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({
      'contacts.pending': FieldValue.arrayUnion([
        {
          'userId': targetUserId,
          'dateSent': Timestamp.now(),
        }
      ])
    });
  }

  Future<void> acceptFriendRequest(
      String currentUserId, String requestorUserId) async {
    // Remove the request from the current user and add the friend to their list
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({
      'contacts.requests': FieldValue.arrayRemove([
        {'userId': requestorUserId}
      ]),
      'contacts.friends': FieldValue.arrayUnion([
        {'userId': requestorUserId, 'dateAdded': Timestamp.now()}
      ]),
    });

    // Remove the user from the pending list in the requestor's document and add as friend
    await FirebaseFirestore.instance
        .collection('users')
        .doc(requestorUserId)
        .update({
      'contacts.pending': FieldValue.arrayRemove([
        {'userId': currentUserId}
      ]),
      'contacts.friends': FieldValue.arrayUnion([
        {'userId': currentUserId, 'dateAdded': Timestamp.now()}
      ]),
    });
  }

  Future<void> rejectFriendRequest(
      String currentUserId, String requestorUserId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Using a transaction to ensure both updates happen atomically
    await firestore.runTransaction((transaction) async {
      // Step 1: Get the current user's document
      DocumentReference currentUserRef = firestore.collection('users').doc(currentUserId);
      DocumentSnapshot currentUserSnapshot = await transaction.get(currentUserRef);

      // Step 2: Get the requester's document
      DocumentReference requestorUserRef = firestore.collection('users').doc(requestorUserId);
      DocumentSnapshot requestorUserSnapshot = await transaction.get(requestorUserRef);

      // Ensure both users' data exists
      if (currentUserSnapshot.exists && requestorUserSnapshot.exists) {
        // Get the current user's requests and the requester's pending
        var currentUserData = currentUserSnapshot.data() as Map<String, dynamic>;
        var requestorUserData = requestorUserSnapshot.data() as Map<String, dynamic>;

        var currentUserRequests = List<Map<String, dynamic>>.from(currentUserData['contacts']['requests'] ?? []);
        var requestorUserPending = List<Map<String, dynamic>>.from(requestorUserData['contacts']['pending'] ?? []);

        // Remove the request from the current user's requests
        currentUserRequests.removeWhere((request) => request['userId'] == requestorUserId);

        // Remove the current user from the requestor's pending list
        requestorUserPending.removeWhere((pending) => pending['userId'] == currentUserId);

        // Step 3: Update both users' contacts in Firestore
        transaction.update(currentUserRef, {
          'contacts.requests': currentUserRequests,
        });

        transaction.update(requestorUserRef, {
          'contacts.pending': requestorUserPending,
        });
      }
    });
  }

  Future<void> removeFriend(String currentUserId, String friendUserId) async {
    // First, get the current user data to access the friend list
    var currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    var currentUserData = currentUserDoc.data();

    // Get the friend data from the current user's 'friends' list
    var friendData = currentUserData?['contacts']['friends'] ?? [];

    // Find the friend object to remove from the list (the one with the friendUserId)
    var friendToRemove = friendData.firstWhere(
      (friend) => friend['userId'] == friendUserId,
      orElse: () => null,
    );

    if (friendToRemove != null) {
      // Remove the friend from the current user's friends list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'contacts.friends': FieldValue.arrayRemove([friendToRemove]),
      });

      // Remove the current user from the friend's list (unfriending the other person)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUserId)
          .update({
        'contacts.friends': FieldValue.arrayRemove([
          {
            'userId': currentUserId,
            'dateAdded': friendToRemove[
                'dateAdded'] // Make sure to include the dateAdded field
          }
        ]),
      });
    }
  }
}
