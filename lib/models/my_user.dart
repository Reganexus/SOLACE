import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum UserRole { admin, patient, family, caregiver, doctor }

class MyUser {
  final String uid;
  final bool isVerified; // Add isVerified

  MyUser({required this.uid, required this.isVerified}); // Update constructor
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
  });

  factory UserData.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserData(
      uid: doc.id,
      userRole: UserData.getUserRoleFromString(data['userRole']?.toString() ?? 'patient'), // Ensure to convert to string
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
        other.isVerified == isVerified; // Include isVerified in equality check
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
    isVerified.hashCode; // Include isVerified in hash code
  }

  // Helper function to convert string to UserRole enum
  static UserRole getUserRoleFromString(String role) {
    return UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == role,
      orElse: () => UserRole.patient, // Default role if not found
    );
  }

  // Helper function to convert UserRole enum to string
  static String getUserRoleString(UserRole userRole) {
    return userRole.toString().split('.').last; // This will return the string representation
  }
}
