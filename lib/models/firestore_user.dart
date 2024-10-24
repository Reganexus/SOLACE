class FirestoreUser {

  final bool isAdmin;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String email;

  FirestoreUser({
    required this.isAdmin,
    this.lastName,
    this.firstName,
    this.middleName,
    required this.email
  });
}