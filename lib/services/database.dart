// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps, unreachable_switch_default

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:solace/models/my_patient.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  DatabaseService({this.uid});
  final String? uid;
  final LogService _logService = LogService();

  static Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Error uploading profile image: $e");
    }
  }

  Future<void> clearUserRoleCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith('userRole_')) {
        await prefs.remove(key);
        debugPrint("Cleared cached role for: $key");
      }
    }
    debugPrint("All user role cache cleared.");
  }

  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // This clears all SharedPreferences data
    debugPrint("All cache cleared.");
  }

  Future<void> cacheUserRole(String userId, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole_$userId', role);
    debugPrint("Cached role updated to: $role for userId: $userId");
  }

  Future<void> cacheFormData({
    required String userId,
    required String firstName,
    required String middleName,
    required String lastName,
    required String birthday,
    required String phoneNumber,
    required String gender,
    required String religion,
    required String address,
    required String imagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('imagePath_$userId', imagePath);
    await prefs.setString('firstName_$userId', firstName);
    await prefs.setString('middleName_$userId', middleName);
    await prefs.setString('lastName_$userId', lastName);
    await prefs.setString('phoneNumber_$userId', phoneNumber);
    await prefs.setString('birthday_$userId', birthday);
    await prefs.setString('gender_$userId', gender);
    await prefs.setString('religion_$userId', religion);
    await prefs.setString('address_$userId', address);
    if (imagePath != null) {
      await prefs.setString('imagePath_$userId', imagePath);
    }
    debugPrint("Form data cached for userId: $userId");
  }

  Future<void> clearFormCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('imagePath_$userId');
    await prefs.remove('firstName_$userId');
    await prefs.remove('middleName_$userId');
    await prefs.remove('lastName_$userId');
    await prefs.remove('phoneNumber_$userId');
    await prefs.remove('birthday_$userId');
    await prefs.remove('gender_$userId');
    await prefs.remove('religion_$userId');
    await prefs.remove('address_$userId');

    debugPrint("Form cache cleared for userId: $userId");
  }

  Future<void> cacheTrackingData({
    required String userId,
    required Map<String, String> vitalInputs,
    required Map<String, int> symptomValues,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Cache vital inputs
    vitalInputs.forEach((key, value) async {
      await prefs.setString('${key}_${userId}', value);
    });

    // Cache symptom values (slider values)
    symptomValues.forEach((key, value) async {
      await prefs.setInt('${key}_${userId}', value);
    });

    debugPrint("Form data cached for userId: $userId");
  }

  Future<void> clearTrackingCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (var key in keys) {
      if (key.endsWith('_$userId')) {
        await prefs.remove(key);
      }
    }

    debugPrint("Form cache cleared for userId: $userId");
  }

  Future<Map<String, String>> getVitalInputs(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, String> vitalInputs = {};
    // Assuming you have keys for each vital input (e.g., "Heart Rate", "Temperature", etc.)
    List<String> vitalKeys = [
      'Heart Rate',
      'Systolic',
      'Diastolic',
      'Oxygen Saturation',
      'Respiration',
      'Temperature',
      'Pain',
    ];
    for (var key in vitalKeys) {
      vitalInputs[key] = prefs.getString('${key}_${userId}') ?? '';
    }
    return vitalInputs;
  }

  Future<Map<String, int>> getSymptomValues(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, int> symptomValues = {};
    // List of symptom slider keys (e.g., "Diarrhea", "Constipation", etc.)
    List<String> symptomKeys = [
      'Diarrhea',
      'Constipation',
      'Fatigue',
      'Shortness of Breath',
      'Poor Appetite',
      'Coughing',
      'Nausea',
      'Vomiting',
      'Depression',
      'Anxiety',
      'Confusion',
      'Insomnia',
    ];
    for (var key in symptomKeys) {
      symptomValues[key] = prefs.getInt('${key}_${userId}') ?? 0;
    }
    return symptomValues;
  }

  Future<String?> fetchAndCacheUserRole(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check cached role
      final cachedRole = prefs.getString('userRole_$userId');
      if (cachedRole != null) {
        debugPrint("Returning cached role: $cachedRole for userId: $userId");
        return cachedRole;
      }

      // Retry logic for Firestore reads
      const maxRetries = 3;
      const baseDelay = Duration(milliseconds: 500);

      // Iterate through user role collections
      final collections = UserRoleExtension.allRoles;
      for (final collection in collections) {
        int retries = 0;

        while (retries < maxRetries) {
          try {
            final doc =
                await FirebaseFirestore.instance
                    .collection(collection)
                    .doc(userId)
                    .get();

            if (doc.exists) {
              // Cache the found role
              await prefs.setString('userRole_$userId', collection);
              debugPrint("Cached role: $collection for userId: $userId");
              return collection;
            }
            break; // Exit retry loop if successful
          } catch (e) {
            retries++;
            if (retries >= maxRetries) {
              debugPrint(
                "Failed to fetch role from collection $collection after $retries retries: $e",
              );
            } else {
              await Future.delayed(
                baseDelay * (2 << retries),
              ); // Exponential backoff
            }
          }
        }
      }

      debugPrint("No role found for userId: $userId");
      return null;
    } catch (e) {
      debugPrint("Error fetching and caching user role for $userId: $e");
      return null;
    }
  }

  Future<UserData?> fetchUserData(String userId) async {
    final doc = await fetchUserDocument(userId);
    if (doc == null || !doc.exists) return null;
    return UserData.fromDocument(doc);
  }

  Future<bool> checkUserExists(String userId) async {
    final doc = await fetchUserDocument(userId);
    return doc?.exists ?? false;
  }

  Future<String?> fetchProfileImageUrl(String userId) async {
    final doc = await fetchUserDocument(userId);
    final data = doc?.data() as Map<String, dynamic>?;

    return data?['profileImageUrl'];
  }

  Future<bool> isPhoneNumberUnique(String phoneNumber) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final role = await fetchAndCacheUserRole(currentUser.uid);
      if (role != null) {
        await cacheUserRole(currentUser.uid, role);
      }

      if (role == null) return false;

      final query =
          await FirebaseFirestore.instance
              .collection(role)
              .where('phoneNumber', isEqualTo: phoneNumber)
              .get();

      return query.docs.isEmpty ||
          query.docs.any((doc) => doc.id == currentUser.uid);
    } catch (e) {
      debugPrint("Error checking phone number uniqueness: $e");
      return false;
    }
  }

  Future<String?> fetchUserName(String userId) async {
    final doc = await fetchUserDocument(userId);
    if (doc == null || !doc.exists) return null;

    // Safely cast data() to Map<String, dynamic>
    final data = doc.data() as Map<String, dynamic>?;

    final firstName = data?['firstName'] ?? '';
    final middleName = data?['middleName'] ?? '';
    final lastName = data?['lastName'] ?? '';

    // Construct the full name
    return [
      firstName,
      middleName,
      lastName,
    ].where((name) => name.isNotEmpty).join(' ').trim();
  }

  Future<UserData?> getUserDataByEmail(String email) async {
    try {
      final roles = UserRoleExtension.allRoles;
      for (final role in roles) {
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection(role)
                .where('email', isEqualTo: email)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          return UserData.fromDocument(querySnapshot.docs.first);
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data by email: $e");
    }
    return null;
  }

  Future<bool> isUserFriend(String currentUserId, String targetUserId) async {
    final doc = await fetchUserDocument(currentUserId);

    // Safely cast data() to Map<String, dynamic>
    final data = doc?.data() as Map<String, dynamic>?;

    final friends = data?['contacts']?['friends'] as Map<String, dynamic>?;

    return friends != null && friends.containsKey(targetUserId);
  }

  Stream<UserData?>? get userData {
    if (uid == null) return null;
    return Stream.fromFuture(fetchUserData(uid!));
  }

  Stream<List<UserData>> fetchUsersByRole(UserRole role) {
    return FirebaseFirestore.instance
        .collection(role.name)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserData.fromDocument(doc)).toList(),
        );
  }

  Future<void> addNotification(
    String userId,
    String notificationMessage,
    String type,
  ) async {
    try {
      final role = await fetchAndCacheUserRole(userId);
      if (role == null) throw Exception("User role not found for $userId");
      await cacheUserRole(userId, role);

      final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
      final notificationData = {
        'notificationId': notificationId,
        'message': notificationMessage,
        'timestamp': Timestamp.now(),
        'type': type,
        'read': false,
      };

      await FirebaseFirestore.instance
          .collection(role)
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .set(notificationData);

      debugPrint("Notification added for userId: $userId");
    } catch (e) {
      debugPrint("Error adding notification: $e");
      throw Exception("Failed to add notification.");
    }
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      // Fetch and cache the current role
      final currentRole = await fetchAndCacheUserRole(userId);
      if (currentRole == null) {
        throw Exception("Current role not found for $userId");
      }

      final newRoleName = newRole.name;

      if (currentRole != newRoleName) {
        // Fetch the user document from the current collection
        final doc =
            await FirebaseFirestore.instance
                .collection(currentRole)
                .doc(userId)
                .get();

        if (doc.exists) {
          final data = doc.data();

          // Move the document to the new collection
          await FirebaseFirestore.instance
              .collection(newRoleName)
              .doc(userId)
              .set({...data!, 'userRole': newRoleName});

          // Delete the document from the current collection
          await FirebaseFirestore.instance
              .collection(currentRole)
              .doc(userId)
              .delete();
        }
      } else {
        // Update the user role within the same collection if no move is needed
        await FirebaseFirestore.instance
            .collection(currentRole)
            .doc(userId)
            .update({'userRole': newRoleName});
      }

      // Ensure the role is cached after the update
      debugPrint("Updated user role for $userId to $newRoleName");
    } catch (e) {
      debugPrint("Error updating user role: $e");
      throw Exception("Failed to update user role.");
    }
  }

  Future<void> updateUserData({
    required String uid,
    required String userRole,
    required String firstName,
    required String lastName,
    required String middleName,
    required String phoneNumber,
    required String gender,
    required DateTime? birthday,
    required String address,
    required String profileImageUrl,
    required String religion,
    required bool newUser,
    required bool isVerified,
    required int age,
  }) async {
    try {
      await FirebaseFirestore.instance.collection(userRole).doc(uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'middleName': middleName,
        'phoneNumber': phoneNumber,
        'gender': gender,
        'birthday': birthday != null ? Timestamp.fromDate(birthday) : null,
        'address': address,
        'profileImageUrl': profileImageUrl,
        'religion': religion,
        'newUser': newUser,
        'isVerified': isVerified,
        'age': age,
      });

      await addNotification(uid, "Profile updated successfully.", "update");
    } catch (e) {
      debugPrint('Error updating user data: $e');
      throw Exception('Failed to update user data.');
    }
  }

  Future<void> updateUserVerificationStatus({
    required String uid,
    required UserRole userRole,
    required bool isVerified,
  }) async {
    try {
      final collectionName = userRole.name;
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(uid)
          .update({'isVerified': isVerified, 'newUser': true});

      debugPrint(
        "Verification status updated successfully for $uid in $collectionName.",
      );
    } catch (e) {
      debugPrint("Failed to update verification status: $e");
      throw Exception("Failed to update verification status.");
    }
  }

  Future<void> performFirestoreOperation({
    required String userId,
    required String collectionName,
    required String subCollectionName,
    required String documentId,
    required String type,
    Map<String, dynamic>? data,
    bool isUpdate = false,
    bool isDelete = false,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection(collectionName)
        .doc(userId)
        .collection(subCollectionName)
        .doc(documentId);

    final typeUpper = type[0].toUpperCase() + type.substring(1).toLowerCase();

    try {
      if (isDelete) {
        await ref.delete();
        await addNotification(userId, "$typeUpper deleted successfully.", type);
      } else if (isUpdate) {
        if (data != null) {
          await ref.update(data);
          await addNotification(
            userId,
            "$typeUpper updated successfully.",
            type,
          );
        }
      } else if (data != null) {
        await ref.set(data, SetOptions(merge: true));
        await addNotification(userId, "$typeUpper added successfully.", type);
      }
    } catch (e) {
      throw Exception("Error performing Firestore operation: $e");
    }
  }

  Future<void> removeDataFromUserCollection({
    required String userId,
    required String collectionName,
    required String subCollectionName,
    required String documentId,
    required String type,
  }) async {
    await performFirestoreOperation(
      userId: userId,
      collectionName: collectionName,
      subCollectionName: subCollectionName,
      documentId: documentId,
      isDelete: true,
      type: type,
    );
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Get the currently logged-in user's ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in.');
      }
      final currentUserId = currentUser.uid;

      // Check if the current user has admin role
      final userRole = await fetchAndCacheUserRole(currentUserId);
      if (userRole != 'admin') {
        throw Exception('Current user does not have admin privileges.');
      }

      await _moveUserDataToDeletedCollection(userId);

      // Add a log entry for the deletion
      await _logService.addLog(
        userId: userId,
        action: 'Deleted user $userId and moved to "deleted" collection',
        relatedUsers: userId,
      );

      print(
        "User document successfully moved to 'deleted' collection, removed from the original collection, and authentication deleted.",
      );
    } catch (e) {
      print("Error deleting user: $e");
      rethrow;
    }
  }

  Future<void> _moveUserDataToDeletedCollection(String userId) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final collectionName = await fetchAndCacheUserRole(userId);
      if (collectionName == null) {
        throw Exception("Unable to determine the user's role.");
      }

      // Run a Firestore transaction
      await firestore.runTransaction((transaction) async {
        // Reference to the original user document
        final userDocRef = firestore.collection(collectionName).doc(userId);

        // Fetch the user document
        final userDocSnapshot = await transaction.get(userDocRef);
        if (!userDocSnapshot.exists) {
          throw Exception(
            "User document not found in collection: $collectionName.",
          );
        }

        // Get user document data
        final userDocData = userDocSnapshot.data();

        // Reference to the 'deleted' collection document
        final deletedDocRef = firestore.collection('arhived').doc(userId);

        // Add the document to the 'deleted' collection
        transaction.set(deletedDocRef, {
          ...userDocData!,
          'deletedAt': FieldValue.serverTimestamp(), // Add a deletion timestamp
        });

        // Delete the document from the original collection
        transaction.delete(userDocRef);
      });

      // Now delete the subcollections for the user
      await _deleteUserSubcollections(userId);

      // Add a log entry for document movement (without subcollections)
      await _logService.addLog(
        userId: userId,
        action: 'Deleted user $userId and moved to "deleted" collection',
        relatedUsers: userId,
      );

      print("User document and subcollections successfully deleted.");
    } catch (e) {
      print("Error deleting user and subcollections: $e");
      rethrow;
    }
  }

  Future<void> markDecease(String userId) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get the collection name dynamically using fetchAndCacheUserRole
      final collectionName = await fetchAndCacheUserRole(userId);
      if (collectionName == null) {
        throw Exception("Unable to determine the user's role.");
      }

      // Run a Firestore transaction
      await firestore.runTransaction((transaction) async {
        // Reference to the original user document
        final userDocRef = firestore.collection(collectionName).doc(userId);

        // Fetch the user document
        final userDocSnapshot = await transaction.get(userDocRef);
        if (!userDocSnapshot.exists) {
          throw Exception(
            "User document not found in collection: $collectionName.",
          );
        }

        // Get user document data
        final userDocData = userDocSnapshot.data();

        // Reference to the 'deceased' collection document
        final deceasedDocRef = firestore.collection('deceased').doc(userId);

        // Add the document to the 'deceased' collection
        transaction.set(deceasedDocRef, {
          ...userDocData!,
          'deceasedAt':
              FieldValue.serverTimestamp(), // Add a deceased timestamp
        });

        // Delete the document from the original collection
        transaction.delete(userDocRef);
      });

      // Now delete the subcollections for the user
      await _deleteUserSubcollections(userId);

      // Add a log entry for marking user as deceased and deleting subcollections
      await _logService.addLog(
        userId: userId,
        action:
            'Marked user $userId as deceased and moved to "deceased" collection',
        relatedUsers: userId,
      );

      print(
        "User document and subcollections successfully moved to 'deceased' collection.",
      );
    } catch (e) {
      print("Error marking user as deceased and deleting subcollections: $e");
      rethrow;
    }
  }

  Future<void> _deleteUserSubcollections(String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String? userRole = await fetchAndCacheUserRole(userId);

    if (userRole == null) {
      debugPrint("User role is null");
      return;
    }
    // Subcollection names you want to delete
    final List<String> subcollectionNames = [
      'diagnoses',
      'medicines',
      'tasks',
      'schedules',
      'notes',
      'contacts',
      'notifications',
      'predictions',
      'tags',
    ];

    // Loop through each subcollection
    for (final subcollectionName in subcollectionNames) {
      try {
        // Reference to the subcollection
        final subcollectionRef = firestore
            .collection(userRole)
            .doc(userId)
            .collection(subcollectionName);

        // Fetch all documents in the subcollection
        final snapshot = await subcollectionRef.get();

        // Create a batch to delete documents
        final batch = firestore.batch();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        // Commit the batch operation to delete all documents in the subcollection
        await batch.commit();

        print(
          "Subcollection '$subcollectionName' for user $userId successfully deleted.",
        );
      } catch (e) {
        print(
          "Error deleting subcollection '$subcollectionName' for user $userId: $e",
        );
      }
    }
  }

  Future<DocumentSnapshot?> getDeletedUserByEmail(String email) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('deleted')
            .where('email', isEqualTo: email) // Filters documents by email
            .limit(1) // Retrieves only the first match (if any)
            .get();

    // Return the first document if it exists, otherwise null
    return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
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
        return PatientData.fromDocument(doc); // No casting needed now
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
    String? profileImageUrl,
    DateTime? birthday,
    List? cases,
    String? caseDescription,
    String? status,
    String? currentUserId, // Current user who is tagging the patient
  }) async {
    try {
      // Get the appropriate collection for the user role
      final collectionName = UserRole.patient.name;

      // Get the Firestore reference
      final collectionRef = FirebaseFirestore.instance.collection(
        collectionName,
      );

      // Prepare the data map for the patient
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
      if (profileImageUrl != null) {
        updatedData['profileImageUrl'] = profileImageUrl;
      }
      if (address?.isNotEmpty ?? false) updatedData['address'] = address;
      if (cases?.isNotEmpty ?? false) updatedData['cases'] = cases;
      if (caseDescription?.isNotEmpty ?? false) {
        updatedData['caseDescription'] = caseDescription;
      }
      if (status?.isNotEmpty ?? false) updatedData['status'] = status;

      // Add the dateCreated field
      updatedData['dateCreated'] = Timestamp.now();

      // Save the patient data to the patient collection
      if (updatedData.isNotEmpty) {
        await collectionRef.doc(uid).set(updatedData, SetOptions(merge: true));
        print("Patient data added successfully in collection: $collectionName");
      } else {
        print("No data provided to add patient.");
      }

      // Save tags as subcollections for both the patient and current user
      if (currentUserId != null) {
        final String? userRole = await fetchAndCacheUserRole(currentUserId);
        if (userRole == null) {
          throw Exception("User role not found for $currentUserId");
        }

        await FirebaseFirestore.instance
            .collection('patient')
            .doc(uid)
            .collection('tags')
            .doc(currentUserId)
            .set({});

        // Add patient tag to the current user's document
        await FirebaseFirestore.instance
            .collection(userRole)
            .doc(currentUserId)
            .collection('tags')
            .doc(uid)
            .set({});

        print("Tagging successful for patient and user.");
      }
    } catch (e) {
      print("Error adding patient data: $e");
      throw Exception("Failed to add patient data");
    }
  }

  Future<void> updatePatientData({
    required String patientId,
    String? firstName,
    String? middleName,
    String? lastName,
    int? age,
    String? gender,
    String? religion,
    String? profileImageUrl,
    DateTime? birthday,
    String? caseDescription,
    List? cases,
    String? status,
    String? address,
    List<String>? tag,
  }) async {
    try {
      // Prepare the data map with non-null fields
      final updateData = {
        if (firstName != null) 'firstName': firstName,
        if (middleName != null) 'middleName': middleName,
        if (lastName != null) 'lastName': lastName,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (religion != null) 'religion': religion,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (birthday != null) 'birthday': Timestamp.fromDate(birthday),
        if (cases != null && cases.isNotEmpty) 'cases': cases,
        if (caseDescription != null && caseDescription.isNotEmpty)
          'caseDescription': caseDescription,
        if (status != null && status.isNotEmpty) 'status': status,
        if (address != null && address.isNotEmpty) 'address': address,
        if (tag != null) 'tag': tag,
      };

      // Ensure there's data to update
      if (updateData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('patient')
            .doc(patientId)
            .update(updateData);
        print('Patient profile updated successfully.');
      } else {
        print('No valid data provided for update.');
      }
    } catch (e) {
      print('Error updating patient profile: $e');
      throw Exception('Failed to update patient profile');
    }
  }

  Future<DocumentSnapshot?> fetchUserDocument(String userId) async {
    try {
      final role = await fetchAndCacheUserRole(userId);
      if (role == null) return null;
      await cacheUserRole(userId, role);

      final doc =
          await FirebaseFirestore.instance.collection(role).doc(userId).get();
      if (doc.exists) {
        return doc;
      } else {
        debugPrint("No document found for userId: $userId");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching user document: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchThresholds() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('globals')
              .doc('thresholds')
              .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        Map<String, dynamic> thresholds = {};

        data.forEach((vital, values) {
          if (values is Map<String, dynamic>) {
            if (values['maxSevere'] != null) {
              thresholds['maxSevere${vital.capitalize()}'] =
                  values['maxSevere'];
            }
            if (values['maxMild'] != null) {
              thresholds['maxMild${vital.capitalize()}'] = values['maxMild'];
            }
            if (values['maxNormal'] != null) {
              thresholds['maxNormal${vital.capitalize()}'] =
                  values['maxNormal'];
            }
            if (values['minNormal'] != null) {
              thresholds['minNormal${vital.capitalize()}'] =
                  values['minNormal'];
            }
            if (values['minMild'] != null) {
              thresholds['minMild${vital.capitalize()}'] = values['minMild'];
            }
            if (values['minSevere'] != null) {
              thresholds['minSevere${vital.capitalize()}'] =
                  values['minSevere'];
            }
          } else {
            debugPrint('Unexpected format for $vital: $values');
          }
        });

        return thresholds;
      }
    } catch (e) {
      debugPrint('Error fetching thresholds: $e');
    }
    return {};
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
