import 'package:cloud_firestore/cloud_firestore.dart';

class PatientData {
  final String uid;
  final String firstName;
  final String lastName;
  final String? profileImageUrl; // Made nullable
  final String gender;
  final DateTime? birthday;
  final DateTime dateCreated;
  final String religion;
  final String? will; // Made nullable
  final String? fixedWishes; // Made nullable
  final String? organDonation; // Made nullable
  final String status;

  PatientData({
    required this.uid,
    required this.firstName,
    required this.lastName,
    this.profileImageUrl, // Nullable
    required this.dateCreated,
    required this.gender,
    this.birthday, // Nullable
    required this.religion,
    this.will, // Nullable
    this.fixedWishes, // Nullable
    this.organDonation, // Nullable
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
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Safely parse birthday and dateCreated
      final DateTime? birthday = data['birthday'] != null
          ? (data['birthday'] as Timestamp).toDate()
          : null;

      final DateTime? dateCreated = data['dateCreated'] != null
          ? (data['dateCreated'] as Timestamp).toDate()
          : null;

      return PatientData(
        uid: doc.id,
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        profileImageUrl: data['profileImageUrl'] as String?, // Nullable
        gender: data['gender'] ?? '',
        birthday: birthday,
        dateCreated: dateCreated ?? DateTime.now(), // Default to current date if missing
        religion: data['religion'] ?? '',
        will: data['will'] as String?, // Nullable
        fixedWishes: data['fixedWishes'] as String?, // Nullable
        organDonation: data['organDonation'] as String?, // Nullable
        status: data['status'] ?? 'stable',
      );
    } catch (e) {
      throw Exception('Error parsing patient data: $e');
    }
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
