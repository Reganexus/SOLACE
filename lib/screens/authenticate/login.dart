// ignore_for_file: use_build_context_synchronously, unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/forgot.dart';
import 'package:solace/screens/authenticate/verify.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/services/database.dart';
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
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    } else if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
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

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        MyUser? result = await _auth.logInWithEmailAndPassword(email, password);
        if (result != null) {
          await _processLogin(result);
        } else {
          _showError(['Invalid email or password.']);
        }
      } catch (e) {
        String errorMessage;
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              errorMessage = 'No user found for that email.';
              break;
            case 'wrong-password':
              errorMessage = 'Wrong password provided.';
              break;
            case 'invalid-email':
              errorMessage = 'The email address is invalid.';
              break;
            default:
              errorMessage = 'An error occurred. Please try again.';
          }
        } else {
          errorMessage = 'Login failed: $e';
        }
        _showError([errorMessage]);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processLogin(MyUser result) async {
    final uid = result.uid;
    final db = DatabaseService(uid: uid);
    final role = await db.getTargetUserRole(uid);

    if (role != null) {
      final docExists = await _checkDocumentExists(role, uid);
      if (docExists) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => Home(uid: uid, role: role)),
        );
      } else {
        setState(() => error = 'User document not found.');
      }
    } else {
      setState(() => error = 'User role not found.');
    }
  }

  Future<bool> _checkDocumentExists(String role, String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(role)
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      return doc.exists;
    } catch (e) {
      debugPrint('Error fetching document: $e');
      return false;
    }
  }

  void _showError(List<String> errorMessages) {
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

  void togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
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

  Widget _buildLoginHeader() {
    return Column(
      children: [
        Image.asset(
          'lib/assets/images/auth/solace.png',
          width: 100,
        ),
        const SizedBox(height: 40),
        const Text(
          'Login',
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

  Widget buildTextFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    bool obscureText = false,
    Widget? suffixIcon,
    required String? Function(String?) validator,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
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
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss the keyboard
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight, // Full screen height
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _buildLoginHeader(), // Header widget
                          buildTextFormField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            labelText: 'Email',
                            validator: _emailValidator,
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
                              onPressed: togglePasswordVisibility,
                            ),
                            validator: _passwordValidator,
                            onChanged: (val) => setState(() => _password = val),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 40,
                            child: Center(
                              // Center the text
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Forgot(),
                                    ),
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
                              onPressed: _isLoading ? null : _handleLogin,
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
                                'Don\'t have an account?',
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
                                  'Sign Up',
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
              ),
            );
          },
        ),
      ),
    );
  }
}
