// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/globals.dart';
import 'package:solace/shared/widgets/user_editprofile.dart';
import 'package:solace/themes/colors.dart';

class Verify extends StatefulWidget {
  const Verify({super.key});

  @override
  State<Verify> createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {
  bool isResendDisabled = false;
  bool isVerifying = true;
  bool isGoogleSignUp = false;
  int resendCooldown = 60;
  Timer? cooldownTimer;

  @override
  void initState() {
    super.initState();
    determineSignUpMethod();
    if (!emailVerificationEnabled) {
      navigateToHome();
    } else {
      sendVerificationEmail();
      listenForEmailVerification();
    }
  }

  Future<void> createUserDocument(String uid) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        // Set user document only if it doesn't exist
        await userRef.set({
          'uid': uid,
          'isVerified': false,
          'newUser': true,
          // Add other necessary fields
        });
        debugPrint('User document created for UID: $uid');
      }
    } catch (e) {
      debugPrint('Error creating user document: $e');
    }
  }

  void determineSignUpMethod() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      debugPrint('Current user: ${user.email}');
      for (var userInfo in user.providerData) {
        debugPrint('Provider: ${userInfo.providerId}');
        if (userInfo.providerId == 'google.com') {
          if (!isGoogleSignUp) {
            setState(() {
              isGoogleSignUp = true;
            });
          }
          break;
        }
      }
    }
  }

  void sendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser!;
    if (!user.emailVerified) {
      try {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification email sent to ${user.email}')),
          );
        }
        debugPrint('Verification email sent to: ${user.email}');
      } catch (e) {
        debugPrint('Failed to send verification email: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send verification email')),
          );
        }
      }
    }
  }

  void listenForEmailVerification() async {
    while (isVerifying) {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        reloadUser();
      } else {
        break;
      }
    }
  }

  void reloadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        debugPrint('Reloading user: ${user.email}');
        await user.reload();
        if (user.emailVerified) {
          debugPrint('User is verified');
          await DatabaseService(uid: user.uid)
              .setUserVerificationStatus(user.uid, true);
          handlePostVerification(user.uid);
        } else {
          debugPrint('User is not verified');
          if (mounted) {
            setState(() {});
          }
        }
      } catch (e) {
        debugPrint("Error reloading user: $e");
      }
    }
  }

  // Example function for the verification process (step-by-step execution)
  Future<void> handlePostVerification(String uid) async {
    try {
      // Step 1: Check if the user is verified in Firebase Auth
      final updatedUser = FirebaseAuth.instance.currentUser;
      if (updatedUser == null) {
        _showError("No user found.");
        return; // Exit early if no user is authenticated
      }

      // Step 2: Check if the user is verified
      if (!updatedUser.emailVerified) {
        _showError("User email is not verified.");
        return; // Exit early if email is not verified
      }

      // Step 3: Proceed with Firestore data retrieval and update
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(updatedUser.uid);
      final userDoc =
          await userRef.get(); // This waits for Firestore to fetch the user

      // Step 4: If the user document exists and is not verified, update it
      if (userDoc.exists && !userDoc['isVerified']) {
        await userRef.update({'isVerified': true});
        debugPrint('User verification status updated in Firestore.');
      }

      // Step 5: Navigate based on the user data (after Firestore update)
      final userData =
          await DatabaseService(uid: updatedUser.uid).getUserData();
      if (userData?.newUser == true) {
        navigateToEditProfile();
      } else {
        navigateToHome();
      }
    } catch (e) {
      debugPrint('Error in verification process: $e');
      _showError("An error occurred during verification.");
    }
  }

// Example function to handle navigation step-by-step
  Future<void> navigateToHome() async {
    // Ensure the widget is still mounted before attempting navigation
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    }
  }

  Future<void> navigateToEditProfile() async {
    // Ensure the widget is still mounted before attempting navigation
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
      );
    }
  }

// Method to show errors
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void resendVerificationEmail() {
    if (isResendDisabled) return;
    setState(() {
      isResendDisabled = true;
    });
    sendVerificationEmail();
    startCooldown();
  }

  void startCooldown() {
    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown > 0) {
        if (mounted && resendCooldown != resendCooldown) {
          setState(() {
            resendCooldown--;
          });
        }
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            isResendDisabled = false;
            resendCooldown = 60;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: AppColors.neon,
      body: Container(
        color: AppColors.neon,
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isVerifying)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            const SizedBox(height: 20),
            if (isGoogleSignUp)
              Column(
                children: const [
                  Text(
                    'Thanks for signing up with Google!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'We\'ve linked your Google account, so you\'re all set!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      color: AppColors.white,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Text(
                    'Verify your Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'A verification email has been sent to ',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Inter',
                            color: AppColors.white,
                          ),
                        ),
                        TextSpan(
                          text: user.email,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'No verification? ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          color: AppColors.white,
                        ),
                      ),
                      if (!isResendDisabled)
                        GestureDetector(
                          onTap: resendVerificationEmail,
                          child: const Text(
                            'Resend',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.white,
                            ),
                          ),
                        )
                      else
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              color: AppColors.white,
                            ),
                            children: [
                              TextSpan(
                                text: '$resendCooldown ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(
                                text: 'seconds.',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
