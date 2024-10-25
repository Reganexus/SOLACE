import 'package:firebase_auth/firebase_auth.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // create MyUser object based on User
  MyUser? _userFromFirebaseUser(User? user) {
    return user != null ? MyUser(uid: user.uid) : null;
  }

  // auth change user stream
  Stream<MyUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  //log in anonymously
  Future signInAnon() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // log in with email and password
  Future logInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      print('Logged in user: $user');
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.hashCode);
      return null;
    } 
  }

  // sign up with email and password
  Future signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if(user == null) return null;

      print('New user id: ${user.uid}');
      // create a new document for the user with the uid (test values)
      await DatabaseService(uid: user.uid).updateUserData(
        isAdmin: false,
        email: email,
        lastName: '',
        firstName: '',
        middleName: '',
        phoneNumber: '',
        sex: 'Other',
        birthMonth: 'January',
        birthDay: '1',
        birthYear: (DateTime.now().year).toString(),
      );
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.hashCode);
      return null;
    } 
  }

  // sign out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}