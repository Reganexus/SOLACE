// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/models/my_user.dart';

class DatabaseService {

  final String? uid;
  DatabaseService({this.uid});

  // collection reference
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  // Update user data in Firestore
  Future<void> updateUserData({
    UserRole? userRole,
    String? email,
    String? lastName,
    String? firstName,
    String? middleName,
    String? phoneNumber,
    String? sex,
    String? birthMonth,
    String? birthDay,
    String? birthYear,
    String? address,
  }) async {
    Map<String, dynamic> updatedData = {};
    if (userRole != null) {
      updatedData['userRole'] = userRole.toString().split('.').last;  // Saves enum as a string
    }
    if (email != null) updatedData['email'] = email;
    if (lastName != null) updatedData['lastName'] = lastName;
    if (firstName != null) updatedData['firstName'] = firstName;
    if (middleName != null) updatedData['middleName'] = middleName;
    if (phoneNumber != null) updatedData['phoneNumber'] = phoneNumber;
    if (sex != null) updatedData['sex'] = sex;
    if (birthMonth != null) updatedData['birthMonth'] = birthMonth;
    if (birthDay != null) updatedData['birthDay'] = birthDay;
    if (birthYear != null) updatedData['birthYear'] = birthYear;
    if (address != null) updatedData['address'] = address;

    if (updatedData.isNotEmpty) {
      await userCollection.doc(uid).set(updatedData, SetOptions(merge: true));
    }
  }

  // Method to add a vital record
  Future<void> addVitalRecord(String vital, double inputRecord) async {
    // // Check if uid is not null
    // if (uid != null) {
    //   print('To add vital inside: $uid');
    //   // Create a new record document under the 'heart_rate' subcollection
    //   DocumentReference docRef = userCollection
    //       .doc(uid) // Reference to the specific user
    //       .collection('vitals') // Accessing the vitals subcollection
    //       .doc(vital); // Document for the vital

    //   // Get a reference to the 'records' subcollection within the vital
    //   CollectionReference recordsRef = docRef.collection('records');

    //   // Create a new record with a timestamp and value
    //   await recordsRef.add({
    //     'timestamp': FieldValue.serverTimestamp(), // Automatically set to server time
    //     'value': inputRecord,
    //   });

    //   print('Added vital: $uid');
    // } else {
    //   //throw Exception("User ID is null. Cannot add heart rate record.");
    //   print('User ID is null. Cannot add vital record.');
    // }
    print('Add vital: $vital $inputRecord');  // print for now, problems with permission
  }

  // Fetch user data from Firestore
  Future<UserData?> getUserData() async {
    try {
      DocumentSnapshot snapshot = await userCollection.doc(uid).get();
      if (snapshot.exists) {
        return _userDataFromSnapshot(snapshot);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Convert DocumentSnapshot to UserData
  UserData _userDataFromSnapshot(DocumentSnapshot snapshot) {
    print('_userDataFromSnapshot: $snapshot');
    return UserData(
      userRole: UserData.getUserRoleFromString(snapshot['userRole']),
      email: snapshot['email'],
      lastName: snapshot['lastName'],
      firstName: snapshot['firstName'],
      middleName: snapshot['middleName'],
      phoneNumber: snapshot['phoneNumber'],
      sex: snapshot['sex'],
      birthMonth: snapshot['birthMonth'],
      birthDay: snapshot['birthDay'],
      birthYear: snapshot['birthYear'],
      address: snapshot['address'],
    );
  }

  // Stream of user list data
  Stream<List<UserData>> get users {
    return userCollection.snapshots().map(_userListFromSnapshot);
  }

  // Stream to get user data
  Stream<UserData>? get userData {
    print('Get userdata: $uid');
    return userCollection.doc(uid).snapshots().map(_userDataFromSnapshot);
  }

  // Convert QuerySnapshot to List<UserData>
  List<UserData> _userListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc){
      return UserData(
        userRole: UserData.getUserRoleFromString(doc.get('userRole')),
        email: doc.get('email') ?? 'none',
        lastName: doc.get('lastName') ?? 'none',
        firstName: doc.get('firstName') ?? 'none',
        middleName: doc.get('middleName') ?? 'none',
        phoneNumber: doc.get('phoneNumber') ?? 'none',
        sex: doc.get('sex') ?? 'none',
        birthMonth: doc.get('birthMonth') ?? 'none',
        birthDay: doc.get('birthDay') ?? 'none',
        birthYear: doc.get('birthYear') ?? 'none',
        address: doc.get('address') ?? 'none',
      );
    }).toList();
  }
}