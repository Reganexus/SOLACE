import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/screens/authenticate/verify.dart';
import 'package:solace/screens/caregiver/caregiver_waiting_screen.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/accountflow/rolechooser.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final MyUser? user = Provider.of<MyUser?>(context);

    if (user == null) {
      return const Authenticate();
    }

    clearFieldsCache(user.uid);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUserDataWithRetries(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: AppColors.neon,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Loader.loaderWhite,
                SizedBox(height: 20),
                Text(
                  "Loading your data. Please wait.",
                  style: Textstyle.bodyWhite.copyWith(
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _errorScreen("Failed to load user data. Please try again.");
        }

        final userData = snapshot.data;
        if (userData != null) {
          final isVerified = userData['isVerified'] ?? false;
          final newUser = userData['newUser'] ?? true;
          final role = userData['userRole'];
          final hasAccess = userData['hasAccess'] ?? false;

          debugPrint("Has Access of user: $hasAccess");

          if (newUser && !isVerified) {
            return const Verify();
          } else if (newUser && isVerified) {
            return RoleChooser(onRoleSelected: (role) {});
          } else if (!newUser && isVerified && hasAccess == false) {
            return CaregiverWaitingScreen(userId: user.uid, userRole: role);
          } else if (!newUser && isVerified && hasAccess == true) {
            return Home(uid: user.uid, role: role);
          } else {
            return _errorScreen(
              "User verification failed. Please contact support.",
            );
          }
        } else {
          return Authenticate();
        }
      },
    );
  }

  Future<void> clearFieldsCache(String uid) async {
    final DatabaseService databaseService = DatabaseService();
    await databaseService.clearFormCache(uid);
  }

  Future<Map<String, dynamic>?> _fetchUserDataWithRetries(String uid) async {
    const maxRetries = 5;
    const retryDelay = Duration(seconds: 3);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Use fetchAndCacheUserRole instead of getTargetUserRole
        final String? role = await DatabaseService().fetchAndCacheUserRole(uid);
        if (role == null) {
          //           debugPrint("Role not found. Retrying...");
          await Future.delayed(retryDelay);
          continue;
        }

        final docSnapshot =
            await FirebaseFirestore.instance.collection(role).doc(uid).get();

        if (docSnapshot.exists) {
          return docSnapshot.data() as Map<String, dynamic>;
        } else {
          //           debugPrint("User document not found. Retrying...");
        }
      } catch (e) {
        //         debugPrint("Error fetching user data: $e");
      }

      await Future.delayed(retryDelay);
    }

    //     debugPrint("Max retries reached. User document not found.");
    return null;
  }

  Widget _errorScreen(String message) {
    return Scaffold(
      backgroundColor: AppColors.neon,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: Textstyle.error),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Authenticate();
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
}
