// ignore_for_file: avoid_print, unnecessary_nullable_for_final_variable_declarations, unreachable_switch_default

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/controllers/messaging_service.dart';
import 'package:solace/services/log_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final LogService _logService;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestoreInstance,
    GoogleSignIn? googleSignInInstance,
    LogService? logServiceInstance,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestoreInstance ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignInInstance ?? GoogleSignIn(),
       _logService = logServiceInstance ?? LogService();

  MyUser? _cachedUser;
  String? get currentUserId => _auth.currentUser?.uid;

  Future<bool> userExists(String email) async {
    final userData = await DatabaseService(uid: '').getUserDataByEmail(email);
    return userData != null;
  }

  Future<MyUser?> _userFromFirebaseUser(User? user) async {
    if (user == null) return null;

    try {
      if (_cachedUser != null && _cachedUser!.uid == user.uid) {
        return _cachedUser; // Return cached data if available
      }

      final userData = await DatabaseService(
        uid: user.uid,
      ).fetchUserData(user.uid);
      if (userData != null) {
        _cachedUser = MyUser(
          uid: user.uid,
          isVerified: userData.isVerified,
          newUser: userData.newUser,
          profileImageUrl: userData.profileImageUrl,
        );
        return _cachedUser;
      }
    } catch (e) {
      //       debugPrint("Error fetching user data from Firestore: $e");
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

  Future<String?> getToken() async {
    User? user = await currentUser();
    return await user?.getIdToken();
  }

  Future<DocumentSnapshot> getUserDocument(String uid, String userRole) async {
    final String collectionName =
        userRole; // Dynamically create collection name
    try {
      return await _firestore.collection(collectionName).doc(uid).get();
    } catch (e) {
      //       debugPrint('Failed to fetch user document: $e');
      throw Exception('Failed to fetch user document: $e');
    }
  }

  Future<bool> emailExists(String email, String userRole) async {
    final String collectionName = userRole;
    final QuerySnapshot result =
        await _firestore
            .collection(collectionName)
            .where('email', isEqualTo: email)
            .get();
    return result.docs.isNotEmpty;
  }

  Future<bool> emailExistsAcrossCollections(String email) async {
    try {
      final results = await Future.wait(
        UserRole.values.map((role) async {
          final collectionName = role.name;
          final query =
              await _firestore
                  .collection(collectionName)
                  .where('email', isEqualTo: email)
                  .limit(1)
                  .get();
          return query.docs.isNotEmpty;
        }),
      );
      return results.contains(true);
    } catch (e) {
      //       debugPrint("Error checking email existence: $e");
      return false;
    }
  }

  Future<MyUser?> logInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      await _logService.addLog(
        userId: user!.uid,
        action: 'Logged in with email and password',
      );

      return user != null ? await _userFromFirebaseUser(user) : null;
    } catch (e) {
      //       debugPrint("Log in error: ${e.toString()}");
      return null;
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
    final userDocRef = _firestore.collection('unregistered').doc(uid);

    try {
      // Check existence and create in one atomic Firestore operation
      await userDocRef.set({
        'email': email,
        'isVerified': isVerified,
        'newUser': newUser,
        'profileImageUrl': profileImageUrl ?? '',
        'userRole': userRole.name,
        'dateCreated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await MessagingService.fetchAndSaveToken();
    } catch (e) {
      throw Exception("Failed to initialize user document. Error: $e");
    }
  }

  Future<bool> signUpWithEmailAndPassword(
    String email,
    String password, {
    String? profileImageUrl,
  }) async {
    try {
      // Check if email exists in the deleted collection
      if (await emailExistsInDeletedCollection(email)) {
        //         debugPrint("Sign-up blocked: Email exists in the deleted collection.");
        throw FirebaseAuthException(
          code: 'email-deleted',
          message: 'This account was previously deleted by an admin.',
        );
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user == null) {
        return false;
      }

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

      await _logService.addLog(
        userId: user.uid,
        action: 'Created account with email and password',
      );

      // Set cached user data
      _cachedUser = MyUser(
        uid: user.uid,
        isVerified: false,
        profileImageUrl: profileImageUrl ?? '',
        newUser: true,
      );
      return true; // Indicate success
    } on FirebaseAuthException {
      // Rethrow so the UI can handle specific error codes
      rethrow;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  Future<MyUser?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final googleUser = await retryOperation(() => _googleSignIn.signIn());

      if (googleUser == null) {
        return null;
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user == null) {
        return null;
      }

      final email = user.email;
      if (email != null && await emailExistsInDeletedCollection(email)) {
        throw FirebaseAuthException(
          code: 'email-deleted',
          message: 'This account was previously deleted by an admin.',
        );
      }

      // Check or initialize user data
      if (email != null) {
        final emailExists = await emailExistsAcrossCollections(email);

        if (!emailExists) {
          await initializeUserDocument(
            uid: user.uid,
            email: email,
            isVerified: true,
            newUser: true,
            userRole: UserRole.unregistered,
            profileImageUrl: '',
          );
        }

        // Fetch and cache user data
        final userData = await DatabaseService(
          uid: user.uid,
        ).fetchUserData(user.uid);
        if (userData != null) {
          _cachedUser = MyUser(
            uid: user.uid,
            isVerified: userData.isVerified,
            newUser: userData.newUser,
            profileImageUrl: userData.profileImageUrl,
          );
          return _cachedUser;
        }
      }
    } catch (e) {
      if (kDebugMode) print("Error signing in with Google: $e");
      if (e is FirebaseAuthException) {
        if (kDebugMode) print("Firebase Auth Error Code: ${e.code}");
        if (kDebugMode) print("Firebase Auth Error Message: ${e.message}");
      }
      return null;
    }
    return null;
  }

  Future<bool> emailExistsInDeletedCollection(String email) async {
    final deletedUserDoc = await DatabaseService().getDeletedUserByEmail(email);
    return deletedUserDoc != null;
  }

  Future<T?> retryOperation<T>(
    Future<T?> Function() operation, {
    int retries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        return await operation();
      } catch (e) {
        //         debugPrint("Retrying operation due to error: $e");
        if (i == retries - 1) rethrow; // Rethrow if retries exhausted
        await Future.delayed(delay);
      }
    }
    return null;
  }

  Future<void> setUserVerificationStatus(
    String uid,
    bool isVerified,
    String userRole,
  ) async {
    final String collectionName =
        userRole; // Dynamically create collection name
    try {
      await _firestore.collection(collectionName).doc(uid).update({
        'isVerified': isVerified,
      });
    } catch (e) {
      //       debugPrint('Failed to update verification status: $e');
      throw Exception('Failed to update verification status: $e');
    }
  }

  Future<void> signOut() async {
    try {
      // Log the logout action
      if (currentUserId != null) {
        await _logService.addLog(userId: currentUserId!, action: 'Logged out');
      }

      // List of collections to search
      final List<String> collections = ['admin', 'doctor', 'nurse', 'caregiver'];

      // Search for the user ID in each collection and set isLoggedIn to false
      for (String collection in collections) {
        final userDoc = await _firestore.collection(collection).doc(currentUserId).get();
        if (userDoc.exists) {
          await _firestore.collection(collection).doc(currentUserId).update({
            'isLoggedIn': false,
          });
          break; // Exit the loop once the user is found
        }
      }

      // Sign out from Firebase Auth and Google Sign-In
      await _auth.signOut();
      await _googleSignIn.signOut();

      // Clear cached user data
      _cachedUser = null;

      // Log the logout action again (if needed)
      if (currentUserId != null) {
        await _logService.addLog(userId: currentUserId!, action: 'Logged out');
      }
    } catch (e) {
      //  debugPrint("Error signing out: $e");
    }
  }

  Future<bool?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return null;
    }
  }
}
