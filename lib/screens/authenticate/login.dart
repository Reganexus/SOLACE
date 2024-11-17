// ignore_for_file: use_build_context_synchronously

import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/forgot.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/shared/globals.dart';
import 'package:solace/shared/widgets/user_editprofile.dart';
import 'package:solace/themes/colors.dart';

class LogIn extends StatefulWidget {
  final VoidCallback toggleView; // Updated to VoidCallback

  const LogIn({super.key, required this.toggleView}); // Pass key to super

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  MyUser? currentUser;

  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String error = '';
  bool _isLoading = false; // Loading state

  bool _isPasswordVisible = false;
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (autoLoginenabled) {
      _autoLogin();
    }

    // Listener for email focus
    _emailFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Listener for password focus
    _passwordFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Dispose of focus nodes
    _emailFocusNode.removeListener(() {});
    _passwordFocusNode.removeListener(() {});
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUpWithGoogle() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      MyUser? user = await _auth.signInWithGoogle();
      if (user != null) {
        // Check if the user is new
        if (user.newUser) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
          );
        } else {
          // If the user has already completed their profile
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
        }
      } else {
        _showError("Google sign-up failed. Please try again.", "");
      }
    } catch (e) {
      _showError(
          "An error occurred during Google sign-up. Please try again later.",
          "");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message, String criteria) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                // Container for the error messages
                Container(
                  padding:
                      const EdgeInsets.all(16), // Padding inside the container
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFFFF3F2), // Background color for errors
                    border: Border.all(
                      color: const Color(0xFFFEC5D0), // Border color for errors
                      width: 2, // Border width
                    ),
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error Title
                      const Text(
                        'Error/s Occurred!',
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF690D02), // Text color for title
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Error Messages
                      Text(
                        message
                            .split('\n')
                            .where((error) =>
                                error.isNotEmpty) // Filter out empty messages
                            .map((error) => "• $error")
                            .join('\n'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(
                              0xFF690D02), // Text color for error messages
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Only show the Password Criteria Container if criteria is not empty
                if (criteria.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(
                        16), // Padding inside the container
                    decoration: BoxDecoration(
                      color: const Color(
                          0xFFE8F5E9), // Complementary background color for password criteria
                      border: Border.all(
                        color: const Color(
                            0xFFC8E6C9), // Complementary border color for password criteria
                        width: 2, // Border width
                      ),
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Password Criteria Title
                        const Text(
                          'Password Criteria',
                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Password Criteria List
                        Text(
                          criteria
                              .split('\n')
                              .where((criterion) => criterion
                                  .isNotEmpty) // Filter out empty criteria
                              .map((criterion) => "• $criterion")
                              .join('\n'),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                backgroundColor: AppColors.neon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _autoLogin() async {
    String testEmail = 'john@gmail.com';
    String testPassword = 'test123';

    dynamic result =
        await _auth.logInWithEmailAndPassword(testEmail, testPassword);
    if (result == null && mounted) {
      setState(() => error = 'Auto login failed');
    }
  }

  TextStyle get focusedLabelStyle => const TextStyle(
        color: AppColors.neon,
        fontSize: 16,
      );

  InputDecoration _inputDecoration(String label, FocusNode focusNode) {
    return InputDecoration(
      labelText: label,
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
        color: focusNode.hasFocus ? AppColors.neon : AppColors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss the keyboard
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight,
            ),
            child: Center(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      'lib/assets/images/auth/solace.png',
                      width: 100,
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
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      decoration: _inputDecoration('Email', _emailFocusNode),
                      onChanged: (val) => setState(() => _email = val),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: !_isPasswordVisible,
                      decoration:
                          _inputDecoration('Password', _passwordFocusNode)
                              .copyWith(
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
                            if (mounted) {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            }
                          },
                        ),
                      ),
                      onChanged: (val) => setState(() => _password = val),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      constraints: BoxConstraints(minHeight: 50),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Forgot()),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isLoading // Check if loading
                            ? null // Disable the button while loading
                            : () async {
                                String errorMessage = '';

                                // Validate Email
                                if (_emailController.text.isEmpty) {
                                  errorMessage += "Enter an email.\n";
                                } else if (!RegExp(
                                        r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                                    .hasMatch(_emailController.text)) {
                                  errorMessage +=
                                      "Enter a valid email address.\n";
                                }

                                // Validate Password
                                if (_passwordController.text.isEmpty) {
                                  errorMessage += "Enter a password.\n";
                                } else if (_passwordController.text.length <
                                    6) {
                                  errorMessage +=
                                      "Password must be at least 6 characters long.\n";
                                } else if (_passwordController.text.length >
                                    4096) {
                                  errorMessage +=
                                      "Password must be no more than 4096 characters long.\n";
                                } else if (!RegExp(r'(?=.*[a-z])')
                                    .hasMatch(_passwordController.text)) {
                                  errorMessage +=
                                      "Password must include at least one lowercase letter.\n";
                                } else if (!RegExp(r'(?=.*[A-Z])')
                                    .hasMatch(_passwordController.text)) {
                                  errorMessage +=
                                      "Password must include at least one uppercase letter.\n";
                                } else if (!RegExp(r'(?=.*\d)')
                                    .hasMatch(_passwordController.text)) {
                                  errorMessage +=
                                      "Password must include at least one number.\n";
                                } else if (!RegExp(r'(?=.*[!@#\$%\^&\*_])')
                                    .hasMatch(_passwordController.text)) {
                                  errorMessage +=
                                      "Password must include at least one special character.\n";
                                }

                                // Show errors if there are any
                                if (errorMessage.isNotEmpty) {
                                  // Call _showError with both error messages and criteria
                                  _showError(errorMessage, "");
                                  return; // Exit early if there are validation errors
                                }

                                if (_formKey.currentState!.validate()) {
                                  if (mounted) {
                                    setState(() {
                                      _isLoading =
                                          true; // Set loading state to true
                                    });
                                  }
                                  dynamic result =
                                      await _auth.logInWithEmailAndPassword(
                                          _email, _password);
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false; // Reset loading state
                                      if (result == null) {
                                        error =
                                            'Could not log in with those credentials';
                                      } else {
                                        error = ''; // Clear error on success
                                      }
                                    });
                                  }
                                }
                              },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          backgroundColor: AppColors.neon,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child:
                            _isLoading // Show CircularProgressIndicator if loading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white))
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.white,
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: <Widget>[
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("or"),
                        ),
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _handleSignUpWithGoogle,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                              'Sign in with Google',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text(
                          'Don\'t have an account?',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        GestureDetector(
                          onTap: () => widget
                              .toggleView(), // Call toggleView as a function
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.neon,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
