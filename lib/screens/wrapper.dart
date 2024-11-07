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
            ); // Loading indicator
          }

          if (!snapshot.hasData) {
            // No user signed in, show the authentication screen
            return Authenticate();
          }

          final user = snapshot.data;
          if (user != null) {
            // If user is signed in, we fetch their data
            return FutureBuilder<DocumentSnapshot>(
              future: DatabaseService(uid: user.uid).userCollection.doc(user.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppColors.neon)); // Loading indicator for user data
                }

                if (userSnapshot.hasError) {
                  return Center(child: Text('Error: ${userSnapshot.error}')); // Handle error
                }

                if (userSnapshot.hasData && userSnapshot.data != null) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                  bool isVerified = userData['isVerified'] ?? false;
                  bool newUser = userData['newUser'] ?? false;

                  if (emailVerificationEnabled && !isVerified) {
                    return Verify();
                  } else if (newUser) {
                    return EditProfileScreen(); // Redirect to EditProfile if new user
                  } else {
                    return Home(); // Redirect to Home if profile is completed
                  }
                }

                // If no data or the data is null, show loading
                return Center(child: CircularProgressIndicator(color: AppColors.neon));
              },
            );
          }

          // Fallback to Authenticate if no user is found
          return Authenticate(); // No user signed in
        },
      ),
    );
  }
}
