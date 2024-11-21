import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:solace/models/hive_boxes.dart';
import 'package:solace/models/local_user.dart';
import 'package:solace/models/my_user.dart';

class LocalDatabaseService {
  final String? uid;

  LocalDatabaseService({this.uid});

  updateLocalUserData({
    UserRole? userRole,
    String? email,
    String? firstName,
    String? middleName,
    String? lastName,
    String? phoneNumber,
    DateTime? birthday,
    String? gender,
    String? address,
    String? profileImageUrl,
    bool? isVerified,
    bool? newUser,
    DateTime? dateCreated,
  }) {
    // Print initial values (Before update)
    LocalUser? existingUser = localUsersBox.get(uid);
    debugPrint('Before Update - Existing User Data:');
    debugPrint(existingUser != null ? existingUser.firstName : 'No existing user found');

    // Update local Hive storage
    // First, retrieve the existing LocalUser or create a new one if not found
    existingUser = localUsersBox.get(uid) ?? LocalUser(
      uid: uid,
      userRole: UserData.getUserRoleString(userRole ?? UserRole.patient), // Assuming a default role
      email: email ?? '',
      firstName: firstName ?? '',
      middleName: middleName ?? '',
      lastName: lastName ?? '',
      phoneNumber: phoneNumber ?? '',
      birthday: birthday != null ? Timestamp.fromDate(birthday) : null, 
      gender: gender ?? '',
      address: address ?? '',
      profileImageUrl: profileImageUrl ?? '',
      isVerified: isVerified ?? false,
      newUser: newUser ?? false,
      dateCreated: dateCreated != null ? Timestamp.fromDate(dateCreated) : null,
    );

    // Create a new LocalUser instance with updated fields
    LocalUser updatedUser = LocalUser(
      uid: uid,
      userRole: userRole != null ? UserData.getUserRoleString(userRole) : existingUser.userRole,
      email: email ?? existingUser.email,
      firstName: firstName ?? existingUser.firstName,
      middleName: middleName ?? existingUser.middleName,
      lastName: lastName ?? existingUser.lastName,
      phoneNumber: phoneNumber ?? existingUser.phoneNumber,
      birthday: birthday != null ? Timestamp.fromDate(birthday) : existingUser.birthday,
      gender: gender ?? existingUser.gender,
      address: address ?? existingUser.address,
      profileImageUrl: profileImageUrl ?? existingUser.profileImageUrl,
      isVerified: isVerified ?? existingUser.isVerified,
      newUser: newUser ?? existingUser.newUser,
      dateCreated: dateCreated != null ? Timestamp.fromDate(dateCreated) : existingUser.dateCreated,
    );

    // Save the updated user to Hive
    localUsersBox.put(uid, updatedUser);

    // Print new data to be saved (After update)
    debugPrint('After Update - New Local User Data:');
    debugPrint(updatedUser.firstName);
  }
}