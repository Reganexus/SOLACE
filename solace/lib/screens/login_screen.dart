import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart'; // Adjust the path according to your structure

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),  // Adjust padding for the sides
          height: MediaQuery.of(context).size.height,  // Full height of the screen
          width: double.infinity,  // Full width of the screen
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,  // Center vertically
            crossAxisAlignment: CrossAxisAlignment.center,  // Center horizontally
            mainAxisSize: MainAxisSize.min,  // Shrink column size to fit children
            children: <Widget>[
              Image.asset(
                'lib/assets/images/auth/sign_up.png',  // Ensure this path is correct
                width: double.infinity,
              ),
              const SizedBox(height: 40),
          
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 40),
          
              // Email Input Field with border radius and background color
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,  // Enable background color
                  fillColor: AppColors.gray,  // Set background color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),  // Set border radius
                    borderSide: BorderSide.none,  // No border since we use background
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Password Input Field with border radius and background color
              TextField(
                obscureText: true, // Hides the text input for password
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,  // Enable background color
                  fillColor: AppColors.gray,  // Set background color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),  // Set border radius
                    borderSide: BorderSide.none,  // No border since we use background
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Forgot Password Text
              GestureDetector(
                onTap: () {
                  // Action for forgot password
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    color: AppColors.black,  // Set color as needed
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Divider with 'or'
              const Row(
                children: <Widget>[
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Colors.grey,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("or"),
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
          
              // Sign in with Google Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // Action for signing in with Google
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'lib/assets/images/auth/google.png',  // Ensure this path is correct
                        height: 24,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
