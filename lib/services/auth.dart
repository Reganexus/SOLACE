// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:flutter/foundation.dart';

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
    debugPrint('Current User: ${_auth.currentUser}');
    debugPrint('Display name: ${_auth.currentUser?.displayName}');
    debugPrint('Email: ${_auth.currentUser?.email}');
    debugPrint('Email verified: ${_auth.currentUser?.emailVerified}');
    debugPrint('Is anonymous: ${_auth.currentUser?.isAnonymous}');
    debugPrint('Photo URL: ${_auth.currentUser?.photoURL}');
    debugPrint('Provider data: ${_auth.currentUser?.providerData}');
  }

  Future<MyUser?> _userFromFirebaseUser(User? user) async {
    if (user != null) {
      // Fetch user data to determine the actual verification status
      UserData? userData = await DatabaseService(uid: user.uid).getUserData();
      return userData != null ? MyUser(uid: user.uid, isVerified: userData.isVerified) : null;
    }
    return null;
  }

  Stream<MyUser?> get user {
    return _auth.authStateChanges().asyncMap(_userFromFirebaseUser);
  }

  User? get currentUser {
    return _auth.currentUser;
  }

  String? get currentUserId => _auth.currentUser?.uid;

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
      return await _userFromFirebaseUser(user);
    } catch (e) {
      debugPrint("Sign in anon error: ${e.toString()}");
      return null;
    }
  }

  Future<MyUser?> logInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return user != null ? await _userFromFirebaseUser(user) : null;
    } catch (e) {
      debugPrint("Log in error: ${e.toString()}");
      return null;
    }
  }

  Future<MyUser?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user == null) return null;
      debugPrint('New user id: ${user.uid}');

      // Set isVerified to false for email/password sign-ups
      await DatabaseService(uid: user.uid).updateUserData(
        userRole: UserRole.patient,
        email: email,
        lastName: '',
        firstName: '',
        middleName: '',
        phoneNumber: '',
        gender: '',
        birthday: null,
        address: '',
        isVerified: false, // Set verification status to false initially
      );

      return MyUser(uid: user.uid, isVerified: false);
    } catch (e) {
      debugPrint("Sign up error: ${e.toString()}");
      return null;
    }
  }

  Future<MyUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      debugPrint("Google user selected: $googleUser");

      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      debugPrint("Google authentication object: $googleAuth");

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;
      if (user == null) {
        debugPrint("User object is null after Google sign-in.");
        return null;
      }

      debugPrint('User signed in with Google: ${user.uid}');

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        debugPrint("User does not exist in Firestore. Creating new user document.");
        await DatabaseService(uid: user.uid).updateUserData(
          userRole: UserRole.patient,
          email: user.email ?? '',
          lastName: '',
          firstName: '',
          middleName: '',
          phoneNumber: '',
          gender: '',
          birthday: null,
          address: '',
          isVerified: true, // Default to verified for Google sign-ins
        );
      } else {
        debugPrint("User exists in Firestore. Setting verification status to true.");
        await DatabaseService(uid: user.uid).setUserVerificationStatus(user.uid, true);
      }

      debugPrint("Returning MyUser object for user: ${user.uid}");
      return MyUser(uid: user.uid, isVerified: true);
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      return null;
    }
  }


  Future<void> setUserVerificationStatus(String uid, bool isVerified) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isVerified': isVerified,
    });
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      debugPrint('User signed out');
    } catch (e) {
      debugPrint("Sign out error: ${e.toString()}");
    }
  }

  Future<bool?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent to $email');
      return true;
    } catch (e) {
      debugPrint("Reset password error: ${e.toString()}");
      return null;
    }
  }
}
