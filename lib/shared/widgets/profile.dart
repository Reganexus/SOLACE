// ignore_for_file: avoid_print, unused_import, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/help_page.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/shared/widgets/user_editprofile.dart';
import 'package:solace/shared/widgets/contacts.dart';
import 'package:solace/models/my_user.dart';
import 'package:url_launcher/url_launcher.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: StreamBuilder<UserData?>(
        stream: DatabaseService(uid: user?.uid).userData,
        builder: (context, snapshot) {
          // Check for loading or error states
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Fallback user data in case of null snapshot data
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
                birthday: null,
                userRole: UserRole.patient, // Default to 'patient' if no role found
                isVerified: false,
                newUser: true,
                dateCreated: DateTime.now(),
                profileImageUrl: '',
                status: 'stable', // Default status
              );

          // Redirect to EditProfileScreen if newUser is true
          if (userData.newUser) {
            Future.microtask(() {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            });
            return const SizedBox(); // Return an empty widget while redirecting
          }

          // Main Profile Screen if newUser is false
          return SingleChildScrollView(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  Center(
                    child: CircleAvatar(
                      radius: 75,
                      backgroundImage: NetworkImage(userData.profileImageUrl),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '${userData.firstName} ${userData.middleName} ${userData.lastName}',
                            style: const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 5),
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
                              height: 18,
                              width: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Divider(thickness: 1.0),
                  const SizedBox(height: 10),

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
                      _buildProfileInfoSection(
                          'Phone Number', userData.phoneNumber),
                      _buildProfileInfoSection(
                          'House Address', userData.address),
                      _buildProfileInfoSection('Gender', userData.gender),
                      _buildProfileInfoSection(
                          'Birthdate',
                          userData.birthday != null
                              ? '${userData.birthday!.month}/${userData.birthday!.day}/${userData.birthday!.year}'
                              : ''),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Divider(thickness: 1.0),
                  const SizedBox(height: 10),

                  const Text(
                    'Contacts',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Contacts(
                            currentUserId: userData.uid,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "View Contacts",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                        fontSize: 16.0,
                        color: AppColors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Divider(thickness: 1.0),
                  const SizedBox(height: 10),

                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HelpPage()),
                      );
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

