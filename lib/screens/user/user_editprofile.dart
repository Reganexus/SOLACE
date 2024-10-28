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
      future: DatabaseService(uid: user!.uid).getUserData(),
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
          appBar: AppBar(
            title: const Text('Edit Profile'),
            backgroundColor: AppColors.white,
            scrolledUnderElevation: 0.0,
          ),
          body: UserDataForm(
            isSignUp: false,
            userData: userData,
            onButtonPressed: () {
              // Perform the update and handle navigation in the then callback
              DatabaseService(uid: user.uid).updateUserData(
                firstName: userData!.firstName,
                lastName: userData.lastName,
                middleName: userData.middleName,
                phoneNumber: userData.phoneNumber,
                sex: userData.sex,
                birthMonth: userData.birthMonth,
                birthDay: userData.birthDay,
                birthYear: userData.birthYear,
                address: userData.address, // Include the address
              ).then((_) {
                // Check if the widget is still mounted before navigating
                if (context.mounted) {
                  Navigator.pop(context); // Navigate back after saving
                }
              });
            },
          ),
        );
      },
    );
  }
}
