import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

enum UserRole { admin, nurse, caregiver, doctor, patient, unregistered }

extension UserRoleExtension on UserRole {
  static List<String> get allRoles =>
      UserRole.values.map((e) => e.name).toList();

  static UserRole? fromString(String role) {
    try {
      return UserRole.values.firstWhere((e) => e.name == role);
    } catch (e) {
      return null;
    }
  }
}

class MyUser with ChangeNotifier {
  String uid;
  bool isVerified;
  bool newUser;
  String profileImageUrl;
  String? email; // Add email as a nullable property

  MyUser({
    required this.uid,
    required this.isVerified,
    this.newUser = true,
    required this.profileImageUrl,
    this.email, // Initialize email (optional)
  });

  // Method to update user data
  void setUser(
    String newUid,
    bool newIsVerified,
    bool isNewUser,
    String newProfileImageUrl,
    String? newEmail,
  ) {
    uid = newUid;
    isVerified = newIsVerified;
    newUser = isNewUser;
    profileImageUrl = newProfileImageUrl;
    email = newEmail; // Update email
    notifyListeners();
  }
}

class UserData {
  final UserRole userRole;
  final String uid;
  final String firstName;
  final String? middleName;
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
  final String status;
  final String religion;

  UserData({
    required this.userRole,
    required this.uid,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.birthday,
    required this.gender,
    required this.address,
    required this.isVerified,
    required this.newUser,
    required this.dateCreated,
    required this.profileImageUrl,
    required this.status,
    required this.religion,
  });

  int? get age =>
      birthday == null
          ? null
          : DateTime.now().year -
              birthday!.year -
              (DateTime.now().isBefore(
                    DateTime(
                      birthday!.year,
                      DateTime.now().month,
                      DateTime.now().day,
                    ),
                  )
                  ? 1
                  : 0);

  factory UserData.fromMap(Map<String, dynamic> map, String id) {
    return UserData(
      uid: id,
      userRole: UserData.getUserRoleFromString(
        map['userRole']?.toString() ?? 'caregiver',
      ),
      firstName: map['firstName'] ?? '',
      middleName: map['middleName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      birthday:
          map['birthday'] != null
              ? (map['birthday'] as Timestamp).toDate()
              : null,
      gender: map['gender'] ?? '',
      address: map['address'] ?? '',
      isVerified: map['isVerified'] ?? '',
      newUser: map['newUser'] ?? true,
      dateCreated: map['dateCreated'] ?? '',
      status: map['status'] ?? '',
      religion: map['religion'] ?? '',
    );
  }

  factory UserData.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserData(
      uid: doc.id,
      userRole: UserData.getUserRoleFromString(
        data['userRole']?.toString() ?? 'patient',
      ),
      firstName: data['firstName'] ?? '',
      middleName: data['middleName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      birthday:
          data['birthday'] is Timestamp
              ? (data['birthday'] as Timestamp).toDate()
              : null,
      gender: data['gender'] ?? '',
      address: data['address'] ?? '',
      isVerified: data['isVerified'] ?? false,
      newUser: data['newUser'] ?? true,
      dateCreated:
          data['dateCreated'] is Timestamp
              ? (data['dateCreated'] as Timestamp).toDate()
              : DateTime.now(),
      profileImageUrl: data['profileImageUrl'] ?? '',
      status: data['status'] ?? 'stable',
      religion: data['religion'] ?? 'Not specified',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userRole': getUserRoleString(userRole),
      'uid': uid,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'gender': gender,
      'address': address,
      'isVerified': isVerified,
      'newUser': newUser,
      'dateCreated': Timestamp.fromDate(dateCreated),
      'profileImageUrl': profileImageUrl,
      'status': status,
      'religion': religion,
    };
  }

  @override
  String toString() {
    return 'UserData{uid: $uid, userRole: $userRole, email: $email, lastName: $lastName, firstName: $firstName, middleName: $middleName, phoneNumber: $phoneNumber, gender: $gender, birthday: ${birthday != null ? DateFormat('yyyy-MM-dd').format(birthday!) : 'N/A'}, address: $address, isVerified: $isVerified, status: $status, religion: $religion}';
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
        other.isVerified == isVerified &&
        other.status == status &&
        other.religion == religion;
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
        isVerified.hashCode ^
        status.hashCode ^
        religion.hashCode;
  }

  static UserRole getUserRoleFromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.toString().split('.').last == role,
      orElse: () => UserRole.caregiver,
    );
  }

  static String getUserRoleString(UserRole userRole) {
    return userRole.toString().split('.').last;
  }
}
