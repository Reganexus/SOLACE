// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize GoogleSignIn instance
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Check if a user exists with the given email
  Future<bool> userExists(String email) async {
    final userData = await DatabaseService(uid: '').getUserDataByEmail(email);
    return userData != null;
  }

  void displayValues() {
    print('Current User: ${_auth.currentUser}');
    print('Display name: ${_auth.currentUser?.displayName}');
    print('Email: ${_auth.currentUser?.email}');
    print('Email verified: ${_auth.currentUser?.emailVerified}');
    print('Is anonymous: ${_auth.currentUser?.isAnonymous}');
    print('Photo URL: ${_auth.currentUser?.photoURL}');
    print('Provider data: ${_auth.currentUser?.providerData}');
  }

  MyUser? _userFromFirebaseUser(User? user) {
    return user != null ? MyUser(uid: user.uid) : null;
  }

  Stream<MyUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  User? get currentUser {
    return _auth.currentUser;
  }

  Future<bool> emailExists(String email) async {
    final QuerySnapshot result = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    return result.docs.isNotEmpty;
  }

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

  Future<MyUser?> logInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return user != null ? _userFromFirebaseUser(user) : null;
    } catch (e) {
      print("Log in error: ${e.toString()}");
      return null;
    }
  }

  Future<MyUser?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user == null) return null;
      print('New user id: ${user.uid}');

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
        birthYear: DateTime.now().year.toString(),
        address: '',
      );
      return _userFromFirebaseUser(user);
    } catch (e) {
      print("Sign up error: ${e.toString()}");
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final userCredential = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        ),
      );

      // Check if the email already exists
      final emailExists = await this.emailExists(userCredential.user?.email ?? '');
      if (emailExists) {
        return null;
      }

      return userCredential;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      print('User signed out');
    } catch (e) {
      print("Sign out error: ${e.toString()}");
    }
  }

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
