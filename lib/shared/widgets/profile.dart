// ignore_for_file: avoid_print, unused_import, use_build_context_synchronously, library_private_types_in_public_api
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/help_page.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/shared/accountflow/user_editprofile.dart';
import 'package:solace/shared/widgets/contacts.dart';
import 'package:solace/models/my_user.dart';
import 'package:url_launcher/url_launcher.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  File? _profileImage;
  late Future<UserData?> _userDataFuture;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<MyUser?>(context, listen: false);
    _userDataFuture = (user != null
        ? DatabaseService(uid: user.uid).userData?.first // Use null-aware operator
        : Future.value(null))!; // Return a null Future if no user is available
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: FutureBuilder<UserData?>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("Future error: \${snapshot.error}");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Something went wrong. Please try again.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      final user = Provider.of<MyUser?>(context, listen: false);
                      _userDataFuture = (user != null
                          ? DatabaseService(uid: user.uid).userData?.first
                          : Future.value(null))!;
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          UserData userData = snapshot.data ??
              UserData(
                uid: '',
                firstName: 'N/A',
                middleName: 'N/A',
                lastName: 'N/A',
                email: 'N/A',
                phoneNumber: 'N/A',
                address: 'N/A',
                gender: 'N/A',
                birthday: null,
                userRole: UserRole.caregiver,
                isVerified: false,
                newUser: false,
                dateCreated: DateTime.now(),
                profileImageUrl: '',
                status: 'N/A',
                religion: 'N/A',
              );

          if (userData.newUser) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
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
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (userData.profileImageUrl.isNotEmpty
                              ? NetworkImage(userData.profileImageUrl)
                                  as ImageProvider
                              : const AssetImage(
                                  'lib/assets/images/shared/placeholder.png')),
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
                            : '',
                      ),
                    ],
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
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text(
                            'Log Out',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter'),
                          ),
                          backgroundColor: AppColors.white,
                          contentPadding: const EdgeInsets.all(20),
                          content: const Text(
                            'Are you sure you want to log out?',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Inter'),
                          ),
                          actions: [
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.neon,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.neon,
                                  foregroundColor: AppColors.white,
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.red,
                                  foregroundColor: AppColors.white,
                                ),
                                child: const Text('Log Out'),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout ?? false) {
                        await AuthService().signOut();
                        // Navigate back to the Authenticate screen
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Authenticate()),
                            (route) => false, // Remove all previous routes
                          );
                        }
                      }
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
