// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/screens/authenticate/verify.dart';
import 'package:solace/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/globals.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator()); // Loading indicator
          }

          if (snapshot.hasData) {
            final user = snapshot.data;
            if (user != null) {
              return FutureBuilder<DocumentSnapshot>(
                future: DatabaseService(uid: user.uid)
                    .userCollection
                    .doc(user.uid)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child:
                            CircularProgressIndicator()); // Loading indicator for user data
                  }

                  if (userSnapshot.hasError) {
                    return Center(
                        child: Text(
                            'Error: ${userSnapshot.error}')); // Handle error
                  }

                  if (userSnapshot.hasData && userSnapshot.data != null) {
                    final userData = userSnapshot.data!.data()
                        as Map<String, dynamic>?; // Cast to map
                    bool isVerified = userData?['isVerified'] ??
                        false; // Safe access with null check

                    debugPrint("OooLALALA User Data: $userData");
                    if (emailVerificationEnabled && !isVerified) {
                      return Verify(); // Redirect to Verify screen if not verified
                    } else {
                      return Home(); // Redirect to Home
                    }
                  } else {
                    return Center(
                        child:
                            Text('User data not found')); // Handle no user data
                  }
                },
              );
            }
          }

          return Authenticate(); // No user signed in
        },
      ),
    );
  }
}
