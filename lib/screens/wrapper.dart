// ignore_for_file: unused_import

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/screens/authenticate/verify.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/globals.dart';
import 'package:solace/shared/widgets/user_editprofile.dart';
import 'package:solace/themes/colors.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the user state from the provider
    final MyUser? user = Provider.of<MyUser?>(context);

    if (user == null) {
      debugPrint("No user found, navigating to Authenticate screen.");
      // User is signed out
      return const Authenticate();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: DatabaseService(uid: user.uid).userCollection.doc(user.uid).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.neon),
          );
        }

        if (userSnapshot.hasError) {
          debugPrint('Error fetching user data: ${userSnapshot.error}');
          return Center(child: Text('Error: ${userSnapshot.error}'));
        }

        if (userSnapshot.hasData && userSnapshot.data != null) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          bool isVerified = userData['isVerified'] ?? false;
          bool newUser = userData['newUser'] ?? false;

          if (emailVerificationEnabled && !isVerified) {
            return const Verify();
          } else if (newUser) {
            return const EditProfileScreen();
          } else {
            return const Home();
          }
        }

        return Center(
          child: CircularProgressIndicator(color: AppColors.neon),
        );
      },
    );
  }
}
