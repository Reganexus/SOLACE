// ignore_for_file: use_build_context_synchronously, unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/forgot.dart';
import 'package:solace/screens/authenticate/verify.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/services/auth.dart';
import 'package:flutter/material.dart';
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
        // Check if the email exists in any role-based collection
        final List<String> collections = ['nurse', 'admin', 'doctor', 'patient', 'unregistered'];
        DocumentSnapshot? userDoc;
        String? userRole;

        for (final collection in collections) {
          final querySnapshot = await FirebaseFirestore.instance
              .collection(collection)
              .where('email', isEqualTo: myUser.email)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            userDoc = querySnapshot.docs.first;
            userRole =
                collection.substring(0, collection.length - 1); // Remove 's'
            break;
          }
        }

        if (userDoc != null) {
          // Email exists in the database
          final userData = userDoc.data() as Map<String, dynamic>?;

          if (userData != null && userData['isVerified'] == true) {
            // Verified user: Redirect to Home
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Home(uid: myUser.uid, role: userRole!),
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

  void _showError(List<String> errorMessages) {
    // First, check if there are multiple errors or just one
    if (errorMessages.isNotEmpty) {
      // Show error messages in a Snackbar one by one
      for (var error in errorMessages) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error,
              style: const TextStyle(fontSize: 16),
            ),
            duration: const Duration(seconds: 3), // Customize the duration
            backgroundColor: Colors.red, // Background color of the Snackbar
          ),
        );
      }
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
                      'Login',
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
                      validator: _emailValidator,
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
                      validator: _passwordValidator,
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
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  if (mounted) {
                                    setState(() => _isLoading = true);
                                  }

                                  String email = _emailController.text.trim();
                                  String password =
                                      _passwordController.text.trim();

                                  try {
                                    MyUser? result =
                                        await _auth.logInWithEmailAndPassword(
                                            email, password);

                                    if (result != null) {
                                      if (mounted) setState(() => error = '');

                                      String uid = result.uid;
                                      String? role;

                                      for (final collection in [
                                        'caregiver',
                                        'admin',
                                        'doctor', 'patient', 'unregistered'
                                      ]) {
                                        try {
                                          final doc = await FirebaseFirestore
                                              .instance
                                              .collection(collection)
                                              .doc(uid)
                                              .get()
                                              .timeout(
                                                  const Duration(seconds: 10));
                                          if (doc.exists) {
                                            role = collection;
                                            break;
                                          }
                                        } catch (e) {
                                          debugPrint(
                                              "Error fetching document: $e");
                                        }
                                      }

                                      if (role != null) {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                Home(uid: uid, role: role!),
                                          ),
                                        );
                                        return;
                                      } else {
                                        if (mounted) {
                                          setState(() =>
                                              error = 'User role not found.');
                                        }
                                      }
                                    } else {
                                      if (mounted) {
                                        setState(() => error =
                                            'Invalid email or password.');
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() => error =
                                          'Login failed: ${e.toString()}');
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
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
                                ? SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: const CircularProgressIndicator(
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
      ),
    );
  }
}
