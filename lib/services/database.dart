import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/models/my_user.dart';

class DatabaseService {

  final String? uid;
  DatabaseService({ this.uid });

  // collection reference
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');

  Future<void> updateUserData({
    bool? isAdmin,
    String? email,
    String? lastName,
    String? firstName,
    String? middleName,
    String? phoneNumber,
    String? sex,
    String? birthMonth,
    String? birthDay,
    String? birthYear,
  }) async {
    Map<String, dynamic> updatedData = {};
    if (isAdmin != null) updatedData['isAdmin'] = isAdmin;
    if (email != null) updatedData['email'] = email;
    if (lastName != null) updatedData['lastName'] = lastName;
    if (firstName != null) updatedData['firstName'] = firstName;
    if (middleName != null) updatedData['middleName'] = middleName;
    if (phoneNumber != null) updatedData['phoneNumber'] = phoneNumber;
    if (sex != null) updatedData['sex'] = sex;
    if (birthMonth != null) updatedData['birthMonth'] = birthMonth;
    if (birthDay != null) updatedData['birthDay'] = birthDay;
    if (birthYear != null) updatedData['birthYear'] = birthYear;

    print(updatedData['isAdmin']);
    print(updatedData['email']);
    print(updatedData['lastName']);
    print(updatedData['firstName']);
    print(updatedData['middleName']);
    print(updatedData['phoneNumber']);
    print(updatedData['sex']);
    print(updatedData['birthMonth']);
    print(updatedData['birthDay']);
    print(updatedData['birthYear']);

    // Only execute if there are fields to set
    if (updatedData.isNotEmpty) {
      print('UID: $uid');
      return await userCollection.doc(uid).set(updatedData, SetOptions(merge: true));
    }
  }


  // user list from snapshot
  List<UserData>? _userListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc){
      return UserData(
        isAdmin: doc.get('isAdmin') ?? false,
        email: doc.get('email') ?? 'none',
        lastName: doc.get('lastName') ?? 'none',
        firstName: doc.get('firstName') ?? 'none',
        middleName: doc.get('middleName') ?? 'none',
        phoneNumber: doc.get('phoneNumber') ?? 'none',
        sex: doc.get('sex') ?? 'none',
        birthMonth: doc.get('birthMonth') ?? 'none',
        birthDay: doc.get('birthDay') ?? 'none',
        birthYear: doc.get('birthYear') ?? 'none',
      );
    }).toList();
  }

  // user data from snapshots
  UserData _userDataFromSnapshot(DocumentSnapshot snapshot) {
    return UserData(
      isAdmin: snapshot['isAdmin'],
      email: snapshot['email'],
      lastName: snapshot['lastName'],
      firstName: snapshot['firstName'],
      middleName: snapshot['middleName'],
      phoneNumber: snapshot['phoneNumber'],
      sex: snapshot['sex'],
      birthMonth: snapshot['birthMonth'],
      birthDay: snapshot['birthDay'],
      birthYear: snapshot['birthYear'],
    );
  }

  // get userCollection stream
  Stream<List<UserData>?>? get users {
    return userCollection.snapshots().map(_userListFromSnapshot);
  }

  // get user doc stream
  Stream<UserData>? get userData {
    return userCollection.doc(uid).snapshots().map(_userDataFromSnapshot);
  }
}