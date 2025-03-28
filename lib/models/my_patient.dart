import 'package:cloud_firestore/cloud_firestore.dart';

class PatientData {
  final String uid;
  final String userRole;
  final String firstName;
  final String lastName;
  final String middleName; // Changed to required
  final String caseTitle; // Required
  final String caseDescription; // Required
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
    required this.middleName, // Marked as required
    required this.caseTitle, // Required
    required this.caseDescription, // Required
    required this.profileImageUrl,
    required this.gender,
    required this.birthday,
    required this.dateCreated,
    required this.religion,
    required this.will,
    required this.fixedWishes,
    required this.organDonation,
    required this.status,
    required this.address,
  });

  /// Calculate age from the birthday
  int get age {
    final now = DateTime.now();
    int years = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      years--;
    }
    return years;
  }

  /// Factory method to create `PatientData` from a Firestore document
  factory PatientData.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null for patient ID: ${doc.id}');
    }

    return PatientData(
      uid: doc.id,
      userRole: data['userRole'] ?? 'patient',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      middleName:
          data['middleName'] ?? '', // Changed to required with default fallback
      caseTitle: data['caseTitle'] ?? '', // Ensure default value or required
      caseDescription:
          data['caseDescription'] ?? '', // Ensure default value or required
      profileImageUrl: data['profileImageUrl'] ?? '',
      gender: data['gender'] ?? '',
      birthday: (data['birthday'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateCreated:
          (data['dateCreated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      religion: data['religion'] ?? '',
      will: data['will'] ?? '',
      fixedWishes: data['fixedWishes'] ?? '',
      organDonation: data['organDonation'] ?? '',
      status: data['status'] ?? 'stable',
      address: data['address'] ?? '',
    );
  }

  /// Converts `PatientData` into a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'userRole': userRole,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName, // Included as required
      'caseTitle': caseTitle, // Include in mapping
      'caseDescription': caseDescription, // Include in mapping
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
    return 'PatientData(uid: $uid, userRole: $userRole, firstName: $firstName, lastName: $lastName, middleName: $middleName, caseTitle: $caseTitle, caseDescription: $caseDescription, gender: $gender, birthday: $birthday, age: $age, religion: $religion, address: $address, status: $status)';
  }
}
