// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async'; // Import the Timer class
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/services/database.dart'; // Import your DatabaseService
import 'package:solace/shared/globals.dart';
import 'package:solace/shared/widgets/user_editprofile.dart';
import 'package:solace/themes/colors.dart'; // Make sure to import your colors

class Verify extends StatefulWidget {
  const Verify({super.key});

  @override
  State<Verify> createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {
  bool isResendDisabled = false; // Prevents multiple requests in a short time
  bool isVerifying = true; // Indicates if we are currently verifying the email
  bool isGoogleSignUp = false; // Indicates if the user signed up with Google
  int resendCooldown = 60; // Cooldown period in seconds
  Timer? cooldownTimer; // Timer instance for cooldown

  @override
  void initState() {
    super.initState();
    determineSignUpMethod();
    if (!emailVerificationEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      });
    } else {
      sendVerifyLink();
      listenForVerification();
    }
  }

  void determineSignUpMethod() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Check if the user signed up with Google
      for (var userInfo in user.providerData) {
        if (userInfo.providerId == 'google.com') {
          setState(() {
            isGoogleSignUp = true;
          });
          break;
        }
      }
    }
  }

  void sendVerifyLink() async {
    final user = FirebaseAuth.instance.currentUser!;
    if (!user.emailVerified) {
      await user.sendEmailVerification().then((_) {
        debugPrint('Verification email sent to: ${user.email}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification email sent to ${user.email}')),
        );
      });
    }
  }

  void listenForVerification() async {
    while (isVerifying) {
      await Future.delayed(const Duration(seconds: 5)); // Check every 5 seconds
      if (mounted) {
        // Ensure the widget is still in the widget tree
        reloadUser();
      } else {
        break; // Stop the loop if the widget is no longer mounted
      }
    }
  }

  void reloadUser() async {
    final user = FirebaseAuth.instance.currentUser;

    // Ensure `user` is not null and `mounted` is true before continuing
    if (user != null && mounted) {
      await user.reload();
      if (user.emailVerified) {
        await DatabaseService(uid: user.uid)
            .setUserVerificationStatus(user.uid, true);

        // Fetch user data to check for `newUser`
        final userData = await DatabaseService(uid: user.uid).getUserData();
        if (userData?.newUser == true) {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => EditProfileScreen()),
              (Route<dynamic> route) => false,
            );
          }
        } else {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Home()),
              (Route<dynamic> route) => false,
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isVerifying = true; // Continue verification spinner if not verified
          });
        }
      }
    } else {
      setState(() {
        isVerifying = false; // Exit the verification loop if user is null
      });
    }
  }

  @override
  void dispose() {
    isVerifying = false; // Stop the verification loop when widget is disposed
    cooldownTimer?.cancel(); // Cancel the cooldown timer
    super.dispose();
  }

  void resendVerificationEmail() async {
    setState(() {
      isResendDisabled = true; // Temporarily disable button to prevent spamming
    });
    sendVerifyLink();
    startCooldown();
  }

  void startCooldown() {
    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown > 0) {
        setState(() {
          resendCooldown--;
        });
      } else {
        timer.cancel();
        setState(() {
          isResendDisabled = false; // Enable resend after cooldown
          resendCooldown = 60; // Reset cooldown
        });
      }
    });
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
            // Conditional UI based on sign-in method
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
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'A verification email has been sent to ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
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
                      if (!isResendDisabled) // Show the Resend Gesture Detector if not disabled
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
                      else // Show cooldown timer if disabled
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
                                  fontWeight:
                                      FontWeight.bold, // Bold for the countdown
                                ),
                              ),
                              const TextSpan(
                                text: 'seconds.',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.normal, // Normal for "seconds"
                                ),
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
