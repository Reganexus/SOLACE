import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/screens/authenticate/verify.dart';
import 'package:solace/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/globals.dart';
import 'package:solace/shared/widgets/user_editprofile.dart';
import 'package:solace/themes/colors.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  late final StreamSubscription<User?> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update UI based on auth state
          debugPrint("User auth state changed, updating UI.");
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the subscription to avoid memory leaks
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.neon),
            );
          }

          if (!snapshot.hasData) {
            debugPrint("No user found, navigating to Authenticate screen.");
            // User is signed out
            return Authenticate();
          }

          final user = snapshot.data;
          if (user != null) {
            // Check Firestore for user details
            return FutureBuilder<DocumentSnapshot>(
              future: DatabaseService(uid: user.uid).userCollection.doc(user.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppColors.neon));
                }

                if (userSnapshot.hasError) {
                  return Center(child: Text('Error: ${userSnapshot.error}'));
                }

                if (userSnapshot.hasData && userSnapshot.data != null) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                  bool isVerified = userData['isVerified'] ?? false;
                  bool newUser = userData['newUser'] ?? false;

                  if (emailVerificationEnabled && !isVerified) {
                    return Verify();
                  } else if (newUser) {
                    return EditProfileScreen();
                  } else {
                    return Home();
                  }
                }

                return Center(child: CircularProgressIndicator(color: AppColors.neon));
              },
            );
          }

          // Fallback if no user found
          return Authenticate();
        },
      ),
    );
  }
}
