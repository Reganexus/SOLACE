// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/user_data_form.dart';
import 'package:solace/screens/home/home.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);

    if (user == null) {
      debugPrint("Loading edit user profile...");
      return const Center(
          child: CircularProgressIndicator()); // Loading indicator
    }

    return FutureBuilder<UserData?>(
      future: DatabaseService(uid: user.uid).getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData) {
          return const Center(child: Text("No user data found"));
        }

        final userData = snapshot.data;

        // Show alert dialog if the user is a new user
        if (userData?.newUser ?? false) {
          Future.delayed(Duration.zero, () {
            _showNewUserAlert(context);
          });
        }

        return PopScope(
          canPop: !(userData?.newUser ?? true), // Allow pop if not newUser
          onPopInvokedWithResult: (bool canPop, dynamic result) {
            // If the user hasn't completed the form, show the alert dialog
            if (userData?.newUser ?? false) {
              _showAlertDialog(context);
              return; // Don't allow pop
            }
            // Otherwise, allow the pop
          },
          child: Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppBar(
              title: const Text('Edit Profile'),
              backgroundColor: AppColors.white,
              scrolledUnderElevation: 0.0,
              automaticallyImplyLeading: !(userData?.newUser ??
                  true), // Show back button if newUser is false
            ),
            body: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus(); // Dismiss the keyboard
              },
              child: SingleChildScrollView(
                child: Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
                  child: Column(
                    children: [
                      UserDataForm(
                        isSignUp: false,
                        userData: userData,
                        newUser:
                            true, // Set as true since this is the first time the user is filling the profile
                        onButtonPressed: ({
                          required String firstName,
                          required String lastName,
                          required String middleName,
                          required String phoneNumber,
                          required String gender,
                          required DateTime? birthday,
                          required String address,
                        }) async {
                          try {
                            await DatabaseService(uid: user.uid).updateUserData(
                              firstName: firstName,
                              lastName: lastName,
                              middleName: middleName,
                              phoneNumber: phoneNumber,
                              gender: gender,
                              birthday: birthday,
                              address: address,
                              newUser:
                                  false, // Ensure newUser is set to false once profile is completed
                            );

                            // Navigate to Home after successful profile update
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => Home()),
                                (Route<dynamic> route) =>
                                    false, // Remove all previous routes
                              );
                            }
                          } catch (e) {
                            print("Error updating profile: $e");
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Function to show an alert dialog informing the user they need to fill the form
  void _showNewUserAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text(
            'Profile Setup Required',
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: const Text(
            'Please fill out the form to complete your profile.',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.normal,
              color: AppColors.black,
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                backgroundColor: AppColors.neon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to show an alert dialog when the user tries to leave the screen without completing the form
  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text(
            'Profile Incomplete',
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: const Text(
            'Please fill out the entire form before proceeding.',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.normal,
              color: AppColors.black,
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                backgroundColor: AppColors.neon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
