// ignore_for_file: avoid_print, use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/error_handler.dart';
import 'package:solace/shared/accountflow/rolechooser.dart';
import 'package:solace/shared/globals.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/email_verification.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';

class Verify extends StatefulWidget {
  const Verify({super.key});

  @override
  State<Verify> createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {
  final EmailVerificationService _emailVerificationService =
      EmailVerificationService();
  final DatabaseService db = DatabaseService();

  bool isResendDisabled = false;
  bool isVerifying = true;
  bool isGoogleSignUp = false;
  bool _navigated = false;
  bool _isCancelled = false;
  int resendCooldown = 60;
  Timer? cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVerificationFlow(); // Run after the widget tree is built.
    });
  }

  @override
  void dispose() {
    _isCancelled = true;
    cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeVerificationFlow() async {
    determineSignUpMethod();
    if (isGoogleSignUp) {
      await fetchAndNavigate(FirebaseAuth.instance.currentUser!.uid);
    } else if (!emailVerificationEnabled) {
      navigateToHome();
    } else {
      sendVerificationEmail();
      await verifyEmailAndRole();
    }
  }

  Future<void> verifyEmailAndRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not authenticated.");
      }

      final isVerified = await _emailVerificationService
          .pollEmailVerificationStatus(
            timeoutMinutes: 5,
            checkIntervalSeconds: 5,
          );

      if (isVerified && !_isCancelled) {
        final role = await db.fetchAndCacheUserRole(user.uid);

        if (role != null) {
          final userRole = UserRoleExtension.fromString(role);
          if (userRole == null) {
            throw Exception("Invalid role string: $role");
          }

          await db.updateUserVerificationStatus(
            uid: user.uid,
            userRole: userRole,
            isVerified: true,
          );

          await fetchAndNavigate(user.uid);
        } else {
          throw Exception("Role not found for the current user.");
        }
      } else if (!_isCancelled) {
        _handleTimeout();
      }
    } catch (e) {
      if (!_isCancelled) _showError([e.toString()]);
    }
  }

  void determineSignUpMethod() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        isGoogleSignUp = user.providerData.any(
          (info) => info.providerId == 'google.com',
        );
      });
    }
  }

  Future<void> sendVerificationEmail() async {
    await handleSendVerificationEmail();
  }

  Future<void> handleSendVerificationEmail({bool startCooldown = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        showToast('Verification email sent to ${user.email}');
        if (startCooldown) {
          startCooldownTimer();
        }
      } catch (e) {
        _showError(['Failed to send verification email. Please try again.']);
      }
    }
  }

  void listenForEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showError(["User not authenticated."]);
      return;
    }

    try {
      bool isVerified = await _emailVerificationService
          .pollEmailVerificationStatus(
            timeoutMinutes: 5,
            checkIntervalSeconds: 5,
          );

      if (isVerified && !_isCancelled) {
        String? role = await db.fetchAndCacheUserRole(user.uid);
        if (role != null) {
          await FirebaseFirestore.instance
              .collection(role)
              .doc(user.uid)
              .update({'isVerified': true, 'newUser': true});
          await fetchAndNavigate(user.uid);
        } else {
          _showError(["Role not found for the current user."]);
        }
      } else if (!_isCancelled) {
        _handleTimeout();
      }
    } catch (e) {
      if (!_isCancelled) {
        _showError([
          "An error occurred during email verification. Please try again.",
        ]);
      }
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

  Future<void> _handleTimeout() async {
    setState(() => isVerifying = false);
    _showError([
      'Verification timed out. Please verify your email and try again.',
    ]);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Add a delay and fetch user data before navigating
      await Future.delayed(const Duration(seconds: 3));
      await fetchAndNavigate(user.uid);
    } else {
      _showError(["User is not authenticated."]);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => Verify()),
    );
  }

  void resendVerificationEmail() {
    if (!isResendDisabled) {
      handleSendVerificationEmail(startCooldown: true);
    }
  }

  void startCooldownTimer() {
    setState(() {
      isResendDisabled = true;
      resendCooldown = 60;
    });

    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCancelled) timer.cancel();
      if (resendCooldown > 0) {
        setState(() => resendCooldown--);
      } else {
        timer.cancel();
        setState(() => isResendDisabled = false);
      }
    });
  }

  void _showError(List<String> errorMessages) {
    if (errorMessages.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder:
          (context) => ErrorDialog(title: 'Error', messages: errorMessages),
    );
  }

  Future<void> fetchAndNavigate(String uid) async {
    final userData = await db.fetchUserData(uid);

    if (userData != null) {
      debugPrint("User Data: ${userData.toMap()}");

      // Convert the UserData object to a map if needed
      final userMap = {
        'email': userData.email,
        'uid': userData.uid,
        'userRole': userData.userRole,
        'isVerified': userData.isVerified,
        'newUser': userData.newUser,
        'profileImageUrl': userData.profileImageUrl,
        'phoneNumber': userData.phoneNumber,
        'gender': userData.gender,
        'birthday': userData.birthday?.toIso8601String() ?? '',
        'address': userData.address,
        'religion': userData.religion,
      };

      navigateToRoleChooser(userMap);
    } else {
      debugPrint("User data not found for UID: $uid");
      _showError(["Failed to fetch user data."]);
    }
  }

  Future<void> navigateToHome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final role = await db.fetchAndCacheUserRole(user.uid);
      if (role != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Home(uid: user.uid, role: role)),
        );
      } else {
        _showError(["Role not found for the current user."]);
      }
    } else {
      _showError(["User is not authenticated."]);
    }
  }

  void navigateToRoleChooser(Map<String, dynamic> userData) {
    if (!_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => RoleChooser(
                  onRoleSelected: (role) {
                    debugPrint("Selected role: $role");
                    // Handle role selection logic.
                  },
                ),
            settings: RouteSettings(arguments: userData),
          ),
        );
      });
    }
  }

  Widget _loader() {
    return Column(children: [Loader.loaderWhite]);
  }

  Widget _googleSignUp() {
    return Column(
      children: [
        Text(
          'Thanks for signing up with Google!',
          textAlign: TextAlign.center,
          style: Textstyle.title.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 20),
        Text(
          'We\'ve linked your Google account, so you\'re all set!',
          textAlign: TextAlign.center,
          style: Textstyle.bodyWhite,
        ),
      ],
    );
  }

  Widget _verification(User user) {
    return Column(
      children: [
        Text(
          'Verify your Account',
          textAlign: TextAlign.center,
          style: Textstyle.title.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 20),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'A verification email has been sent to ',
                style: Textstyle.bodyWhite,
              ),
              TextSpan(
                text: user.email ?? 'Unknown email',
                style: Textstyle.bodyWhite.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('No verification? ', style: Textstyle.bodyWhite),
            if (!isResendDisabled)
              GestureDetector(
                onTap: resendVerificationEmail,
                child: Text(
                  'Resend',
                  style: Textstyle.bodyWhite.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.white,
                  ),
                ),
              )
            else
              RichText(
                text: TextSpan(
                  style: Textstyle.bodyWhite,
                  children: [
                    TextSpan(
                      text: '$resendCooldown ',
                      style: Textstyle.bodyWhite.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: 'seconds.', style: Textstyle.bodyWhite),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: AppColors.neon,
      body: Container(
        color: AppColors.neon,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isVerifying) _loader(),
            const SizedBox(height: 20),
            if (isGoogleSignUp) _googleSignUp() else _verification(user),
          ],
        ),
      ),
    );
  }
}
