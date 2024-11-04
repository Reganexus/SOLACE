// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/shared/widgets/user_editprofile.dart';
import 'package:solace/models/my_user.dart';

class CaregiverProfile extends StatelessWidget {
  const CaregiverProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);
    print('User Profile: $user'); // Check if userData is null or contains the expected data

    return Scaffold(
      backgroundColor: AppColors.white,
      body: StreamBuilder<UserData?>(
        stream: DatabaseService(uid: user?.uid).userData,
        builder: (context, snapshot) {
          print('Profile uid: ${user?.uid}');
          print('Profile snapshot: $snapshot');

          // Provide default values if no data is found
          UserData userData = snapshot.data ??
              UserData(
                uid: user?.uid ?? '',
                firstName: 'Set First Name',
                middleName: 'Set Middle Name',
                lastName: 'Set Last Name',
                email: '',
                phoneNumber: 'Set Phone Number',
                address: 'Set Address',
                gender: 'Set Gender',
                birthday: null, // Set to null initially
                userRole: UserRole.caregiver, // Use the UserRole enum
                isVerified: false,
              );

          return SingleChildScrollView(
            // Wrap the entire view in a SingleChildScrollView
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        image: DecorationImage(
                          image: AssetImage(
                              'lib/assets/images/shared/placeholder.png'), // Placeholder image
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10), // Space after image

                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        '${userData.firstName} ${userData.middleName} ${userData.lastName}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis, // Add this to handle overflow
                        maxLines: 1, // Limit to one line
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: IntrinsicWidth(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          backgroundColor: AppColors.neon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.neon),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Image.asset(
                              'lib/assets/images/shared/profile/edit-white.png',
                              height: 18, // Adjust the height as needed
                              width: 18, // Adjust the width as needed
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Divider
                  const SizedBox(height: 10),
                  const Divider(thickness: 1.0),
                  const SizedBox(height: 10),

                  // Personal Information
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileInfoSection('Email Address', userData.email),
                      _buildProfileInfoSection('Phone Number', userData.phoneNumber),
                      _buildProfileInfoSection('House Address', userData.address),
                      _buildProfileInfoSection('Gender', userData.gender),
                      _buildProfileInfoSection('Birthdate',
                          userData.birthday != null ?
                          '${userData.birthday!.day}/${userData.birthday!.month}/${userData.birthday!.year}' : 'N/A'),
                    ],
                  ),

                  // Divider
                  const SizedBox(height: 10),
                  const Divider(thickness: 1.0),
                  const SizedBox(height: 10),

                  // Account
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      await AuthService().signOut();
                    },
                    child: const Text(
                      "Help",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                        fontSize: 16.0,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      await AuthService().signOut();
                    },
                    child: const Text(
                      "Log Out",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                        fontSize: 16.0,
                        color: AppColors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method for each profile info section
  Widget _buildProfileInfoSection(String header, String data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Colors.grey,
            ),
          ),
          Text(
            data,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.normal,
              fontFamily: 'Inter',
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
