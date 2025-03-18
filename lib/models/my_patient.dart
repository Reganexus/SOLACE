import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PatientData {
  final String uid;
  final String userRole;
  final String firstName;
  final String lastName;
  final String profileImageUrl;
  final String gender;
  final DateTime birthday;
  final DateTime dateCreated;
  final String religion;
  final String will;
  final String fixedWishes;
  final String organDonation;
  final String status;
  final String address;

  PatientData({
    required this.uid,
    this.userRole = 'patient',
    required this.firstName,
    required this.lastName,
    required this.profileImageUrl, // Nullable
    required this.dateCreated,
    required this.gender,
    required this.birthday, // Nullable
    required this.religion,
    required this.will, // Nullable
    required this.fixedWishes, // Nullable
    required this.organDonation, // Nullable
    required this.status,
    required this.address,
  });

  int? get age {
    if (birthday == null) return null; // No age if birthday is not set
    final now = DateTime.now();
    int years = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      years--;
    }
    return years;
  }

  /// Factory method to create a PatientData object from Firestore document
  factory PatientData.fromDocument(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      final DateTime? birthday =
          data['birthday'] != null
              ? (data['birthday'] as Timestamp).toDate()
              : null;

      final DateTime? dateCreated =
          data['dateCreated'] != null
              ? (data['dateCreated'] as Timestamp).toDate()
              : null;

      return PatientData(
        uid: doc.id,
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        profileImageUrl: data['profileImageUrl'] ?? '',
        gender: data['gender'] ?? '',
        birthday: birthday ?? DateTime.now(),
        dateCreated: dateCreated ?? DateTime.now(),
        religion: data['religion'] ?? '',
        will: data['will'] ?? '',
        fixedWishes: data['fixedWishes'] ?? '',
        organDonation: data['organDonation'] ?? '',
        status: data['status'] ?? 'stable',
        address: data['address'] ?? '',
      );
    } catch (e) {
      debugPrint('Error parsing patient data: $e');
      throw Exception('Error parsing patient data: $e');
    }
  }

  /// Converts a PatientData object into a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'userRole': userRole,
      'firstName': firstName,
      'lastName': lastName,
      'profileImageUrl': profileImageUrl,
      'gender': gender,
      'birthday': Timestamp.fromDate(birthday),
      'dateCreated': Timestamp.fromDate(dateCreated),
      'religion': religion,
      'will': will,
      'fixedWishes': fixedWishes,
      'organDonation': organDonation,
      'status': status,
      'address': address,
    };
  }

  @override
  String toString() {
    return 'PatientData(uid: $uid, userRole: $userRole, firstName: $firstName, lastName: $lastName, gender: $gender, birthday: $birthday, age: $age, religion: $religion, address: $address, status: $status)';
  }
}
