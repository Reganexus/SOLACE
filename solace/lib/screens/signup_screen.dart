import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart'; // Adjust the path according to your structure

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _agreeToTerms = false;

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
                'Hello!',
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
              const SizedBox(height: 10),
          
              // Checkbox for Terms and Conditions
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (bool? value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.neon,  
                      checkColor: Colors.white,
                      side: const BorderSide(
                        color: AppColors.neon,
                        width: 2,
                      ),
                    ),
                    const Text('I agree to '),
                    GestureDetector(
                      onTap: () {
                        // Show modal when clicked
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Terms and Conditions'),
                              content: const Text(
                                  'Here you can add your terms and conditions.'),
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
                      },
                      child: const Text(
                        'terms and conditions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          color: AppColors.black,  // Set color as needed
                        ),
                      ),
                    ),
                  ],
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
          
              // Sign up with Google Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // Action for signing up with Google
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
                        'Sign up with Google',
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
