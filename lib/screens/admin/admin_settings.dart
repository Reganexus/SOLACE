// ignore_for_file: avoid_print, unused_element, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/screens/admin/export_data.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/help_page.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/shared/widgets/user_editprofile.dart';
import 'package:solace/models/my_user.dart';

class AdminSettings extends StatelessWidget {
  const AdminSettings({super.key});

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
                userRole:
                    UserRole.patient, // Default to 'patient' if no role found
                isVerified: false,
                newUser: true,
                dateCreated:
                    DateTime.now(), // Providing default dateCreated value
                profileImageUrl:
                    '', // Default profile image URL (empty string or placeholder)
                status: 'stable'
              );

          return SingleChildScrollView(
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
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(50)),
                        image: DecorationImage(
                          image: userData.profileImageUrl.isNotEmpty
                              ? NetworkImage(userData
                                  .profileImageUrl) // Use the image from the URL if available
                              : AssetImage(
                                      'lib/assets/images/shared/placeholder.png')
                                  as ImageProvider, // Placeholder image if not
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          // Use Flexible to avoid overflow
                          child: Text(
                            '${userData.firstName} ${userData.middleName} ${userData.lastName}',
                            style: const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                              color: Colors.black,
                            ),
                            overflow:
                                TextOverflow.ellipsis, // Handle text overflow
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
                        'Export Data',
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
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExportDataScreen(
                                filterValue: 'patient',
                                title: 'Export Patient Data',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Export Patient Data",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                            fontSize: 16.0,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Export Caregiver Data
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExportDataScreen(
                                filterValue: 'caregiver',
                                title: 'Export Caregiver Data',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Export Caregiver Data",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                            fontSize: 16.0,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Export Doctor Data
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExportDataScreen(
                                filterValue: 'doctor',
                                title: 'Export Doctor Data',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Export Doctor Data",
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExportDataScreen(
                                filterValue: 'good',
                                title: 'Export No Risk Patients Data',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Export No Risk Patients",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                            fontSize: 16.0,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Export Low Risk Patients
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExportDataScreen(
                                filterValue: 'low',
                                title: 'Export Low Risk Patients Data',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Export Low Risk Patients",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                            fontSize: 16.0,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Export High Risk Patients
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExportDataScreen(
                                filterValue: 'high',
                                title: 'Export High Risk Patients Data',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Export High Risk Patients",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                            fontSize: 16.0,
                            color: AppColors.black,
                          ),
                        ),
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
                        MaterialPageRoute(builder: (context) => const HelpPage()),
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

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
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
