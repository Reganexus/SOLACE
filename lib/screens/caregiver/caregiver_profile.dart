import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/screens/caregiver/caregiver_editprofile.dart'; // Adjust the path as necessary
import 'package:solace/screens/get_started_screen.dart'; // Adjust the path as necessary

class CaregiverProfileScreen extends StatelessWidget {
  const CaregiverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 20.0), // Space after title

            // Placeholder Image
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

            // Caregiver Name
            const Center(
              child: Text(
                'Caregiver',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
            const SizedBox(height: 20), // Spacing before buttons

            // Row of buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProfileButton(
                  context,
                  'Show QR',
                  'lib/assets/images/shared/profile/qr.png',
                  AppColors.neon,
                  () => _showQrModal(context), // Function for showing QR modal
                ),
                _buildProfileButton(
                  context,
                  'Edit Profile',
                  'lib/assets/images/shared/profile/edit.png',
                  AppColors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CaregiverEditProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildProfileButton(
                  context,
                  'Logout',
                  'lib/assets/images/shared/profile/logout.png',
                  AppColors.red,
                  () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GetStarted(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20), // Space after buttons

            // Horizontal line
            const Divider(thickness: 1, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Function to build each profile button
  Widget _buildProfileButton(BuildContext context, String title,
      String iconPath, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 90.0,
        height: 90.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60.0,
              height: 60.0,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(16.0), // Padding inside the container
                child: Image.asset(iconPath),
              ),
            ),
            const SizedBox(height: 5.0), // Spacing between container and text
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12.0,
                fontWeight: FontWeight.normal,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQrModal(BuildContext context) {
    // Show QR modal implementation
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
}
