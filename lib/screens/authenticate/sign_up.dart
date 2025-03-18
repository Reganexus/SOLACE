// ignore_for_file: use_build_context_synchronously, unused_import, unnecessary_null_comparison

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/verify.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/accountflow/rolechooser.dart';
import 'package:solace/themes/colors.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart'; // For Toast if needed

class SignUp extends StatefulWidget {
  final Function toggleView;
  const SignUp({super.key, required this.toggleView});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  MyUser? currentUser;

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

  final passwordCriteria = "Be at least 6 characters long.\n"
      "Include at least one lowercase letter.\n"
      "Include at least one uppercase letter.\n"
      "Include at least one number.\n"
      "Include at least one special character.\n";

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

  Future<Map<String, dynamic>> loadJson() async {
    final String response =
        await rootBundle.loadString('lib/assets/terms_and_conditions.json');
    debugPrint("Terms and Conditions: $response");
    return json.decode(response);
  }

  void _showTermsDialog(Map<String, dynamic> termsData) {
    final terms = termsData['terms'];
    final sections = terms['sections'] as Map<String, dynamic>;

    // Start building the dialog content
    List<Widget> contentWidgets = [
      if (terms['welcomeMessage'] != null)
        Text(
          terms['welcomeMessage'],
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.black,
            fontFamily: 'Inter',
          ),
        ),
      const SizedBox(height: 16), // Add spacing after the welcome message
    ];

    // Add sections dynamically
    sections.forEach((key, section) {
      final sectionMap = section as Map<String, dynamic>;
      contentWidgets.add(
        Text(
          sectionMap['numberHeader'] ?? '',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.black,
          ),
        ),
      );
      contentWidgets.add(
        Text(
          sectionMap['content'] ?? '',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: AppColors.black,
          ),
        ),
      );
      contentWidgets
          .add(const SizedBox(height: 16)); // Spacing between sections
    });

    // Show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            terms['title'] ?? 'Terms and Conditions',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...contentWidgets,
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity, // Full-width button
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        backgroundColor: AppColors.neon,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showError(List<String> errorMessages) {
    debugPrint(
        "Displaying error dialog with messages: ${errorMessages.join(', ')}");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text(
            'Error',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Prevent unnecessary space
            crossAxisAlignment:
                CrossAxisAlignment.start, // Aligns children to the left
            children: [
              Text(
                errorMessages.join('\n'), // Join messages with a newline
                textAlign: TextAlign.left, // Left-align the text
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, // Full-width button
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    backgroundColor: AppColors.neon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> validateInput(String email, String password) {
    List<String> errors = [];

    // Email Validation
    if (email.isEmpty) {
      errors.add("Enter an email.");
    } else if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(email)) {
      errors.add("Enter a valid email address.");
    }

    // Password Validation
    if (password.isEmpty) {
      errors.add("Enter a password.");
    } else if (password.length < 6) {
      errors.add("Password must be at least 6 characters long.");
    } else if (!RegExp(r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%\^&\*_])')
        .hasMatch(password)) {
      errors.add(
          "Password must include uppercase, lowercase, number, and special character.");
    }

    return errors;
  }

  Future<void> _handleSignUp() async {
    debugPrint("Starting sign-up process...");

    // Validate input fields
    List<String> errorMessages = validateInput(_email, _password);
    if (errorMessages.isNotEmpty) {
      debugPrint("Validation errors: $errorMessages");
      _showError(errorMessages);
      return;
    }

    if (_formKey.currentState!.validate() && _agreeToTerms) {
      debugPrint("Input validated, and terms accepted.");

      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      try {
        debugPrint("Attempting to sign up user with email: $_email");
        bool success =
            await _auth.signUpWithEmailAndPassword(_email, _password);

        if (success) {
          debugPrint("Sign-up successful for email: $_email");
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Verify()),
            );
          }
        } else {
          debugPrint("Sign-up failed for email: $_email");
          if (mounted) {
            _showError([
              "The email is already in use or there was an issue. Please log in or try again."
            ]);
          }
        }
      } catch (e) {
        debugPrint("Unexpected error: ${e.toString()}");
        if (mounted) {
          _showError([
            "An unexpected error occurred. Please check your connection and try again."
          ]);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      debugPrint("Terms not accepted or form validation failed.");
      if (!_agreeToTerms) {
        _showError(["You must agree to the terms and conditions."]);
      }
    }
  }

  Future<void> _handleSignUpWithGoogle() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Sign in with Google
      MyUser? myUser = await _auth.signInWithGoogle();

      if (mounted && myUser != null) {
        DatabaseService db = DatabaseService(uid: myUser.uid);

        // Get the user role directly using DatabaseService
        String? userRole = await db.getTargetUserRole(myUser.uid);

        if (userRole != null) {
          // Fetch the user document from the corresponding collection
          final userDoc = await FirebaseFirestore.instance
              .collection(userRole)
              .doc(myUser.uid)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();

            if (userData != null && userData['isVerified'] == true) {
              // Verified user: Redirect to Home
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Home(uid: myUser.uid, role: userRole),
                ),
              );
            } else {
              // Not verified: Redirect to Verify
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Verify()),
              );
            }
          } else {
            _showError(["Email not associated with a verified account."]);
          }
        } else {
          _showError(["User role not found. Please contact support."]);
        }
      }
    } catch (e) {
      if (e.toString().contains("google_sign_in_aborted")) {
        return; // User cancelled sign-in, no action needed
      }

      if (mounted) {
        _showError(
          ["An error occurred during Google sign-in. Please try again later."],
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSignUpHeader() {
    return Column(
      children: [
        Image.asset(
          'lib/assets/images/auth/solace.png',
          width: 100,
        ),
        const SizedBox(height: 40),
        const Text(
          'Sign Up',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
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

  Widget buildTextFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required String? Function(String?) validator,
    required ValueChanged<String> onChanged,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text, // Default to text input
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType, // Add the keyboardType property here
      decoration: _inputDecoration(labelText, focusNode).copyWith(
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss the keyboard
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _buildSignUpHeader(),
                        buildTextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          labelText: 'Email',
                          validator: (val) =>
                              val!.isEmpty ? 'Enter a valid email' : null,
                          onChanged: (val) => setState(() => _email = val),
                        ),
                        const SizedBox(height: 20),
                        buildTextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          labelText: 'Password',
                          obscureText: !_isPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppColors.darkgray,
                            ),
                            onPressed: () => setState(() =>
                                _isPasswordVisible = !_isPasswordVisible),
                          ),
                          validator: (val) => val!.length < 6
                              ? 'Password must be at least 6 characters long.'
                              : null,
                          onChanged: (val) => setState(() => _password = val),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 40,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _agreeToTerms,
                                  onChanged: (val) =>
                                      setState(() => _agreeToTerms = val!),
                                ),
                                const Text(
                                  'I agree to the ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    // Load the terms and conditions JSON
                                    final terms = await loadJson();
                                    debugPrint("terms: $terms");
                                    _showTermsDialog(terms);
                                  },
                                  child: const Text(
                                    'terms and conditions',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.neon,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.bold,
                                    ),
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
                            onPressed: _isLoading ? null : _handleSignUp,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 15,
                              ),
                              backgroundColor: AppColors.neon,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      color: AppColors.white,
                                      strokeWidth: 4.0,
                                    ),
                                  )
                                : const Text(
                                    'Sign Up',
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
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("or"),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _handleSignUpWithGoogle,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 15,
                              ),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(
                                  color: AppColors.darkgray,
                                ),
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
                              'Already have an account?',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: AppColors.black,
                              ),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () => widget.toggleView(),
                              child: const Text(
                                ' Login',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.neon,
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
