import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:solace/models/hive_boxes.dart';
import 'package:solace/models/local_user.dart';

enum UserRole { admin, patient, family, caregiver, doctor }

class MyUser with ChangeNotifier {
  String uid;
  bool isVerified; // Add isVerified
  bool newUser;
  String profileImageUrl;

  MyUser({
    required this.uid,
    required this.isVerified,
    this.newUser = true,
    required this.profileImageUrl,
  });

  // Method to update user data
  void setUser(String newUid, bool newIsVerified, bool isNewUser,
      String newProfileImageUrl) {
    uid = newUid;
    isVerified = newIsVerified;
    newUser = isNewUser;
    profileImageUrl = newProfileImageUrl; // Update profileImageUrl
    notifyListeners();
  }
}

class UserData {
  final String uid;
  final UserRole userRole;
  final String email;
  final String firstName;
  final String middleName;
  final String lastName;
  final String phoneNumber;
  final DateTime? birthday;
  final String gender;
  final String address;
  final String profileImageUrl;
  final bool isVerified;
  final bool newUser;
  final DateTime? dateCreated;

  UserData({
    required this.uid,
    required this.userRole,
    required this.email,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.phoneNumber,
    this.birthday,
    required this.gender,
    required this.address,
    required this.profileImageUrl,
    required this.isVerified,
    required this.newUser,
    this.dateCreated,
  });

  factory UserData.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserData(
      uid: doc.id,
      userRole: UserData.getUserRoleFromString(
          data['userRole']?.toString() ?? 'patient'),
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      middleName: data['middleName'] ?? '',
      lastName: data['lastName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      birthday: data['birthday'] != null
          ? (data['birthday'] as Timestamp).toDate()
          : null,
      gender: data['gender'] ?? '',
      address: data['address'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      isVerified: data['isVerified'] ?? false,
      newUser: data['newUser'] ?? true,
      dateCreated: (data['dateCreated'] as Timestamp).toDate(),
    );
  }

  factory UserData.fromLocal(String uid) {
    LocalUser? existingUser = localUsersBox.get(uid);
    if (existingUser != null) {
      return UserData(
        uid: existingUser.uid ?? '',
        userRole: getUserRoleFromString(existingUser.userRole ?? ''),
        email: existingUser.email ?? '',
        firstName: existingUser.firstName ?? '',
        middleName: existingUser.middleName ?? '',
        lastName: existingUser.lastName ?? '',
        phoneNumber: existingUser.phoneNumber ?? '',
        birthday: existingUser.birthday?.toDate(),
        gender: existingUser.gender ?? '',
        address: existingUser.address ?? '',
        profileImageUrl: existingUser.profileImageUrl ?? '',
        isVerified: existingUser.isVerified ?? false,
        newUser: existingUser.newUser ?? false,
        dateCreated: existingUser.dateCreated!.toDate(),
      );
    } else {
      return UserData(
        uid: '',
        userRole: UserRole.patient,
        email: '',
        firstName: '',
        middleName: '',
        lastName: '',
        phoneNumber: '',
        birthday: null,
        gender: '',
        address: '',
        profileImageUrl: '',
        isVerified: false,
        newUser: false,
        dateCreated: null,
      );
    }
  }


  @override
  String toString() {
    return 'UserData{uid: $uid, userRole: $userRole, email: $email, firstName: $firstName, middleName: $middleName, lastName: $lastName, phoneNumber: $phoneNumber, birthday: ${birthday != null ? DateFormat('yyyy-MM-dd').format(birthday!) : 'N/A'}, gender: $gender, address: $address, profileImageUrl: $profileImageUrl, isVerified: $isVerified, newUser: $newUser, dateCreated: ${dateCreated != null ? DateFormat('yyyy-MM-dd').format(dateCreated!) : 'N/A'}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserData &&
        other.uid == uid &&
        other.userRole == userRole &&
        other.email == email &&
        other.firstName == firstName &&
        other.middleName == middleName &&
        other.lastName == lastName &&
        other.phoneNumber == phoneNumber &&
        other.birthday == birthday &&
        other.gender == gender &&
        other.address == address &&
        other.profileImageUrl == profileImageUrl &&
        other.isVerified == isVerified && 
        other.newUser == newUser &&
        other.dateCreated == dateCreated;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        userRole.hashCode ^
        email.hashCode ^
        firstName.hashCode ^
        middleName.hashCode ^
        lastName.hashCode ^
        phoneNumber.hashCode ^
        birthday.hashCode ^
        gender.hashCode ^
        address.hashCode ^
        isVerified.hashCode ^
        newUser.hashCode ^
        dateCreated.hashCode;
  }

  static UserRole getUserRoleFromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.toString().split('.').last == role,
      orElse: () => UserRole.patient,
    );
  }

  static String? getUserRoleString(UserRole userRole) {
    return userRole.toString().split('.').last;
  }
}
