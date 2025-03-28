import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/error_handler.dart';
import 'package:solace/services/validator.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/inputdecoration.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';

class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  final DatabaseService _databaseService = DatabaseService();
  final FocusNode _emailFocusNode = FocusNode();
  final TextEditingController _emailController = TextEditingController();

  bool isResendDisabled = false;
  bool emailSent = false;
  int resendCooldown = 60;
  static const int _resendCooldownDuration = 60;
  Timer? cooldownTimer;
  bool isLoading = false;

  @override
  void dispose() {
    cooldownTimer?.cancel();
    _emailFocusNode.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void resetPassword() async {
    final validationError = Validator.email(_emailController.text);
    if (validationError != null) {
      _showError([validationError]);
      return;
    }

    setState(() => isLoading = true);

    try {
      final userData = await _databaseService.getUserDataByEmail(
        _emailController.text,
      );
      if (userData == null) {
        _showError(['No user found with this email.']);
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text,
      );

      if (context.mounted) {
        // Show a SnackBar after the email is sent
        showToast('Password reset email sent successfully.');

        // Navigate to Authenticate screen after the SnackBar
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Authenticate()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError([Validator.firebaseError(e.code)]);
    } catch (e) {
      _showError(['An unexpected error occurred. Please try again later.']);
    } finally {
      setState(() => isLoading = false);
    }
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

  void startCooldown() {
    setState(() {
      isResendDisabled = true;
      resendCooldown = _resendCooldownDuration;
    });
    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown > 0) {
        setState(() => resendCooldown--);
      } else {
        timer.cancel();
        setState(() => isResendDisabled = false);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.neon,
        foregroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      backgroundColor: AppColors.neon,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Forgot Password',
                style: Textstyle.title.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Enter your email address below to receive a password reset link.',
                style: Textstyle.body.copyWith(color: AppColors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      enabled:
                          !isLoading &&
                          !isResendDisabled, // Disable during loading or resend cooldown
                      decoration: InputDecorationStyles.build(
                        !isResendDisabled || isLoading
                            ? 'Enter your Email'
                            : "",
                        _emailFocusNode,
                      ).copyWith(
                        labelStyle: TextStyle(color: AppColors.black),
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.blackTransparent,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.blackTransparent,
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 1,
                      style: Textstyle.body.copyWith(color: AppColors.black),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    height: 56,
                    child: TextButton(
                      onPressed:
                          (isResendDisabled || isLoading)
                              ? null
                              : resetPassword,
                      style: Buttonstyle.darkgray.copyWith(
                        shape: WidgetStateProperty.all(
                          const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      child:
                          isLoading
                              ? Loader.loaderWhite
                              : Text(
                                isResendDisabled ? '$resendCooldown s' : 'Send',
                                style: Textstyle.smallButton,
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
