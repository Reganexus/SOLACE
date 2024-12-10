import 'dart:async'; // Import for Timer
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/themes/colors.dart';

class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  TextEditingController email = TextEditingController();
  String error = '';
  bool isResendDisabled = false; // Controls cooldown state
  bool emailSent = false; // Tracks if the email was successfully sent
  int resendCooldown = 60; // Cooldown period in seconds
  Timer? cooldownTimer; // Timer instance for cooldown

  @override
  void dispose() {
    cooldownTimer?.cancel(); // Cancel the timer if the widget is disposed
    email.dispose();
    super.dispose();
  }

  void resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);
      setState(() {
        emailSent = true;
      });
      startCooldown();
    } catch (e) {
      setState(() => error = 'Error: ${e.toString()}');
    }
  }

  void startCooldown() {
    setState(() {
      isResendDisabled = true;
    });
    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown > 0) {
        setState(() {
          resendCooldown--;
        });
      } else {
        timer.cancel();
        setState(() {
          isResendDisabled = false;
          resendCooldown = 60; // Reset cooldown
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Back'),
        backgroundColor: AppColors.neon,
        scrolledUnderElevation: 0.0,
        foregroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.neon,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss the keyboard
        },
        child: Container(
          color: AppColors.neon,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Forgot Password',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: email,
                decoration: InputDecoration(
                  hintText: 'Enter your Email',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.blackTransparent,
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: isResendDisabled ? null : resetPassword,
                style: TextButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  backgroundColor: AppColors.blackTransparent,
                  foregroundColor: isResendDisabled
                      ? AppColors.whiteTransparent
                      : AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isResendDisabled
                    ? Text(
                  'Email Sent, $resendCooldown seconds',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : const Text(
                  'Send Link',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (emailSent) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Changed your password? ',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontFamily: 'Inter',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const Authenticate()),
                        );
                      },
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    error,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
