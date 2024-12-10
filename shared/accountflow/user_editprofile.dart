// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use, dead_code, unnecessary_const

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/accountflow/user_data_form.dart';
import 'package:solace/screens/home/home.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _alertShown = false;
  bool _isUserFetched = false; // Track if user data has been fetched

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);
    debugPrint("User: ${user?.uid}");

    if (user == null) {
      debugPrint("Loading user data...");
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<UserData?>(
      future: DatabaseService(uid: user.uid).getUserData(),
      builder: (context, snapshot) {
        debugPrint("Snapshot state: ${snapshot.connectionState}");

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          debugPrint("Error in FutureBuilder: ${snapshot.error}");
          return Scaffold(
            body: Center(
              child: Text("Error: ${snapshot.error}"),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          debugPrint("No data found in FutureBuilder");
          return const Scaffold(
            body: Center(child: Text("No user data found.")),
          );
        }

        final userData = snapshot.data;

        // Prevent navigating to EditProfileScreen multiple times by checking if the user is already fetched
        if (userData?.newUser ?? false && !_isUserFetched) {
          Future.delayed(Duration.zero, () async {
            if (mounted && !_alertShown) {
              _alertShown = true; // Prevent showing the alert repeatedly
              await _showNewUserAlert(context); // Show alert only once
              setState(() {
                _isUserFetched = true; // Mark that user data has been fetched
              });
            }
          });
        }

        return WillPopScope(
          onWillPop: () async {
            if (userData.newUser) {
              if (mounted) {
                await _showAlertDialog(
                    context); // Check if mounted before showing dialog
              }
              return false; // Prevent pop if the user is new
            }
            return true; // Allow pop if profile is completed
          },
          child: Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppBar(
              title: const Text('Edit Profile'),
              backgroundColor: AppColors.white,
              scrolledUnderElevation: 0.0,
              automaticallyImplyLeading: !(userData?.newUser ?? true),
            ),
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
                  child: Column(
                    children: [
                      UserDataForm(
                        isSignUp: false,
                        userData: userData,
                        newUser: userData?.newUser ?? false,
                        userRole: userData!.userRole,
                        onButtonPressed: ({
                          required String firstName,
                          required String lastName,
                          required String middleName,
                          required String phoneNumber,
                          required String gender,
                          required DateTime? birthday,
                          required String address,
                          required String profileImageUrl,
                          required String religion,
                          required int age,
                          String? will, // Nullable
                          String? fixedWishes, // Nullable
                          String? organDonation, // Nullable
                        }) async {
                          // Now use userRole here
                          if (userData.userRole == UserRole.patient) {
                            await DatabaseService(uid: user.uid).updateUserData(
                              firstName: firstName,
                              lastName: lastName,
                              middleName: middleName,
                              phoneNumber: phoneNumber,
                              gender: gender,
                              birthday: birthday,
                              address: address,
                              profileImageUrl: profileImageUrl,
                              religion: religion,
                              newUser: false,
                              age: age,
                              will: will, // Pass will if patient
                              fixedWishes:
                                  fixedWishes, // Pass fixedWishes if patient
                              organDonation:
                                  organDonation, // Pass organDonation if patient
                            );
                          } else {
                            await DatabaseService(uid: user.uid).updateUserData(
                              firstName: firstName,
                              lastName: lastName,
                              middleName: middleName,
                              phoneNumber: phoneNumber,
                              gender: gender,
                              birthday: birthday,
                              address: address,
                              profileImageUrl: profileImageUrl,
                              religion: religion,
                              newUser: false,
                              age: age,
                            );
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Profile updated successfully')));
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Home()),
                              (Route<dynamic> route) => false,
                            );
                          }
                        },
                        age:
                            userData.age ?? 0, // Pass the correct value for age
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

  Future<void> _showNewUserAlert(BuildContext context) async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.white,
            title: const Text(
              'Profile Setup Required',
              style: const TextStyle(
                fontSize: 24,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            content: const Text(
              'Please fill out the form to complete your profile.',
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.normal,
                color: AppColors.black,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  backgroundColor: AppColors.neon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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

  Future<void> _showAlertDialog(BuildContext context) async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppColors.white,
            title: const Text(
              'Profile Incomplete',
              style: const TextStyle(
                fontSize: 24,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            content: const Text(
              'Please fill out the entire form before proceeding.',
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.normal,
                color: AppColors.black,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  backgroundColor: AppColors.neon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
}
