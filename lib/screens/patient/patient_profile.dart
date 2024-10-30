import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/shared/widgets/user_editprofile.dart';
import 'package:solace/models/my_user.dart'; // Ensure you import your UserData model

class PatientProfile extends StatelessWidget {
  const PatientProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);
    print('User Profile: $user'); // Check if userData is null or contains the expected data

    return Scaffold(
      backgroundColor: AppColors.white,
      body: StreamBuilder<UserData>(
        stream: DatabaseService(uid: user?.uid).userData,
        builder: (context, snapshot) {
          print('Profile uid: ${user?.uid}');
          print('Profile snapshot: ${snapshot}');
          if(snapshot.hasData) {
            UserData? userData = snapshot.data;
            return Container(
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
                          image: AssetImage('lib/assets/images/shared/placeholder.png'), // Placeholder image
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10), // Space after image
            
                  // User Name
                  Center(
                    child: Text(
                      '${userData?.firstName ?? ''} ${userData?.middleName ?? ''} ${userData?.lastName ?? ''}', // Concatenate name parts
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Spacing before buttons
            
                  // Centered Row of Buttons
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Image.asset('lib/assets/images/shared/profile/qr.png', height: 30),
                          onPressed: () => _showQrModal(context),
                        ),
                        const SizedBox(width: 5), // Spacing between icons
                        IconButton(
                          icon: Image.asset('lib/assets/images/shared/profile/edit.png', height: 30),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 5), // Spacing between icons
                        IconButton(
                          icon: Image.asset('lib/assets/images/shared/profile/logout.png', height: 30),
                          onPressed: () async {
                            await AuthService().signOut();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20), // Space after buttons
            
                  // Section Header
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
            
                  // Scrollable Profile Info Sections
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileInfoSection(
                            'Name',
                            '${userData?.firstName ?? 'N/A'} ${userData?.middleName ?? ''} ${userData?.lastName ?? 'N/A'}', // Adjust name format
                          ),
                          _buildProfileInfoSection('Email Address', userData?.email ?? 'N/A'), // Updated email
                          _buildProfileInfoSection('Phone Number', userData?.phoneNumber ?? 'N/A'), // Provide default value
                          _buildProfileInfoSection('House Address', userData?.address ?? '123 Sample Street'), // Adjust accordingly
                          _buildProfileInfoSection('Gender', userData?.sex ?? 'N/A'), // Provide default value
                          _buildProfileInfoSection('Birthdate',
                              '${userData?.birthMonth ?? 'N/A'} ${userData?.birthDay ?? 'N/A'}, ${userData?.birthYear ?? 'N/A'}'), // Combine birthdate components
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            print('Snapshot no data');
            return Center(child: Text('Loading...'));
          }
        }
      ),
    );
  }

  // Helper method for each profile info section
  Widget _buildProfileInfoSection(String header, String data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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

// Function to show QR modal
void _showQrModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('QR Code'),
        content: const Text('Here you can display the QR code.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
