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
    bool? isAdmin, // Add isAdmin parameter
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
    if (isAdmin != null) {
      updatedData['isAdmin'] = isAdmin; // Include isAdmin in updatedData
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
    if (address != null) updatedData['address'] = address; // Add this line

    if (updatedData.isNotEmpty) {
      await userCollection.doc(uid).set(updatedData, SetOptions(merge: true));
    }
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
    return UserData(
      uid: snapshot.id, // Capture the document ID as uid
      isAdmin: snapshot['isAdmin'] ?? false,
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
  Stream<UserData?> get userData {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return UserData(
          uid: snapshot.id, // Provide the uid here
          isAdmin: snapshot['isAdmin'] ?? false,
          email: snapshot['email'] ?? '',
          firstName: snapshot['firstName'],
          lastName: snapshot['lastName'],
          middleName: snapshot['middleName'],
          phoneNumber: snapshot['phoneNumber'],
          sex: snapshot['sex'],
          birthMonth: snapshot['birthMonth'],
          birthDay: snapshot['birthDay'],
          birthYear: snapshot['birthYear'],
          address: snapshot['address'],
        );
      } else {
        return null; // No user data found
      }
    });
  }


  // Convert QuerySnapshot to List<UserData>
  List<UserData> _userListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return UserData(
        uid: doc.id, // Include uid here
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

}
