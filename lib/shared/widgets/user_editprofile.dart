// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/user_data_form.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);

    return FutureBuilder<UserData?>(
      future: DatabaseService(uid: user?.uid).getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData) {
          return const Center(child: Text("No user data found"));
        }

        final userData = snapshot.data;

        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            title: const Text('Edit Profile'),
            backgroundColor: AppColors.white,
            scrolledUnderElevation: 0.0,
          ),
          body: SingleChildScrollView(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
              child: Column(
                children: [
                  UserDataForm(
                    isSignUp: false,
                    userData: userData, // No email field needed here
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
                        await DatabaseService(uid: user?.uid).updateUserData(
                          firstName: firstName,
                          lastName: lastName,
                          middleName: middleName,
                          phoneNumber: phoneNumber,
                          gender: gender,
                          birthday: birthday,
                          address: address,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
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
        );
      },
    );
  }
}
