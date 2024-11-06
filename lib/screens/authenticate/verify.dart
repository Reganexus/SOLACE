// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async'; // Import the Timer class
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/services/database.dart'; // Import your DatabaseService
import 'package:solace/shared/globals.dart';
import 'package:solace/themes/colors.dart'; // Make sure to import your colors

class Verify extends StatefulWidget {
  const Verify({super.key});

  @override
  State<Verify> createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {
  bool isResendDisabled = false; // Prevents multiple requests in a short time
  bool isVerifying = true; // Indicates if we are currently verifying the email
  int resendCooldown = 60; // Cooldown period in seconds
  Timer? cooldownTimer; // Timer instance for cooldown

  @override
  void initState() {
    super.initState();
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

  Future<void> reloadUser() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.reload();
    if (user.emailVerified) {
      debugPrint("User email is verified in Firebase.");
      await DatabaseService(uid: user.uid).setUserVerificationStatus(user.uid, true);

      // Instead of navigating through Wrapper, navigate directly to Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Home()),
            (Route<dynamic> route) => false,
      );
    } else {
      debugPrint("User email is not verified yet.");
      setState(() {
        isVerifying = true; // Continue the spinner if still not verified
      });
    }
  }


  void listenForVerification() async {
    while (isVerifying) {
      await Future.delayed(const Duration(seconds: 5)); // Check every 5 seconds
      await reloadUser();
    }
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
  void dispose() {
    cooldownTimer?.cancel(); // Cancel the timer if the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: AppColors.neon,
      body: Container(
        color: AppColors.neon,
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isVerifying)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            const SizedBox(height: 20),
            const Text(
              'Verify your Account',
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
                            fontWeight: FontWeight.bold, // Bold for the countdown
                          ),
                        ),
                        const TextSpan(
                          text: 'seconds.',
                          style: TextStyle(
                            fontWeight: FontWeight.normal, // Normal for "seconds"
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
