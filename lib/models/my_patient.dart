import 'package:cloud_firestore/cloud_firestore.dart';

class PatientData {
  final String uid;
  final String userRole;
  final String firstName;
  final String lastName;
  final String middleName;
  final String caseTitle;
  final String caseDescription;
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
  final List<String> tag;

  PatientData({
    required this.uid,
    this.userRole = 'patient',
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.caseTitle,
    required this.caseDescription,
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
    required this.tag,
  });

  int get age {
    final now = DateTime.now();
    int years = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      years--;
    }
    return years;
  }

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
      middleName: data['middleName'] ?? '',
      caseTitle: data['caseTitle'] ?? '',
      caseDescription: data['caseDescription'] ?? '',
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
      tag: List<String>.from(data['tag'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userRole': userRole,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'caseTitle': caseTitle,
      'caseDescription': caseDescription,
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
      'tag': tag,
    };
  }

  @override
  String toString() {
    return 'PatientData(uid: $uid, userRole: $userRole, firstName: $firstName, lastName: $lastName, middleName: $middleName, caseTitle: $caseTitle, caseDescription: $caseDescription, gender: $gender, birthday: $birthday, age: $age, religion: $religion, address: $address, status: $status, tag: $tag)';
  }
}
