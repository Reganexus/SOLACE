// ignore_for_file: avoid_print, unnecessary_nullable_for_final_variable_declarations, unreachable_switch_default

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:flutter/foundation.dart';
import 'package:solace/controllers/cloud_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize GoogleSignIn instance
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Cache to store user data
  MyUser? _cachedUser;

  String getCollectionName(UserRole role) {
    switch (role) {
      case UserRole.caregiver:
        return 'caregiver';
      case UserRole.admin:
        return 'admin';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.patient:
        return 'patient';
      case UserRole.unregistered:
        return 'unregistered';
      default:
        throw UnimplementedError();
    }
  }

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

  Future<User?> currentUser() async {
    return _auth.currentUser;
  }

  Future<DocumentSnapshot> getUserDocument(String uid, String userRole) async {
    final String collectionName =
        userRole; // Dynamically create collection name
    try {
      return await _firestore.collection(collectionName).doc(uid).get();
    } catch (e) {
      debugPrint('Failed to fetch user document: $e');
      throw Exception('Failed to fetch user document: $e');
    }
  }

  String? get currentUserId => _auth.currentUser?.uid;

  static String? getUserRoleString(UserRole role) {
    switch (role) {
      case UserRole.caregiver:
        return 'caregiver';
      case UserRole.admin:
        return 'admin';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.patient:
        return 'patient';
      case UserRole.unregistered:
        return 'unregistered';
      default:
        throw UnimplementedError();
    }
  }

  Future<bool> emailExists(String email, String userRole) async {
    final String collectionName =
        userRole; // Dynamically create collection name
    final QuerySnapshot result = await _firestore
        .collection(collectionName)
        .where('email', isEqualTo: email)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<bool> emailExistsAcrossCollections(String email) async {
    try {
      // List of role-based collections
      List<String> collections = [
        'admin',
        'doctor',
        'caregiver',
        'patient',
        'unregistered'
      ];

      for (String collection in collections) {
        final QuerySnapshot result = await _firestore
            .collection(collection)
            .where('email', isEqualTo: email)
            .get();

        if (result.docs.isNotEmpty) {
          return true; // Email found in one of the collections
        }
      }

      return false; // Email not found in any collection
    } catch (e) {
      debugPrint('Error checking email across collections: $e');
      return false; // Return false if there's an error
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

  Future<void> _fetchAndSaveFCMToken({int retryCount = 0}) async {
    try {
      await CloudMessagingService.fetchAndSaveToken();
      debugPrint("FCM token saved successfully.");
    } catch (e) {
      if (retryCount < 3) {
        final delay =
            Duration(seconds: 2 * (retryCount + 1)); // Exponential backoff
        await Future.delayed(delay);
        await _fetchAndSaveFCMToken(retryCount: retryCount + 1);
      } else {
        debugPrint("Error fetching and saving FCM token after retries: $e");
      }
    }
  }

  Future<void> initializeUserDocument({
    required String uid,
    required String email,
    required bool isVerified,
    required bool newUser,
    required UserRole userRole,
    String? profileImageUrl,
  }) async {
    try {
      debugPrint("Starting initializeUserDocument for UID: $uid");
      final unregisteredRef = _firestore.collection('unregistered').doc(uid);

      // Check if the document exists
      final userDoc = await unregisteredRef.get();
      debugPrint("Checking if user document exists for UID: $uid");

      // If the document doesn't exist, initialize it
      if (!userDoc.exists) {
        debugPrint(
            "User document does not exist. Creating new document for UID: $uid");
        try {
          await unregisteredRef.set({
            'email': email,
            'isVerified': isVerified,
            'newUser': newUser,
            'profileImageUrl': profileImageUrl ?? '',
            'userRole': UserRole.unregistered.name,
            'dateCreated': DateTime.now(),
            'contacts': {'friends': {}, 'requests': {}},
            'notifications': [],
            'status': 'stable',
            'symptoms': [],
          }, SetOptions(merge: true));

          debugPrint("Document successfully created for UID: $uid");
        } catch (e) {
          debugPrint("Error creating document for UID: $uid: $e");
        }

        debugPrint(
            "User document successfully created in 'unregistered' for UID: $uid");
      } else {
        debugPrint(
            "User document already exists in 'unregistered' for UID: $uid");
      }

      // Fetch and save the FCM token
      debugPrint("Fetching and saving FCM token for UID: $uid");
      await _fetchAndSaveFCMToken();
      debugPrint("FCM token fetched and saved for UID: $uid");
    } catch (e) {
      debugPrint("Error initializing user document for UID: $uid. Error: $e");
    }
  }

  Future<MyUser?> signUpWithEmailAndPassword(String email, String password,
      {String? profileImageUrl}) async {
    try {
      debugPrint("Starting signUpWithEmailAndPassword for email: $email");
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user == null) {
        debugPrint("Sign-up failed: user is null for email: $email");
        return null;
      }

      debugPrint("Sign-up successful for UID: ${user.uid}");

      // Clear the cache after successful sign-up
      _cachedUser = null;

      // Initialize user document
      await initializeUserDocument(
        uid: user.uid,
        email: email,
        isVerified: false,
        newUser: true,
        userRole: UserRole.unregistered,
        profileImageUrl: profileImageUrl,
      );

      debugPrint("User document initialized for UID: ${user.uid}");

      // Set cached user data
      _cachedUser = MyUser(
        uid: user.uid,
        isVerified: false,
        profileImageUrl: profileImageUrl ?? '',
        newUser: true,
      );

      debugPrint("Cached user data set for UID: ${user.uid}");
      return _cachedUser; // Return cached user data
    } catch (e) {
      debugPrint("Sign-up error for email: $email. Error: ${e.toString()}");
      return null;
    }
  }

  Future<MyUser?> signInWithGoogle() async {
    try {
      debugPrint("Starting signInWithGoogle");
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint("Google sign-in aborted by user.");
        return null;
      }

      debugPrint("Google sign-in successful. Fetching credentials.");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user == null) {
        debugPrint("Google sign-in failed: user is null.");
        return null;
      }

      debugPrint("Google sign-in successful for UID: ${user.uid}");

      // Clear the cache when a new user logs in
      _cachedUser = null;

      final email = user.email; // Access email directly from the User object
      if (email != null) {
        debugPrint("Checking if email exists across collections: $email");
        // Check if email exists across all role-based collections
        bool userExists = await emailExistsAcrossCollections(email);

        if (!userExists) {
          debugPrint(
              "User email not found in collections. Initializing new user document for UID: ${user.uid}");
          String? profileImageUrl = googleUser.photoUrl ?? '';
          await initializeUserDocument(
            uid: user.uid,
            email: email,
            isVerified: true,
            newUser: true,
            userRole: UserRole.unregistered,
            profileImageUrl: profileImageUrl,
          );
        } else {
          debugPrint("User email already exists in collections: $email");
        }

        // Fetch user data after checking or initializing
        debugPrint("Fetching user data for UID: ${user.uid}");
        UserData? userData = await DatabaseService(uid: user.uid).getUserData();

        if (userData == null) {
          debugPrint("No user data found for UID: ${user.uid}");
          return null;
        }

        debugPrint("User data fetched successfully for UID: ${user.uid}");

        // Cache user data
        _cachedUser = MyUser(
          uid: user.uid,
          isVerified: userData.isVerified,
          newUser: userData.newUser,
          profileImageUrl: userData.profileImageUrl,
        );

        debugPrint("Cached user data set for UID: ${user.uid}");
        return _cachedUser; // Return cached user data
      }
    } catch (e) {
      debugPrint("Google sign-in error: ${e.toString()}");
    }
    return null;
  }

  Future<void> setUserVerificationStatus(
      String uid, bool isVerified, String userRole) async {
    final String collectionName =
        userRole; // Dynamically create collection name
    try {
      await _firestore.collection(collectionName).doc(uid).update({
        'isVerified': isVerified,
      });
    } catch (e) {
      debugPrint('Failed to update verification status: $e');
      throw Exception('Failed to update verification status: $e');
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Sign out from Google
      await _googleSignIn.signOut();

      // Clear cached user data
      _cachedUser = null;

      await FirebaseFirestore.instance.clearPersistence();

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
