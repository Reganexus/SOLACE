// ignore_for_file: avoid_print

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
    DateTime? birthday,
    String? gender,
    String? address,
    String? profileImageUrl, // Add this parameter for profile image URL
    bool? isVerified,
    bool? newUser, // New field for update
    DateTime? dateCreated, // New field for update
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
    if (birthday != null) {
      updatedData['birthday'] = Timestamp.fromDate(birthday);
    }
    if (gender != null) updatedData['gender'] = gender;
    if (address != null) updatedData['address'] = address;
    if (profileImageUrl != null) {
      updatedData['profileImageUrl'] = profileImageUrl;
    } else {
      updatedData['profileImageUrl'] = ''; // Default to empty string if no image URL is provided
    }

    if (isVerified != null) {
      updatedData['isVerified'] = isVerified;
    }
    if (newUser != null) {
      updatedData['newUser'] = newUser; // Include newUser in the update
    }
    if (dateCreated != null) {
      updatedData['dateCreated'] = Timestamp.fromDate(dateCreated); // Add dateCreated
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

  // Fetch the user role by userId
  Stream<List<UserData>> getUsersByRole(String role) {
    return userCollection
        .where('userRole', isEqualTo: role) // Use 'userRole' instead of 'role'
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserData.fromDocument(
              doc)) // Convert Firestore document to UserData
          .toList();
    });
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    try {
      await userCollection.doc(uid).update({
        'userRole': UserData.getUserRoleString(
            role), // Convert role to string for Firestore
      });
    } catch (e) {
      print('Error updating user role: $e');
      rethrow; // Handle error as needed
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // 1. Delete the Firestore user document
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      print("User document deleted from Firestore.");

      // 2. Delete records in the 'tracking' collection related to the user
      await FirebaseFirestore.instance
          .collection('tracking')
          .where('userId', isEqualTo: userId)
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.delete(); // Deleting each document related to the user
        }
        print("User tracking records deleted from Firestore.");
      });

      // 3. Delete the user from Firebase Authentication
      User? user = FirebaseAuth.instance.currentUser;

      // Ensure we are deleting the correct user (the one who is logged in or the user specified)
      if (user != null && user.uid == userId) {
        // Re-authenticate if necessary, or delete directly if the current user is the one requesting deletion
        await user.delete();
        print(
            "User account deleted successfully from Firebase Authentication.");
      } else {
        print(
            "User is not the authenticated user or the user is not logged in.");
      }
    } catch (e) {
      print("Error deleting user: $e");
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
      print("Fetching data for UID: $uid");
      DocumentSnapshot snapshot = await userCollection.doc(uid).get();

      if (snapshot.exists) {
        return UserData.fromDocument(snapshot);
      } else {
        print("No document found for UID: $uid");
        return null; // Handle missing document case
      }
    } catch (e) {
      print('Error fetching user data for UID $uid: $e');
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

  static Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures') // Profile pictures folder
          .child('$userId.jpg'); // User-specific filename

      final uploadTask = storageRef.putFile(file);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl; // Return the download URL of the uploaded file
    } catch (e) {
      throw Exception("Error uploading profile image: $e");
    }
  }



  Future<void> saveScheduleForCaregiver(
      String caregiverId, DateTime scheduledDateTime, String patientId) async {
    final Timestamp timestamp = Timestamp.fromDate(scheduledDateTime);

    // Fetch patient name
    final patientSnapshot = await FirebaseFirestore.instance
        .collection('users')
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

    // Save schedule for caregiver
    await FirebaseFirestore.instance
        .collection('users')
        .doc(caregiverId)
        .update({
      'schedule': FieldValue.arrayUnion([
        {
          'date': timestamp,
          'time': DateFormat.jm().format(scheduledDateTime),
          'patientId': patientId,
        }
      ]),
    });

    // Add schedule notification for caregiver
    await addNotification(
      caregiverId,
      "Scheduled visit for patient $patientName at $formattedDateTime",
      'schedule',
    );
  }

  Future<void> saveScheduleForPatient(
      String patientId, DateTime scheduledDateTime, String caregiverId) async {
    final Timestamp timestamp = Timestamp.fromDate(scheduledDateTime);

    // Fetch caregiver name
    final caregiverSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(caregiverId)
        .get();
    String caregiverName = '';
    if (caregiverSnapshot.exists) {
      caregiverName = caregiverSnapshot.data()?['firstName']?.trim() ?? '';
      String lastName = caregiverSnapshot.data()?['lastName']?.trim() ?? '';
      caregiverName = '$caregiverName $lastName'.trim();
    }

    // Format date and time
    String formattedDateTime =
        DateFormat('MMMM dd, yyyy h:mm a').format(scheduledDateTime);

    // Save schedule for patient
    await FirebaseFirestore.instance.collection('users').doc(patientId).update({
      'schedule': FieldValue.arrayUnion([
        {
          'date': timestamp,
          'time': DateFormat.jm().format(scheduledDateTime),
          'caregiverId': caregiverId,
        }
      ]),
    });

    // Add schedule notification for patient
    await addNotification(
      patientId,
      "Scheduled appointment with caregiver $caregiverName at $formattedDateTime.",
      'schedule',
    );
  }

// Function to add a notification for the user, with the correct timestamp
  Future<void> addNotification(
      String userId, String notificationMessage, String type) async {
    final timestamp = Timestamp.now();
    final notificationId = DateTime.now()
        .millisecondsSinceEpoch
        .toString(); // Generate a unique ID

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'notifications': FieldValue.arrayUnion([
          {
            'notificationId': notificationId, // Unique ID for the notification
            'message': notificationMessage,
            'timestamp': timestamp,
            'type': type,
            'read': false, // Default to unread
          }
        ]),
      });
    } catch (e) {
      print('Error adding notification: $e');
    }
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

  // Send a friend request
  Future<void> sendFriendRequest(
      String currentUserId, String targetUserId) async {
    final timestamp = FieldValue.serverTimestamp();

    try {
      await userCollection.doc(targetUserId).update({
        'contacts.requests.$currentUserId': {'timestamp': timestamp}
      });
      print('Friend request sent from $currentUserId to $targetUserId');
    } catch (e) {
      print('Error sending friend request: $e');
    }
  }

  // Accept a friend request
  Future<void> acceptFriendRequest(
      String currentUserId, String senderUserId) async {
    final timestamp = FieldValue.serverTimestamp();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRef = userCollection.doc(currentUserId);
        final senderRef = userCollection.doc(senderUserId);

        // Remove request from the current user's requests and add to friends
        transaction.update(userRef, {
          'contacts.requests.$senderUserId': FieldValue.delete(),
          'contacts.friends.$senderUserId': {'timestamp': timestamp}
        });

        // Add current user to sender's friends list
        transaction.update(senderRef, {
          'contacts.friends.$currentUserId': {'timestamp': timestamp}
        });
      });

      print('Accepted friend request from $senderUserId for $currentUserId');
    } catch (e) {
      print('Error accepting friend request: $e');
    }
  }

  // Decline a friend request
  Future<void> declineFriendRequest(
      String currentUserId, String senderUserId) async {
    try {
      await userCollection
          .doc(currentUserId)
          .update({'contacts.requests.$senderUserId': FieldValue.delete()});
      print('Declined friend request from $senderUserId for $currentUserId');
    } catch (e) {
      print('Error declining friend request: $e');
    }
  }

  // Remove a friend
  Future<void> removeFriend(String currentUserId, String friendUserId) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRef = userCollection.doc(currentUserId);
        final friendRef = userCollection.doc(friendUserId);

        // Remove friend from current user's friends list
        transaction.update(
            userRef, {'contacts.friends.$friendUserId': FieldValue.delete()});

        // Remove current user from friend's friends list
        transaction.update(friendRef,
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
      var userDoc = await userCollection.doc(userId).get();
      return userDoc.exists;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // Check if the user is already a friend
  Future<bool> isUserFriend(String currentUserId, String targetUserId) async {
    try {
      var userDoc = await userCollection.doc(currentUserId).get();
      var friends = userDoc['contacts']['friends'];
      return friends.containsKey(targetUserId);
    } catch (e) {
      print('Error checking if user is a friend: $e');
      return false;
    }
  }

  // Check if the user already has a pending friend request
  Future<bool> hasPendingRequest(
      String currentUserId, String targetUserId) async {
    try {
      var userDoc = await userCollection.doc(currentUserId).get();
      var requests = userDoc['contacts']['requests'];
      return requests.containsKey(targetUserId);
    } catch (e) {
      print('Error checking for pending request: $e');
      return false;
    }
  }

  Future<String> getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await userCollection.doc(userId).get();

      if (userDoc.exists) {
        // Concatenate firstName, middleName, and lastName to form the full name
        String firstName = userDoc['firstName'] ?? '';
        String middleName = userDoc['middleName'] ?? '';
        String lastName = userDoc['lastName'] ?? '';

        // Combine parts, ensuring there's a space between them if not empty
        String fullName =
            '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName';

        // Trim leading and trailing spaces
        return fullName.trim().isEmpty ? 'Unknown' : fullName.trim();
      } else {
        throw Exception("User not found");
      }
    } catch (e) {
      print("Error getting user name: $e");
      return 'Error'; // Return 'Error' if there's an exception
    }
  }
}
