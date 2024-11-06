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
      return userData != null
          ? MyUser(uid: user.uid, isVerified: userData.isVerified)
          : null;
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

  Future<MyUser?> logInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return user != null ? await _userFromFirebaseUser(user) : null;
    } catch (e) {
      debugPrint("Log in error: ${e.toString()}");
      return null;
    }
  }

  Future<MyUser?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      if (user == null) return null;
      debugPrint('New user id: ${user.uid}');

      // Set isVerified to false for email/password sign-ups
      await DatabaseService(uid: user.uid).updateUserData(
        userRole: UserRole.patient,
        email: email,
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
      // Google Sign-In process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication? googleAuth =
      await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Sign in to Firebase
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      if (user != null) {
        // Check if the user exists in Firestore
        final email = user.email;
        if (email != null && !await emailExists(email)) {
          // If the user does not exist, create a new document
          await DatabaseService(uid: user.uid).updateUserData(
            userRole: UserRole.patient, // Set default user role
            email: email,
            isVerified: true, // Set isVerified to true for new Google sign-ups
          );
          debugPrint('New user document created for email: $email');
        } else {
          debugPrint('User document already exists for email: $email');
        }

        // Fetch the user data again to ensure we have the latest data
        DocumentSnapshot userDataSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDataSnapshot.exists) {
          Map<String, dynamic> userData = userDataSnapshot.data() as Map<String, dynamic>;
          bool isVerified = userData['isVerified'] ?? false;

          return MyUser(uid: user.uid, isVerified: isVerified); // Return as verified
        } else {
          debugPrint("User data document does not exist after sign-in.");
          return null; // Handle this case if necessary
        }
      }
    } catch (e) {
      debugPrint("Google sign-in error: ${e.toString()}");
      return null;
    }
    return null;
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
