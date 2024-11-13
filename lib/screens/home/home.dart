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
import 'package:solace/shared/globals.dart';
import 'package:solace/shared/widgets/user_editprofile.dart';
import 'package:solace/themes/colors.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  final CollectionReference userCollection = DatabaseService().userCollection;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);
    debugPrint("Current user from Provider: $user");

    if (user == null) {
      debugPrint("User is null, navigating to Authenticate screen.");
      return Authenticate();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: userCollection.doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.neon),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error fetching user data: ${snapshot.error}'),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Retry logic: trigger a rebuild to refetch data
                    setState(() {});
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData == null) {
            debugPrint("User data is null, navigating to PatientHome.");
            return PatientHome();
          }

          // Fetch user role, isVerified, and newUser flags
          String userRole = userData['userRole'] ?? UserRole.patient.toString();
          bool isVerified = userData['isVerified'] ?? false;
          bool newUser = userData['newUser'] ?? false;

          // Handle unverified users with email verification enabled
          if (emailVerificationEnabled && !isVerified) {
            return Verify();
          }

          // Direct new users to the profile setup screen
          if (newUser) {
            return EditProfileScreen();
          }

          // Route user based on their role
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
          debugPrint("No user data found in Firestore.");
          return Center(child: Text('User data not found'));
        }
      },
    );
  }
}
