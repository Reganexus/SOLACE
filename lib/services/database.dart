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

    // Only execute if there are fields to set
    if (updatedData.isNotEmpty) {
      return await userCollection.doc(uid).set(updatedData, SetOptions(merge: true));
    }
  }

  // Method to add a vital record
  Future<void> addVitalRecord(String vital, int inputRecord) async {
    // Check if uid is not null
    if (uid != null) {
      // Create a new record document under the 'heart_rate' subcollection
      DocumentReference docRef = userCollection
          .doc(uid) // Reference to the specific user
          .collection('vitals') // Accessing the vitals subcollection
          .doc(vital); // Document for the vital

      // Get a reference to the 'records' subcollection within the vital
      CollectionReference recordsRef = docRef.collection('records');

      // Create a new record with a timestamp and value
      await recordsRef.add({
        'timestamp': FieldValue.serverTimestamp(), // Automatically set to server time
        'value': inputRecord,
      });
    } else {
      //throw Exception("User ID is null. Cannot add heart rate record.");
      print('User ID is null. Cannot add vital record.');
    }
  }

  // user list from snapshot
  List<UserData> _userListFromSnapshot(QuerySnapshot snapshot) {
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
  Stream<List<UserData>> get users {
    return userCollection.snapshots().map(_userListFromSnapshot);
  }

  // get user doc stream
  Stream<UserData>? get userData {
    return userCollection.doc(uid).snapshots().map(_userDataFromSnapshot);
  }
}