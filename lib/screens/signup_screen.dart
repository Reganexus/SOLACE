import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart'; // Ensure this path is correct
import 'package:solace/screens/user/user_main.dart'; // Import UserMainScreen
import 'package:solace/screens/login_screen.dart';
import 'package:solace/services/auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {

  final AuthService _auth = AuthService();

  bool _agreeToTerms = false;
  bool _isPasswordVisible = false; // Variable to toggle password visibility

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Controllers for email and password fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _emailFocusNode.addListener(() {
      setState(() {});
    });

    _passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose(); // Dispose email controller
    _passwordController.dispose(); // Dispose password controller
    super.dispose();
  }

  // Function to handle sign up with validation
  void _signup() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showSignUpErrorDialog('Email field cannot be empty.');
    } else if (password.length < 6) {
      _showSignUpErrorDialog('Password should be at least 6 characters long.');
    } else if (!_agreeToTerms) {
      _showSignUpErrorDialog('Please agree to the terms and conditions.');
    } else {
      // Try signing up with Firebase
      try {
        // Firebase will throw an error if the email is invalid or the password is too short
        dynamic result = await _auth.signUpWithEmailAndPassword(email, password);
        if (result != null) {
          // On successful sign up, navigate to UserMainScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserMainScreen()),
          );
        } else {
          // either not valid email format or account already
          _showSignUpErrorDialog('Sign up failed. Please try again.');
        }
      } catch (e) {
        _showSignUpErrorDialog('Error: ${e.toString()}');
      }
    }
  }

  // Function to show error dialogs
  void _showSignUpErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Up Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: SizedBox(
          height: deviceHeight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'lib/assets/images/auth/sign_up.png',
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

                  // Email Input Field
                  TextFormField(
                    controller: _emailController, // Add controller here
                    focusNode: _emailFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: AppColors.gray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.neon,
                          width: 2,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: _emailFocusNode.hasFocus
                            ? AppColors.neon
                            : AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Password Input Field with Eye Icon
                  TextFormField(
                    controller: _passwordController, // Add controller here
                    focusNode: _passwordFocusNode,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: AppColors.gray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.neon,
                          width: 2,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: _passwordFocusNode.hasFocus
                            ? AppColors.neon
                            : AppColors.black,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: _passwordFocusNode.hasFocus
                              ? AppColors.neon
                              : AppColors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Checkbox for Terms and Conditions
                  Row(
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
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sign Up Button
                  TextButton(
                    onPressed: _signup, // Update to call _signup function
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 10),
                      backgroundColor: AppColors.neon, // Set background color
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.white, // Set button text color
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

                  // Sign up with Google Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        // Action for signing up with Google
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
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
                            'lib/assets/images/auth/google.png',
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
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to Login view
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const LoginScreen()), // Replace with your login widget
                        );
                      },
                      child: const Text(
                        'I already have an account',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.normal,
                          fontSize: 12.0,
                          color: AppColors.black,
                          decoration: TextDecoration.underline,
                        ),
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
