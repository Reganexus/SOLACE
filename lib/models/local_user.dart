import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'local_user.g.dart';

@HiveType(typeId: 1)
class LocalUser extends HiveObject {
  LocalUser({
    required this.uid,
    required this.userRole,
    required this.email,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.phoneNumber,
    required this.birthday,
    required this.gender,
    required this.address,
    required this.profileImageUrl,
    required this.isVerified,
    required this.newUser,
    required this.dateCreated,
  });

  @HiveField(0)
  String? uid;

  @HiveField(1)
  String? userRole;

  @HiveField(2)
  String? email;

  @HiveField(3)
  String? firstName;

  @HiveField(4)
  String? middleName;

  @HiveField(5)
  String? lastName;

  @HiveField(6)
  String? phoneNumber;

  @HiveField(7)
  Timestamp? birthday;

  @HiveField(8)
  String? gender;

  @HiveField(9)
  String? address;

  @HiveField(10)
  String? profileImageUrl;

  @HiveField(11)
  bool? isVerified;

  @HiveField(12)
  bool? newUser;

  @HiveField(13)
  Timestamp? dateCreated;
}