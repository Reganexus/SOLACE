// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use

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
    debugPrint("User: ${user?.uid}");

    if (user == null) {
      debugPrint("Loading edit user profile...");
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<UserData?>(
      future: DatabaseService(uid: user.uid).getUserData(),
      builder: (context, snapshot) {
        debugPrint("Snapshot state: ${snapshot.connectionState}");

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData) {
          return const Center(child: Text("No user data found"));
        }

        final userData = snapshot.data;

        if (userData?.newUser ?? false) {
          Future.delayed(Duration.zero, () {
            _showNewUserAlert(context);
          });
        }

        return WillPopScope(
          onWillPop: () async {
            if (userData?.newUser ?? false) {
              _showAlertDialog(context);
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
                        newUser: true, // Set as true for new users
                        onButtonPressed: ({
                          required String firstName,
                          required String lastName,
                          required String middleName,
                          required String phoneNumber,
                          required String gender,
                          required DateTime? birthday,
                          required String address,
                        }) async {
                          await DatabaseService(uid: user.uid).updateUserData(
                            firstName: firstName,
                            lastName: lastName,
                            middleName: middleName,
                            phoneNumber: phoneNumber,
                            gender: gender,
                            birthday: birthday,
                            address: address,
                            newUser: false,
                          );
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const Home()),
                                  (Route<dynamic> route) => false,
                            );
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

  void _showNewUserAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text('Profile Setup Required'),
          content: const Text('Please fill out the form to complete your profile.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text('Profile Incomplete'),
          content: const Text('Please fill out the entire form before proceeding.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

