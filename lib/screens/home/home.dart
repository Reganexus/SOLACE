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
import 'package:solace/screens/authenticate/verify.dart';
import 'package:solace/shared/accountflow/rolechooser.dart';
import 'package:solace/shared/globals.dart';
import 'package:solace/themes/colors.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final CollectionReference userCollection = DatabaseService().userCollection;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);

    debugPrint("Current user from Provider: $user");

    // Redirect to the authentication screen if user is null
    if (user == null) {
      debugPrint("User is null, navigating to Authenticate screen.");
      return const Authenticate();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: userCollection.doc(user.uid).get(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.neon,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.white),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          debugPrint("Error fetching user data: ${snapshot.error}");
          return Scaffold(
            backgroundColor: AppColors.neon,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'An error occurred while fetching user data.',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Retry logic: Trigger a rebuild
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.neon,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Success state: Parse user data
        if (snapshot.hasData && snapshot.data != null) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;

          // If no user data is found, default to PatientHome
          if (userData == null) {
            debugPrint("User data is null, navigating to PatientHome.");
            return const PatientHome();
          }

          final String userRole = userData['userRole'] ?? UserRole.patient.toString();
          final bool isVerified = userData['isVerified'] ?? false;
          final bool newUser = userData['newUser'] ?? false;

          // Unverified users
          if (emailVerificationEnabled && !isVerified) {
            debugPrint("Email verification required, navigating to Verify screen.");
            return const Verify();
          }

          // Redirect new users to profile setup
          if (newUser) {
            debugPrint("New user detected, navigating to EditProfileScreen.");
            return const RoleChooser();
          }

          // Route based on user role
          debugPrint("User role is $userRole, navigating to respective home screen.");
          switch (userRole) {
            case 'admin':
              return const AdminHome();
            case 'family':
              return const FamilyHome();
            case 'caregiver':
              return const CaregiverHome();
            case 'doctor':
              return const DoctorHome();
            default:
              return const PatientHome();
          }
        }

        // Default state: No data found
        debugPrint("No user data found in Firestore.");
        return Scaffold(
          backgroundColor: AppColors.neon,
          body: const Center(
            child: Text(
              'User data not found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
