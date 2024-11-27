// ignore_for_file: avoid_print, unnecessary_nullable_for_final_variable_declarations

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

  // Cache to store user data
  MyUser? _cachedUser;

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
    if (user == null) return null;

    try {
      if (_cachedUser != null && _cachedUser!.uid == user.uid) {
        return _cachedUser; // Return cached data if available
      }

      UserData? userData = await DatabaseService(uid: user.uid).getUserData();
      if (userData != null) {
        _cachedUser = MyUser(
          uid: user.uid,
          isVerified: userData.isVerified,
          newUser: userData.newUser,
          profileImageUrl: userData.profileImageUrl, // Pass profileImageUrl
        );
        return _cachedUser;
      } else {
        debugPrint("No user data found for UID: ${user.uid}");
      }
    } catch (e) {
      debugPrint("Error fetching user data from Firestore: ${e.toString()}");
    }

    return null;
  }

  Stream<MyUser?> get user {
    return _auth.authStateChanges().map((User? user) {
      if (user != null) {
        return MyUser(
          uid: user.uid,
          isVerified: user.emailVerified,
          profileImageUrl:
              user.photoURL ?? '', // Default to empty if no photo URL
        );
      } else {
        return null;
      }
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

  Future<void> _initializeUserDocument({
    required String uid,
    required String email,
    required bool isVerified,
    required bool newUser,
    String? profileImageUrl, // Optional parameter for profile image URL
  }) async {
    await DatabaseService(uid: uid).updateUserData(
      userRole: UserRole.patient,
      email: email,
      isVerified: isVerified,
      newUser: newUser,
      dateCreated: DateTime.now(),
      profileImageUrl: profileImageUrl,
    );

    // Initialize user document with status field and profileImageUrl as empty string if null
    await _firestore.collection('users').doc(uid).set({
      'contacts': {
        'friends': {},
        'pending': {},
        'requests': {},
      },
      'notifications': [],
      'profileImageUrl': profileImageUrl ?? '',
      'status': 'stable',
    }, SetOptions(merge: true));
  }

  Future<MyUser?> signUpWithEmailAndPassword(String email, String password,
      {String? profileImageUrl}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user == null) return null;

      // Clear the cache after successful sign-up
      _cachedUser = null;

      await _initializeUserDocument(
        uid: user.uid,
        email: email,
        isVerified: false,
        newUser: true,
        profileImageUrl: profileImageUrl, // Pass profileImageUrl here
      );

      // Set cached user data
      _cachedUser = MyUser(
        uid: user.uid,
        isVerified: false,
        profileImageUrl: profileImageUrl ?? '', // Set profileImageUrl
        newUser: true,
      );

      return _cachedUser; // Return cached user data
    } catch (e) {
      debugPrint("Sign up error: ${e.toString()}");
      return null;
    }
  }

  Future<MyUser?> signInWithGoogle() async {
    try {
      // Sign in with Google
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("Google sign-in aborted by user.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user == null) {
        debugPrint("Google sign-in failed, user is null.");
        return null;
      }

      // Clear the cache when new user logs in
      _cachedUser = null;

      final email = user.email; // Access email directly from the User object
      if (email != null) {
        bool userExists = await emailExists(email);

        if (!userExists) {
          // Set profileImageUrl to a default if no image is present
          String? profileImageUrl =
              googleUser.photoUrl ?? ''; // Default to empty if no photo URL
          await _initializeUserDocument(
            uid: user.uid,
            email: email,
            isVerified: true,
            newUser: true, // Mark as new
            profileImageUrl:
                profileImageUrl, // Pass profileImageUrl to initialize
          );
        }

        UserData? userData = await DatabaseService(uid: user.uid).getUserData();

        if (userData == null) {
          debugPrint("No user data found for UID: ${user.uid}");
          return null;
        }

        // Set cached user data without email in MyUser
        _cachedUser = MyUser(
          uid: user.uid,
          isVerified: userData.isVerified,
          newUser: userData.newUser,
          profileImageUrl: userData.profileImageUrl, // Pass profileImageUrl
        );

        return _cachedUser; // Return cached user data
      }
    } catch (e) {
      debugPrint("Google sign-in error: ${e.toString()}");
    }
    return null;
  }

  Future<void> setUserVerificationStatus(String uid, bool isVerified) async {
    await _firestore.collection('users').doc(uid).update({
      'isVerified': isVerified,
    });
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out from Firebase
      await _googleSignIn.signOut(); // Sign out from Google
      _cachedUser = null; // Clear cached user data
      debugPrint("User signed out and cache cleared.");
    } catch (e) {
      debugPrint("Error signing out: $e");
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
