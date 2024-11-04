// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/verify.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/themes/colors.dart';
import 'dart:convert';

import 'package:solace/screens/home/home.dart';

class SignUp extends StatefulWidget {
  final Function toggleView;
  const SignUp({super.key, required this.toggleView});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  bool _agreeToTerms = false;
  String error = '';
  bool _isPasswordVisible = false;
  bool _isLoading = false; // Loading state

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<Map<String, dynamic>> loadJson() async {
    final String response =
        await rootBundle.loadString('lib/assets/terms_and_conditions.json');
    return json.decode(response);
  }

  // Sign-up method in your sign-up screen
  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      try {
        // Check if the email already exists
        bool emailExists = await _auth.emailExists(_email);
        if (emailExists) {
          _showError(
              "An account with this email already exists. Please log in.");
          return;
        }

        // Attempt to sign up
        var result = await _auth.signUpWithEmailAndPassword(_email, _password);
        if (result != null) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Verify()),
            );
          }
        } else {
          _showError("Registration failed. Please try again.");
        }
      } catch (e) {
        _showError("Network error. Please try again later.");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (!_agreeToTerms) {
      _showError("You must agree to the terms and conditions.");
    }
  }

  Future<void> _handleSignUpWithGoogle() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      MyUser? result = await _auth.signInWithGoogle();
      debugPrint("Sign-in with Google result: $result");

      if (result != null) {
        debugPrint("Google sign-in successful for user: ${result.uid}");
        if (result.isVerified) {
          debugPrint("User is verified. Navigating to Home.");

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Home()),
            ).then((_) {
              debugPrint("Navigation to Home completed.");
            });
          }
        } else {
          if (mounted) {
            debugPrint("User is not verified. Showing error message.");
            _showError("Your account is not verified. Please verify your email.");
          }
        }
      } else {
        if (mounted) {
          debugPrint("Google registration failed. Showing error message.");
          _showError("Registration failed. Please try again.");
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint("Error during Google sign-in: $e");
        _showError("Network error. Please try again later.");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
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
                    'Hello!',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (error.isNotEmpty)
                    SizedBox(
                      height: 20,
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    decoration: _inputDecoration('Email', _emailFocusNode),
                    validator: (val) {
                      if (val!.isEmpty) {
                        return "Enter an email";
                      } else if (!RegExp(
                              r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                          .hasMatch(val)) {
                        return "Enter a valid email address";
                      }
                      return null;
                    },
                    onChanged: (val) => setState(() => _email = val),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: !_isPasswordVisible,
                    decoration: _inputDecoration('Password', _passwordFocusNode)
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
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: (val) {
                      if (val!.length < 6) {
                        return "Enter a password 6+ chars long";
                      } else if (!RegExp(
                              r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$')
                          .hasMatch(val)) {
                        return "Password must include at least one letter and one number";
                      }
                      return null;
                    },
                    onChanged: (val) => setState(() => _password = val),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 50, // Set a minimum height
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 1.2, // Decrease size to make it more compact
                            child: Checkbox(
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
                                width:
                                    1.5, // Thinner border for a more compact look
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _agreeToTerms = !_agreeToTerms;
                              });
                            },
                            child: Row(
                              children: [
                                const Text(
                                  'I agree to ',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16.0,
                                    color: AppColors.black,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    // Load the JSON data
                                    Map<String, dynamic> termsData =
                                        await loadJson();

                                    // Start with the welcome message
                                    List<Widget> contentWidgets = [
                                      Text(
                                        termsData['terms']['welcomeMessage'],
                                        style: const TextStyle(
                                            fontSize: 16,
                                            color: AppColors.black),
                                      ),
                                      const SizedBox(
                                          height: 16), // Add some spacing
                                    ];

                                    // Loop through the sections and build the content
                                    termsData['terms']['sections']
                                        .forEach((key, section) {
                                      contentWidgets.add(
                                        Text(
                                          section['numberHeader'],
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.bold,
                                            fontSize:
                                                18, // You can adjust the font size if needed
                                            color: AppColors.black,
                                          ),
                                        ),
                                      );
                                      contentWidgets.add(
                                        Text(
                                          section['content'],
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 16,
                                            color: AppColors.black,
                                          ),
                                        ),
                                      );
                                      contentWidgets.add(const SizedBox(
                                          height:
                                              16)); // Add spacing between sections
                                    });

                                    // Show the dialog with the loaded content
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          backgroundColor: Colors
                                              .white, // Change to your desired color
                                          title: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Terms and Conditions',
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontFamily: 'Outfit',
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: Container(
                                            constraints: BoxConstraints(
                                                maxHeight:
                                                    400), // Set max height
                                            child: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: contentWidgets,
                                              ),
                                            ),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 15,
                                                        vertical: 5),
                                                backgroundColor: AppColors.neon,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  side: const BorderSide(
                                                      color: AppColors.neon),
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
                                  },
                                  child: const Text(
                                    'terms and conditions',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      color: AppColors.black,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : _handleSignUp, // Disable button if loading
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        backgroundColor: AppColors.neon,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.white) // Loading indicator
                          : const Text(
                              'Sign up',
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
                  GestureDetector(
                    onTap: () =>
                        widget.toggleView(), // Call toggleView as a function
                    child: const Text(
                      'Don\'t have an account? Register',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.black,
                        decoration: TextDecoration.underline,
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
