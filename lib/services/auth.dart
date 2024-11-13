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
      try {
        UserData? userData = await DatabaseService(uid: user.uid).getUserData();
        if (userData != null) {
          return MyUser(uid: user.uid, isVerified: userData.isVerified);
        } else {
          debugPrint("No user data found for UID: ${user.uid}, retrying...");
          await Future.delayed(
              const Duration(milliseconds: 500)); // Delay before retry
          userData = await DatabaseService(uid: user.uid).getUserData();
          return userData != null
              ? MyUser(uid: user.uid, isVerified: userData.isVerified)
              : null;
        }
      } catch (e) {
        debugPrint("Error fetching user data from Firestore: ${e.toString()}");
      }
    }
    return null;
  }

  Stream<MyUser?> get user {
    return _auth.authStateChanges().asyncMap((User? firebaseUser) async {
      if (firebaseUser != null) {
        // Fetch Firestore data for the user after auth state change
        UserData? userData =
            await DatabaseService(uid: firebaseUser.uid).getUserData();
        return userData != null
            ? MyUser(uid: firebaseUser.uid, isVerified: userData.isVerified)
            : null;
      }
      return null;
    });
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
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user == null) return null;
      debugPrint('New user id: ${user.uid}');

      // Set isVerified to false for email/password sign-ups
      await DatabaseService(uid: user.uid).updateUserData(
        userRole: UserRole.patient,
        email: email,
        isVerified: false,
        newUser: true,
      );

      // Initialize the contacts and notifications fields as empty
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {
            'contacts': {
              'friends': {},
              'pending': {},
              'requests': {},
            },
            'notifications': [], // Initialize empty notifications array
          },
          SetOptions(
              merge:
                  true)); // Merge ensures it does not overwrite existing data

      return MyUser(uid: user.uid, isVerified: false);
    } catch (e) {
      debugPrint("Sign up error: ${e.toString()}");
      return null;
    }
  }

  // Google Sign-In Method with Retry Logic
  Future<MyUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      // Retry mechanism: Confirm user is recognized before proceeding
      int retries = 3; // Max retries
      while (user == null && retries > 0) {
        await Future.delayed(const Duration(milliseconds: 500)); // Short delay
        user = _auth.currentUser;
        retries--;
      }

      if (user != null) {
        final email = user.email;

        // Check if user document already exists
        if (email != null && !await emailExists(email)) {
          // Create a new document if user does not exist
          await DatabaseService(uid: user.uid).updateUserData(
            userRole: UserRole.patient,
            email: email,
            isVerified: true,
            newUser: true,
          );

          await _firestore.collection('users').doc(user.uid).set({
            'contacts': {
              'friends': {},
              'requests': {},
            },
            'notifications': [], // Initialize empty notifications array
          }, SetOptions(merge: true));

          debugPrint('New user document created for email: $email');
        } else {
          debugPrint('User document already exists for email: $email');
        }

        // Explicitly update Provider with new user data
        await _updateProviderUser(user);

        return await _userFromFirebaseUser(user);
      }
    } catch (e) {
      debugPrint("Google sign-in error: ${e.toString()}");
    }
    return null;
  }

  // Manually update Provider to prevent mis-navigation due to null user
  Future<void> _updateProviderUser(User user) async {
    final userData = await DatabaseService(uid: user.uid).getUserData();
    if (userData != null) {
      // Optionally trigger a Provider update in your main app here if needed
      debugPrint("Provider manually updated with user: ${user.email}");
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

      // Ensure user is null after sign out
      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint('User successfully signed out and session cleared.');
      } else {
        debugPrint('Sign out incomplete, user still detected.');
      }
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
