// ignore_for_file: use_build_context_synchronously, unused_field

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/forgot.dart';
import 'package:solace/screens/authenticate/verify.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/error_handler.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/inputdecoration.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:solace/services/log_service.dart';

class LogIn extends StatefulWidget {
  final VoidCallback toggleView; // Updated to VoidCallback

  const LogIn({super.key, required this.toggleView}); // Pass key to super

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  MyUser? currentUser;
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  final logService = LogService();
  late final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoginButtonEnabled = true;
  bool _isGoogleSignInButtonEnabled = true;

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
    _addFocusListener(_emailFocusNode);
    _addFocusListener(_passwordFocusNode);
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _addFocusListener(FocusNode focusNode) {
    focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void handleFirebaseAuthError(FirebaseAuthException e) {
    final errorMessages = {
      'user-not-found': 'No user found for that email.',
      'wrong-password': 'Wrong password provided.',
      'invalid-email': 'The email address is invalid.',
    };

    String errorMessage =
        errorMessages[e.code] ?? e.message ?? 'An unexpected error occurred.';
    _showError([errorMessage]);
  }

  void _showError(List<String> errorMessages) {
    if (errorMessages.isEmpty || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ErrorDialog(title: 'Error', messages: errorMessages),
    );
  }

  void togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _handleSignUpWithGoogle() async {
    if (!_isGoogleSignInButtonEnabled) return;

    if (mounted) {
      setState(() => _isGoogleSignInButtonEnabled = false);
    }

    try {
      await _runWithLoadingState(() async {
        MyUser? myUser = await _auth.signInWithGoogle();

        if (myUser != null) {
          String? userRole = await _db.fetchAndCacheUserRole(myUser.uid);

          if (userRole != null) {
            await _navigateBasedOnVerification(myUser.uid, userRole);
          } else {
            _showError(["User role not found. Please contact support."]);
          }
        }
      });
    } catch (e) {
      if (e is FirebaseAuthException) {
        handleFirebaseAuthError(e);
      } else if (e is TimeoutException) {
        _showError(["The request timed out. Please try again later."]);
      } else if (e.toString().contains("google_sign_in_aborted")) {
        // Silently handle user cancellation
      } else {
        _showError([
          "An error occurred during Google sign-in. Please try again later.",
        ]);
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleSignInButtonEnabled = true);
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_isLoginButtonEnabled) return;

    if (mounted) {
      setState(() => _isLoginButtonEnabled = false);
    }

    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        setState(() => _isLoginButtonEnabled = true);
      }
      return;
    }

    try {
      await _runWithLoadingState(_performLogin);
    } catch (e) {
      _handleLoginError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoginButtonEnabled = true);
      }
    }
  }

  Future<void> _performLogin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError(['Email cannot be empty.']);
      return;
    }
    final password = _passwordController.text.trim();
    final allowed = await isLoginAllowed(email);
    
    if (!allowed) {
      final docRef = FirebaseFirestore.instance.collection('login_attempts').doc(email);
      final snapshot = await docRef.get();
      String lockedDurationMessage = '';

      if (snapshot.exists) {
        final data = snapshot.data()!;
        final lockedUntil = (data['lockedUntil'] as Timestamp?)?.toDate();

        if (lockedUntil != null) {
          final remainingDuration = lockedUntil.difference(DateTime.now());
          if (remainingDuration.isNegative) {
            lockedDurationMessage = 'You can try logging in now.';
          } else {
            final minutes = remainingDuration.inMinutes;
            final seconds = remainingDuration.inSeconds % 60;
            lockedDurationMessage =
                'Too many failed login attempts. Please try again after ${minutes}m ${seconds}s.';
          }
        }
      }

      _showError([lockedDurationMessage]);
      return;
    }

    MyUser? result = await _auth
        .logInWithEmailAndPassword(email, password)
        .timeout(
          const Duration(seconds: 10),
          onTimeout:
              () => throw TimeoutException('The login request timed out.'),
        );

    if (result != null) {
      await resetLoginAttempts(email);
      await _processLogin(result);
    } else {
      await recordLoginAttempt(email);
      _showError(['Invalid email or password.']);
    }
  }

  void _handleLoginError(Object e) async {
    String attemptedEmail = _emailController.text.trim();

    if (e is FirebaseAuthException) {
      await logService.addLog(
        userId: 'unauthenticated',
        action: 'Failed login: ${e.code}',
        relatedUsers: attemptedEmail,
      );
      handleFirebaseAuthError(e);
    } else if (e is TimeoutException) {
      await logService.addLog(
        userId: 'unauthenticated',
        action: 'Login timeout',
        relatedUsers: attemptedEmail,
      );
      _showError(['Login timed out. Please try again later.']);
    } else {
      await logService.addLog(
        userId: 'unauthenticated',
        action: 'Login error: ${e.toString()}',
        relatedUsers: attemptedEmail,
      );
      _showError(['Login failed: $e']);
    }

    await recordLoginAttempt(attemptedEmail);
  }


  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _navigateBasedOnVerification(String uid, String userRole) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection(userRole)
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (userDoc.exists && userDoc.data()?['isVerified'] == true) {
        showToast('Login successful. Redirecting to home...');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Home(uid: uid, role: userRole),
          ),
        );
      } else {
        showToast('Account not verified. Redirecting to verification page...');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Verify()),
        );
      }
    } catch (e) {
      _showError(["Failed to verify user. Please try again later."]);
    }
  }

  Future<void> _runWithLoadingState(Future<void> Function() task) async {
    setState(() => _isLoading = true);
    try {
      await task();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processLogin(MyUser result) async {
    final uid = result.uid;
    final role = await _db.fetchAndCacheUserRole(uid);

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

  Future<void> recordLoginAttempt(String email) async {
    if(_email.isEmpty) return; // Avoid unnecessary Firestore calls if email is empty
    final docRef = FirebaseFirestore.instance.collection('login_attempts').doc(email);
    final snapshot = await docRef.get();
    int attempts = 1;
    DateTime? lockedUntil;

    if (snapshot.exists) {
      final data = snapshot.data()!;
      attempts = (data['attempts'] ?? 0) + 1;

      if (attempts >= 20) {
        lockedUntil = DateTime.now().add(Duration(minutes: 10));
      } else if (attempts >= 15) {
        lockedUntil = DateTime.now().add(Duration(minutes: 5));
      } else if (attempts >= 10) {
        lockedUntil = DateTime.now().add(Duration(minutes: 1));
      } else if (attempts >= 5) {
        lockedUntil = DateTime.now().add(Duration(seconds: 30));
      }
    }

    await docRef.set({
      'attempts': attempts,
      'lastAttempt': FieldValue.serverTimestamp(),
      'lockedUntil': lockedUntil,
    });
  }

  Future<void> resetLoginAttempts(String email) async {
    await FirebaseFirestore.instance.collection('login_attempts').doc(email).delete();
  }

  Future<bool> isLoginAllowed(String email) async {
    final docRef = FirebaseFirestore.instance.collection('login_attempts').doc(email);
    final snapshot = await docRef.get();
    
    if (snapshot.exists) {
      final data = snapshot.data()!;
      final lockedUntil = (data['lockedUntil'] as Timestamp?)?.toDate();
      if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
        return false; // Locked out
      }
    }
    return true;
  }

  Future<bool> _checkDocumentExists(String role, String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(role)
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));
      return doc.exists;
    } catch (e) {
      debugPrint('Failed to fetch document: $e');
      return false;
    }
  }

  TextStyle get focusedLabelStyle => Textstyle.bodyNeon;

  Widget _buildLoginHeader() {
    return Column(
      children: [
        Image.asset('lib/assets/images/auth/solace.png', width: 100),
        const SizedBox(height: 40),
        Text('Login', style: Textstyle.title),
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
    required Function(String) onChanged,
    Function(String)? onFieldSubmitted, // New parameter
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: !_isLoading,
      decoration: InputDecorationStyles.build(
        labelText,
        focusNode,
      ).copyWith(suffixIcon: suffixIcon),
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  Widget _emailField() => buildTextFormField(
    controller: _emailController,
    focusNode: _emailFocusNode,
    labelText: 'Email',
    onChanged: (val) => setState(() => _email = val),
    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
  );

  Widget _passwordField() => buildTextFormField(
    controller: _passwordController,
    focusNode: _passwordFocusNode,
    labelText: 'Password',
    obscureText: !_isPasswordVisible,
    suffixIcon: IconButton(
      icon: Icon(
        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
        color: AppColors.darkgray,
      ),
      onPressed: togglePasswordVisibility,
    ),
    onChanged: (val) => setState(() => _password = val),
    onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
  );

  Widget _buildForgotPassword() {
    return SizedBox(
      height: 40,
      child: Center(
        child: GestureDetector(
          onTap:
              _isLoading
                  ? null
                  : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const Forgot(), // Navigate to Forgot screen
                      ),
                    );
                  },
          child: Text(
            'Forgot Password?',
            style: Textstyle.body.copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
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
                          _emailField(),
                          const SizedBox(height: 20),
                          _passwordField(),
                          const SizedBox(height: 20),
                          _buildForgotPassword(),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed:
                                  (!_isLoading && _isLoginButtonEnabled)
                                      ? _handleLogin
                                      : null,
                              style: Buttonstyle.neon,
                              child:
                                  _isLoading
                                      ? SizedBox(
                                        width: 26,
                                        height: 26,
                                        child: Loader.loaderWhite,
                                      )
                                      : Text(
                                        'Login',
                                        style: Textstyle.largeButton,
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
                              onPressed:
                                  (!_isLoading && _isGoogleSignInButtonEnabled)
                                      ? _handleSignUpWithGoogle
                                      : null,
                              style: Buttonstyle.white,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'lib/assets/images/auth/google.png',
                                    height: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Sign in with Google',
                                    style: Textstyle.body,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                'Don\'t have an account?',
                                style: Textstyle.body,
                              ),
                              const SizedBox(width: 5),
                              GestureDetector(
                                onTap:
                                    _isLoading
                                        ? null
                                        : () => widget.toggleView(),
                                child: Text(
                                  'Sign Up',
                                  style: Textstyle.bodyNeon,
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
            );
          },
        ),
      ),
    );
  }
}
