import 'package:cloud_firestore/cloud_firestore.dart';

class PatientData {
  final String uid;
  final String firstName;
  final String lastName;
  final String profileImageUrl;
  final String gender;
  final DateTime? birthday;
  final DateTime dateCreated;
  final String religion;
  final String will;
  final String fixedWishes;
  final String organDonation;
  final String status;

  PatientData({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.profileImageUrl,
    required this.dateCreated,
    required this.gender,
    required this.birthday,
    required this.religion,
    required this.will,
    required this.fixedWishes,
    required this.organDonation,
    required this.status,
  });

  int? get age {
    if (birthday == null) return null; // No age if birthday is not set
    final now = DateTime.now();
    int years = now.year - birthday!.year;
    if (now.month < birthday!.month ||
        (now.month == birthday!.month && now.day < birthday!.day)) {
      years--;
    }
    return years;
  }

  /// Factory method to create a PatientData object from Firestore document
  factory PatientData.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Calculate age based on birthday, if provided
    final DateTime? birthday = data['birthday'] != null
        ? (data['birthday'] as Timestamp).toDate()
        : null;

    return PatientData(
      uid: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      gender: data['gender'] ?? '',
      birthday: birthday,
      dateCreated: (data['dateCreated'] as Timestamp).toDate(),
      religion: data['religion'] ?? '',
      will: data['will'],
      fixedWishes: data['fixedWishes'],
      organDonation: data['organDonation'],
      status: data['status'] ?? 'stable',
    );
  }

  /// Converts a PatientData object into a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'profileImageUrl': profileImageUrl,
      'gender': gender,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'dateCreated': Timestamp.fromDate(dateCreated),
      'religion': religion,
      'will': will,
      'fixedWishes': fixedWishes,
      'organDonation': organDonation,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'PatientData(uid: $uid, firstName: $firstName, lastName: $lastName, gender: $gender, birthday: $birthday, age: $age, religion: $religion, status: $status)';
  }
}
