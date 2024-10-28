class UserData {
  final bool isAdmin;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String email;
  final String? phoneNumber;
  final String? sex;
  final String? birthMonth;
  final String? birthDay;
  final String? birthYear;
  final String? address;

  UserData({
    required this.isAdmin,
    this.lastName,
    this.firstName,
    this.middleName,
    required this.email,
    this.phoneNumber,
    this.sex,
    this.birthMonth,
    this.birthDay,
    this.birthYear,
    this.address,
  });

  @override
  String toString() {
    return 'UserData{isAdmin: $isAdmin, email: $email, lastName: $lastName, firstName: $firstName, middleName: $middleName, phoneNumber: $phoneNumber, sex: $sex, birthMonth: $birthMonth, birthDay: $birthDay, birthYear: $birthYear, address: $address}';
  }
}
