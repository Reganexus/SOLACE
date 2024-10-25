class MyUser {

  final String uid;

  MyUser({ required this.uid });

}

class UserData {
  final bool isAdmin;
  final String email;
  final String? lastName;
  final String? firstName;
  final String? middleName;
  final String? phoneNumber;
  final String? sex;
  final String? birthMonth;
  final String? birthDay;
  final String? birthYear;

  UserData({
    required this.isAdmin,
    required this.email,
    this.lastName,
    this.firstName,
    this.middleName,
    this.phoneNumber,
    this.sex,
    this.birthMonth,
    this.birthDay,
    this.birthYear,
  });
}