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
    // Clear all keys that match 'userRole_' prefix
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
    final doc = await _fetchUserDocument(userId);
    if (doc == null || !doc.exists) return null;
    return UserData.fromDocument(doc);
  }

  Future<bool> checkUserExists(String userId) async {
    final doc = await _fetchUserDocument(userId);
    return doc?.exists ?? false;
  }

  Future<String?> fetchProfileImageUrl(String userId) async {
    final doc = await _fetchUserDocument(userId);
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
    final doc = await _fetchUserDocument(userId);
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
    final doc = await _fetchUserDocument(currentUserId);

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
      // Fetch user data
      final userData = await fetchUserData(userId);
      if (userData == null) {
        print("User document not found.");
        return;
      }

      // Get the collection name dynamically using fetchAndCacheUserRole
      final collectionName = await fetchAndCacheUserRole(userId);
      if (collectionName == null) {
        throw Exception("Unable to determine the user's role.");
      }

      // Delete the user's document from Firestore
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(userId)
          .delete();
      print("User document deleted from collection: $collectionName.");

      // Delete related tracking records
      final trackingDocs =
          await FirebaseFirestore.instance
              .collection('tracking')
              .where('userId', isEqualTo: userId)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in trackingDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print("Related tracking records deleted.");

      // Add a log entry for the deletion
      await _logService.addLog(
        userId: uid ?? '',
        action: 'Deleted user $userId',
        relatedUsers: userId,
      );
    } catch (e) {
      print("Error deleting user: $e");
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
      final collectionName = UserRole.patient.name;

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

  Future<void> updatePatientData({
    required String patientId,
    String? firstName,
    String? middleName,
    String? lastName,
    int? age,
    String? gender,
    String? religion,
    String? will,
    String? fixedWishes,
    String? organDonation,
    String? profileImageUrl,
    DateTime? birthday,
    String? caseTitle,
    String? caseDescription,
    String? status,
    String? address,
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
        if (will != null && will.isNotEmpty) 'will': will,
        if (fixedWishes != null && fixedWishes.isNotEmpty)
          'fixedWishes': fixedWishes,
        if (organDonation != null && organDonation.isNotEmpty)
          'organDonation': organDonation,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (birthday != null) 'birthday': Timestamp.fromDate(birthday),
        if (caseTitle != null && caseTitle.isNotEmpty) 'caseTitle': caseTitle,
        if (caseDescription != null && caseDescription.isNotEmpty)
          'caseDescription': caseDescription,
        if (status != null && status.isNotEmpty) 'status': status,
        if (address != null && address.isNotEmpty) 'address': address,
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

  Future<DocumentSnapshot?> _fetchUserDocument(String userId) async {
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
}
