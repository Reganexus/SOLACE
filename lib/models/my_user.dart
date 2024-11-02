import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, patient, family, caregiver, doctor }

class MyUser {
  final String uid;

  MyUser({required this.uid});
}

class UserData {
  final String uid; // Added the uid field
  final UserRole userRole;
  final String? email;
  final String? lastName;
  final String? firstName;
  final String? middleName;
  final String? phoneNumber;
  final String? sex;
  final String? birthMonth;
  final String? birthDay;
  final String? birthYear;
  final String? address;

  UserData({
    required this.uid, // Add uid here
    required this.userRole,
    required this.email,
    this.lastName,
    this.firstName,
    this.middleName,
    this.phoneNumber,
    this.sex,
    this.birthMonth,
    this.birthDay,
    this.birthYear,
    this.address,
  });

  // Factory method to create UserData from a Firestore document
  factory UserData.fromDocument(DocumentSnapshot snapshot) {
    return UserData(
      uid: snapshot.id, // Fetch uid from Firestore document ID
      userRole: UserData.getUserRoleFromString(snapshot['userRole']),
      email: snapshot['email'],
      lastName: snapshot['lastName'],
      firstName: snapshot['firstName'],
      middleName: snapshot['middleName'],
      phoneNumber: snapshot['phoneNumber'],
      sex: snapshot['sex'],
      birthMonth: snapshot['birthMonth'],
      birthDay: snapshot['birthDay'],
      birthYear: snapshot['birthYear'],
      address: snapshot['address'],
    );
  }

  @override
  String toString() {
    return 'UserData{uid: $uid, userRole: $userRole, email: $email, lastName: $lastName, firstName: $firstName, middleName: $middleName, phoneNumber: $phoneNumber, sex: $sex, birthMonth: $birthMonth, birthDay: $birthDay, birthYear: $birthYear, address: $address}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserData &&
        other.uid == uid && // Include uid comparison here
        other.userRole == userRole &&
        other.email == email &&
        other.lastName == lastName &&
        other.firstName == firstName &&
        other.middleName == middleName &&
        other.phoneNumber == phoneNumber &&
        other.sex == sex &&
        other.birthMonth == birthMonth &&
        other.birthDay == birthDay &&
        other.birthYear == birthYear &&
        other.address == address;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ // Include uid in hashCode
    userRole.hashCode ^
    email.hashCode ^
    lastName.hashCode ^
    firstName.hashCode ^
    middleName.hashCode ^
    phoneNumber.hashCode ^
    sex.hashCode ^
    birthMonth.hashCode ^
    birthDay.hashCode ^
    birthYear.hashCode ^
    address.hashCode;
  }

  // Helper function to convert string to UserRole enum
  static UserRole getUserRoleFromString(String role) {
    return UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == role,
      orElse: () => UserRole.patient, // Default role if not found
    );
  }

  // Helper function to convert UserRole enum to string
  static String getUserRoleString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.family:
        return 'family';
      case UserRole.caregiver:
        return 'caregiver';
      case UserRole.doctor:
        return 'doctor';
      default:
        return 'patient';
    }
  }
}
