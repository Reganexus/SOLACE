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
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<UserData?>(
      future: DatabaseService(uid: user.uid).getUserData(),
      builder: (context, snapshot) {
        final stateWidget = _buildFutureState(snapshot);
        if (stateWidget != null) return stateWidget;

        final userData = snapshot.data!;

        if (userData.newUser) {
          Future.delayed(Duration.zero, () async {
            await _showNewUserAlert(context);
          });
        }

        return PopScope<void>(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) return;
            if (userData.newUser) {
              final bool shouldPop = await _showAlertDialog(context);
              if (context.mounted && shouldPop) {
                Navigator.pop(context);
              }
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppBar(
              title: const Text('Edit Profile'),
              backgroundColor: AppColors.white,
              scrolledUnderElevation: 0.0,
              automaticallyImplyLeading: false,
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
                        newUser: userData.newUser,
                        isVerified: userData.isVerified,
                        userRole: userData.userRole,
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
                        }) async {
                          await DatabaseService(uid: user.uid).updateUserData(
                            userRole: userData.userRole,
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
                            isVerified: true,
                            age: age,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .removeCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Profile updated successfully')),
                            );

                            debugPrint("User UID: ${user.uid}");
                            debugPrint("User Role: ${userData.userRole}");

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Home(
                                    uid: user.uid,
                                    role: userData.userRole.toString()),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          }
                        },
                        age: userData.age ?? 0,
                      )
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

  Future<bool> _showDialog(BuildContext context, String title, String content,
      List<Widget> actions) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: Text(
            content,
            style: TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.normal,
                color: AppColors.black),
          ),
          actions: actions,
        );
      },
    );
  }

  Future<bool> _showNewUserAlert(BuildContext context) async {
    return await _showDialog(
      context,
      'Profile Setup Required',
      'Please fill out the form to complete your profile.',
      [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
  }

  Future<bool> _showAlertDialog(BuildContext context) async {
    return await _showDialog(
      context,
      'Profile Incomplete',
      'Please fill out the entire form before proceeding.',
      [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
  }

  Widget? _buildFutureState(AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (snapshot.hasError) {
      return Scaffold(
        body: Center(child: Text("Error: ${snapshot.error}")),
      );
    } else if (!snapshot.hasData || snapshot.data == null) {
      return const Scaffold(
        body: Center(child: Text("No user data found.")),
      );
    }
    return null;
  }
}
