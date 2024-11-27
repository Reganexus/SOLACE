import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

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
  final UserRole userRole;
  final String uid;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final DateTime? birthday;
  final String gender;
  final String address;
  final bool isVerified;
  final bool newUser;
  final DateTime dateCreated;
  final String profileImageUrl;

  UserData({
    required this.userRole,
    required this.uid,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.birthday,
    required this.gender,
    required this.address,
    required this.isVerified,
    required this.newUser,
    required this.dateCreated,
    required this.profileImageUrl,
  });

  factory UserData.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserData(
      uid: doc.id,
      userRole: UserData.getUserRoleFromString(
          data['userRole']?.toString() ?? 'patient'),
      firstName: data['firstName'] ?? '',
      middleName: data['middleName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      birthday: data['birthday'] != null
          ? (data['birthday'] as Timestamp).toDate()
          : null,
      gender: data['gender'] ?? '',
      address: data['address'] ?? '',
      isVerified: data['isVerified'] ?? false,
      newUser: data['newUser'] ?? true,
      dateCreated: (data['dateCreated'] as Timestamp).toDate(),
      profileImageUrl: data['profileImageUrl'],
    );
  }

  @override
  String toString() {
    return 'UserData{uid: $uid, userRole: $userRole, email: $email, lastName: $lastName, firstName: $firstName, middleName: $middleName, phoneNumber: $phoneNumber, gender: $gender, birthday: ${birthday != null ? DateFormat('yyyy-MM-dd').format(birthday!) : 'N/A'}, address: $address, isVerified: $isVerified}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserData &&
        other.uid == uid &&
        other.userRole == userRole &&
        other.email == email &&
        other.lastName == lastName &&
        other.firstName == firstName &&
        other.middleName == middleName &&
        other.phoneNumber == phoneNumber &&
        other.gender == gender &&
        other.birthday == birthday &&
        other.address == address &&
        other.isVerified == isVerified;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        userRole.hashCode ^
        email.hashCode ^
        lastName.hashCode ^
        firstName.hashCode ^
        middleName.hashCode ^
        phoneNumber.hashCode ^
        gender.hashCode ^
        (birthday?.hashCode ?? 0) ^
        address.hashCode ^
        isVerified.hashCode;
  }

  static UserRole getUserRoleFromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.toString().split('.').last == role,
      orElse: () => UserRole.patient,
    );
  }

  static String getUserRoleString(UserRole userRole) {
    return userRole.toString().split('.').last;
  }

  // Method to calculate the user's age as a list [years, months, days].
  List<int>? calculateAge() {
    if (birthday == null) return null; // Return null if birthday is not set

    DateTime today = DateTime.now();
    int years = today.year - birthday!.year;
    int months = today.month - birthday!.month;
    int days = today.day - birthday!.day;

    // Adjust for negative days
    if (days < 0) {
      months--;
      DateTime prevMonth = DateTime(today.year, today.month, 0); // Previous month
      days += prevMonth.day;
    }

    // Adjust for negative months
    if (months < 0) {
      years--;
      months += 12;
    }

    return [years, months, days];
  }

  // Getter to calculate the age as a string (e.g., "25 years, 3 months, 12 days")
  int? get age {
    final ageList = calculateAge();
    if (ageList == null) return null;
    // return '${ageList[0]} years, ${ageList[1]} months, ${ageList[2]} days';
    return ageList[0];
  }
}
