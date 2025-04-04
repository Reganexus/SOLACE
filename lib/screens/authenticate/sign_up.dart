// ignore_for_file: use_build_context_synchronously, unused_import, unnecessary_null_comparison

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/verify.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/error_handler.dart';
import 'package:solace/services/validator.dart';
import 'package:solace/shared/accountflow/rolechooser.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/themes/inputdecoration.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart'; // For Toast if needed

class SignUp extends StatefulWidget {
  final Function toggleView;
  const SignUp({super.key, required this.toggleView});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  MyUser? currentUser;

  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  late final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ignore: prefer_final_fields
  bool _isSignUpButtonEnabled = true;
  bool _isGoogleSignUpButtonEnabled = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _agreeToTerms = false;

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

  Future<Map<String, dynamic>> _loadTermsAndConditions() async {
    final terms = await rootBundle.loadString(
      'lib/assets/terms_and_conditions.json',
    );
    return json.decode(terms);
  }

  void _showTermsDialog(Map<String, dynamic> termsData) {
    final terms = termsData['terms'];
    final sections = terms['sections'] as Map<String, dynamic>;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.white,
            title: Text(
              terms['title'] ?? 'Terms and Conditions',
              style: Textstyle.heading,
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (terms['lastUpdated'] != null)
                    Text(
                      terms['lastUpdated'],
                      style: Textstyle.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (terms['welcomeMessage'] != null)
                    Text(terms['welcomeMessage'], style: Textstyle.body),
                  const SizedBox(height: 16),
                  if (terms['subMessage'] != null)
                    Text(
                      terms['subMessage'],
                      style: Textstyle.body.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 16),
                  ...sections.entries.map((entry) {
                    final section = entry.value as Map<String, dynamic>;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (section['numberHeader'] != null)
                          Text(
                            section['numberHeader'],
                            style: Textstyle.subheader,
                          ),
                        if (section['content'] != null)
                          Text(section['content'], style: Textstyle.body),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                  const Divider(),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: Buttonstyle.neon,
                      child: Text('OK', style: Textstyle.largeButton),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showError(List<String> errorMessages) {
    if (errorMessages.isEmpty || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder:
          (context) => ErrorDialog(title: 'Error', messages: errorMessages),
    );
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

  void togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      _showError(['Please match the credentials to the criteria']);
      return;
    }

    if (!_agreeToTerms) {
      _showError(['Please accept the terms and conditions to proceed.']);
      return;
    }

    // Check if the widget is still mounted before calling setState
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Check if the email already exists in the database
      final existingUser = await _db.getUserDataByEmail(email);
      if (existingUser != null) {
        _showError([
          'This email is already associated with an existing account.',
        ]);
        return;
      }

      // Proceed with the sign-up process
      await _auth.signUpWithEmailAndPassword(email, password);

      final String? userId = _auth.currentUserId;
      if (userId == null) {
        _showError(['Current user ID is not found.']);
        return;
      }

      showToast('Account successfully created!');

      // Fetch the user's role after sign-up
      final userRole = await _db.fetchAndCacheUserRole(userId);
      if (userRole == null) {
        _showError(['User role could not be determined.']);
        return;
      }

      // Navigate based on verification status
      await _navigateBasedOnVerification(userId, userRole);
    } catch (error) {
      _showError(['An error occurred during sign-up: ${error.toString()}']);
    } finally {
      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignUpWithGoogle() async {
    if (!_isGoogleSignUpButtonEnabled) return;

    // Check if the widget is still mounted before calling setState
    if (mounted) {
      setState(() => _isGoogleSignUpButtonEnabled = false);
    }

    try {
      await _runWithLoadingState(() async {
        final myUser = await _auth.signInWithGoogle();
        if (myUser != null) {
          final userRole = await _db.fetchAndCacheUserRole(myUser.uid);
          if (userRole != null) {
            await _navigateBasedOnVerification(myUser.uid, userRole);
          } else {
            _showError(['User role not found. Please contact support.']);
          }
        }
      });
    } catch (e) {
      _handleGoogleSignInError(e);
    } finally {
      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() => _isGoogleSignUpButtonEnabled = true);
      }
    }
  }

  void _handleGoogleSignInError(dynamic error) {
    if (error is FirebaseAuthException) {
      _handleFirebaseAuthError(error);
    } else if (error is TimeoutException) {
      _showError(['The request timed out. Please try again later.']);
    } else if (!error.toString().contains('google_sign_in_aborted')) {
      _showError(['An error occurred during Google sign-in.']);
    }
  }

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    final messages = {
      'account-exists-with-different-credential':
          'An account already exists with a different credential.',
      'invalid-credential': 'Invalid credentials provided.',
      'user-disabled': 'This user has been disabled. Contact support.',
      'operation-not-allowed':
          'This operation is not allowed. Contact support.',
    };
    _showError([messages[e.code] ?? 'An unexpected error occurred.']);
  }

  Future<void> _navigateBasedOnVerification(String uid, String userRole) async {
    final userDoc = FirebaseFirestore.instance.collection(userRole).doc(uid);
    final userData = (await userDoc.get()).data();

    if (userData?['isVerified'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Home(uid: uid, role: userRole)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Verify()),
      );
    }
  }

  Future<void> _runWithLoadingState(Future<void> Function() task) async {
    setState(() => _isLoading = true);
    try {
      await task();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSignUpHeader() {
    return Column(
      children: [
        Image.asset('lib/assets/images/auth/solace.png', width: 100),
        const SizedBox(height: 40),
        Text('Sign Up', style: Textstyle.title),
        const SizedBox(height: 20),
      ],
    );
  }

  TextStyle get focusedLabelStyle => Textstyle.bodyNeon;

  Widget buildTextFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    bool obscureText = false,
    Widget? suffixIcon,
    required String? Function(String?) validator,
    required Function(String) onChanged,
    Function(String)? onFieldSubmitted,
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
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  Widget _emailField() => buildTextFormField(
    controller: _emailController,
    focusNode: _emailFocusNode,
    labelText: 'Email',
    validator: Validator.email,
    onChanged: (val) {},
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
    validator: Validator.password,
    onChanged: (val) {},
    onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
  );

  Widget _buildTermsAndConditions() {
    return SizedBox(
      height: 40,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _agreeToTerms,
              onChanged: (val) {
                setState(() {
                  _agreeToTerms = val!;
                });
              },
            ),
            Text('I agree to the ', style: Textstyle.body),
            GestureDetector(
              onTap: () async {
                final terms = await _loadTermsAndConditions();
                _showTermsDialog(terms);
              },
              child: Text('terms and conditions', style: Textstyle.bodyPurple),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed:
            (!_isLoading && _isSignUpButtonEnabled) ? _handleSignUp : null,
        style: (!_isSignUpButtonEnabled) ? Buttonstyle.gray : Buttonstyle.neon,
        child:
            _isLoading
                ? SizedBox(width: 26, height: 26, child: Loader.loaderWhite)
                : Text('Sign Up', style: Textstyle.largeButton),
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: <Widget>[
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text("or"),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed:
            (!_isLoading && _isGoogleSignUpButtonEnabled)
                ? _handleSignUpWithGoogle
                : null,
        style: Buttonstyle.white,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('lib/assets/images/auth/google.png', height: 24),
            const SizedBox(width: 10),
            Text('Sign up with Google', style: Textstyle.body),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleViewButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Already have an account?', style: Textstyle.body),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: _isLoading ? null : () => widget.toggleView(),
          child: Text('Login', style: Textstyle.bodyNeon),
        ),
      ],
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
            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildSignUpHeader(),
                      _emailField(),
                      const SizedBox(height: 20),
                      _passwordField(),
                      const SizedBox(height: 20),
                      _buildTermsAndConditions(),
                      const SizedBox(height: 20),
                      _buildSignUpButton(),
                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildGoogleButton(),
                      const SizedBox(height: 20),
                      _buildToggleViewButton(),
                    ],
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
