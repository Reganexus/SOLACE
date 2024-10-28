class MyUser {
  final String uid;

  MyUser({required this.uid});
}

class UserData {
  final String uid; // Add this line
  final bool isAdmin;
  final String? email;
  final String? lastName;
  final String? firstName;
  final String? middleName;
  final String? phoneNumber;
  final String? sex;
  final String? birthMonth;
  final String? birthDay;
  final String? birthYear;
  final String? address;

  UserData({
    required this.uid, // Add this line
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
    this.address,
  });

  @override
  String toString() {
    return 'UserData{isAdmin: $isAdmin, email: $email, lastName: $lastName, firstName: $firstName, middleName: $middleName, phoneNumber: $phoneNumber, sex: $sex, birthMonth: $birthMonth, birthDay: $birthDay, birthYear: $birthYear}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserData &&
        other.uid == uid && // Include uid in equality check
        other.isAdmin == isAdmin &&
        other.email == email &&
        other.lastName == lastName &&
        other.firstName == firstName &&
        other.middleName == middleName &&
        other.phoneNumber == phoneNumber &&
        other.sex == sex &&
        other.birthMonth == birthMonth &&
        other.birthDay == birthDay &&
        other.birthYear == birthYear;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ // Include uid in hashCode
    isAdmin.hashCode ^
    email.hashCode ^
    lastName.hashCode ^
    firstName.hashCode ^
    middleName.hashCode ^
    phoneNumber.hashCode ^
    sex.hashCode ^
    birthMonth.hashCode ^
    birthDay.hashCode ^
    birthYear.hashCode;
  }
}
