// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create MyUser object based on User
  MyUser? _userFromFirebaseUser(User? user) {
    return user != null ? MyUser(uid: user.uid) : null;
  }

  // Auth change user stream
  Stream<MyUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // Getter for the current user
  User? get currentUser {
    return _auth.currentUser; // This returns the currently signed-in user
  }

  // Log in anonymously
  Future<MyUser?> signInAnon() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print("Sign in anon error: ${e.toString()}");
      return null;
    }
  }

  // Log in with email and password
  Future<MyUser?> logInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Log user in successfully, fetch user data here
        return _userFromFirebaseUser(user);
      }
      return null;
    } catch (e) {
      print("Log in error: ${e.toString()}");
      return null;
    }
  }

  // Sign up with email and password
  Future<MyUser?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user == null) return null;
      print('New user id: ${user.uid}');

      // Create a new document for the user with the uid (test values)
      await DatabaseService(uid: user.uid).updateUserData(
        userRole: UserRole.patient,
        email: email,
        lastName: '',
        firstName: '',
        middleName: '',
        phoneNumber: '',
        sex: 'Other',
        birthMonth: 'January',
        birthDay: '1',
        birthYear: (DateTime.now().year).toString(),
        address: '',
      );
      return _userFromFirebaseUser(user);
    } catch (e) {
      print("Sign up error: ${e.toString()}");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('User signed out');
    } catch (e) {
      print("Sign out error: ${e.toString()}");
    }
  }

  // Password Reset
  Future<bool?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to $email');
      return true;
    } catch (e) {
      print("Reset password error: ${e.toString()}");
      return null;
    }
  }
}
