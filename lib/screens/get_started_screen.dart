import 'package:flutter/material.dart';
import 'package:solace/screens/login_screen.dart';
import 'package:solace/screens/signup_screen.dart';
import 'package:solace/themes/colors.dart'; // Use your defined color theme here

class GetStarted extends StatelessWidget {
  const GetStarted({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceHeight =
        MediaQuery.of(context).size.height; // Get the device height

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        // Center the whole content
        child: SizedBox(
          height: deviceHeight, // Use device height
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600, // Set the max width to 600 for consistent layout
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 30, vertical: 40), // Adjust padding
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center vertically
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center horizontally
                children: <Widget>[
                  // Logo
                  Image.asset(
                    'lib/assets/images/auth/solace.png', // Ensure this path is correct
                    height: 150,
                  ),

                  const SizedBox(
                      height:
                          40), // Adjust spacing between the logo and the text

                  // App Title
                  const Text(
                    'SOLACE',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black, // Adjust this as needed
                    ),
                  ),

                  const SizedBox(height: 200),

                  // Get Started Button
                  TextButton(
                    onPressed: () {
                      // Navigate to the Signup screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignupScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 80, vertical: 15),
                      backgroundColor: AppColors.neon, // Set background color
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.white, // Set button text color
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Already have an account text
                  GestureDetector(
                    onTap: () {
                      // Navigate to the Login screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'I already have an account',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: AppColors.black, // Adjust this as needed
                        decoration: TextDecoration
                            .underline, // Optional: underline for clickable text
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
