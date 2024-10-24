import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/models/firestore_user.dart';

class DatabaseService {

  final String? uid;
  DatabaseService({ this.uid });

  // collection reference
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');

  Future updateUserData(bool isAdmin, String lastName, String firstName, String middleName, String email) async {
    return await userCollection.doc(uid).set({
      'isAdmin': isAdmin,
      'lastName': lastName,
      'firstName': firstName,
      'middleName': middleName,
      'email': email
    });
  }

  // user list from snapshot
  List<FirestoreUser>? _userListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc){
      return FirestoreUser(
        isAdmin: doc.get('isAdmin') ?? false,
        lastName: doc.get('lastName') ?? '-',
        firstName: doc.get('firstName') ?? '-',
        middleName: doc.get('middleName') ?? '-',
        email: doc.get('email') ?? '-',
      );
    }).toList();
  }

  // get userCollection stream
  Stream<List<FirestoreUser>?>? get users {
    return userCollection.snapshots().map(_userListFromSnapshot);
  }
}