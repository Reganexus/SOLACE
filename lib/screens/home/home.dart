// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/admin/admin_home.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/screens/caregiver/caregiver_home.dart';
import 'package:solace/screens/doctor/doctor_home.dart';
import 'package:solace/screens/family/family_home.dart';
import 'package:solace/screens/patient/patient_home.dart';
import 'package:solace/services/database.dart';
import 'package:solace/screens/authenticate/verify.dart'; // Import your verify screen

class Home extends StatelessWidget {
  final CollectionReference userCollection = DatabaseService().userCollection;

  Home({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);
    debugPrint("Current user from Provider: $user");

    if (user == null) {
      debugPrint("User is null. Redirecting to Authenticate screen.");
      return Authenticate();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: userCollection.doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint("Loading user data...");
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint("Error fetching user data: ${snapshot.error}");
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error fetching user data: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () {
                    // Implement retry logic or navigate to a safe screen
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          debugPrint("User data found: ${snapshot.data}");
          final userData = snapshot.data!.data();
          if (userData == null) {
            debugPrint("User data is null, navigating to PatientHome.");
            return PatientHome();
          }

          var userMap = userData as Map<String, dynamic>;
          String userRole = userMap['userRole']?.toString() ?? UserRole.patient.toString();
          bool isVerified = userMap['isVerified'] ?? false;
          debugPrint('User role retrieved: $userRole');
          debugPrint('User isVerified status: $isVerified');

          if (!isVerified) {
            debugPrint("User is not verified. Redirecting to Verify screen.");
            return Verify();
          }

          debugPrint("User is verified. Redirecting to respective home screen for role: $userRole");

          switch (userRole) {
            case 'admin':
              return AdminHome();
            case 'family':
              return FamilyHome();
            case 'caregiver':
              return CaregiverHome();
            case 'doctor':
              return DoctorHome();
            default:
              return PatientHome();
          }
        } else {
          debugPrint("No user data found in Firestore. Showing default message.");
          return Center(child: Text('User data not found'));
        }
      },
    );
  }
}

