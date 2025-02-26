// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/shared/accountflow/rolechooser.dart';
import 'package:solace/shared/accountflow/user_editprofile.dart';
import 'package:solace/shared/globals.dart';
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
    if (isGoogleSignUp) {
      // Directly handle Google sign-up as verified
      handlePostVerification(FirebaseAuth.instance.currentUser!.uid);
    } else {
      if (!emailVerificationEnabled) {
        navigateToHome();
      } else {
        sendVerificationEmail();
        listenForEmailVerification();
      }
    }
  }

  void determineSignUpMethod() {
    final user = FirebaseAuth.instance.currentUser;
    var userProviderData = user?.providerData;
    debugPrint("determine sign up method: $userProviderData.");
    if (user != null) {
      for (var userInfo in user.providerData) {
        if (userInfo.providerId == 'google.com') {
          setState(() {
            isGoogleSignUp = true;
          });
          return;
        }
      }
    }
    setState(() {
      isGoogleSignUp = false;
    });
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
      } catch (e) {
        _showError('Failed to send verification email. Please try again.');
      }
    }
  }

  void listenForEmailVerification() async {
    const timeoutDuration = Duration(minutes: 5);
    final startTime = DateTime.now();

    while (isVerifying) {
      await Future.delayed(const Duration(seconds: 5));
      if (DateTime.now().difference(startTime) > timeoutDuration) {
        handleTimeout();
        break;
      }

      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.reload();
          if (user.emailVerified) {
            debugPrint("Email verified for user: ${user.uid}");
            setState(() {
              isVerifying = false;
            });

            // Update Firestore for the verified user
            String? role = await getUserRoleBySearching(user.uid);
            if (role != null) {
              await FirebaseFirestore.instance
                  .collection(role) // e.g., 'admin', 'caregiver'
                  .doc(user.uid)
                  .update({
                'isVerified': true,
                'newUser': true,
              });

              // Handle post-verification actions
              handlePostVerification(user.uid);
            } else {
              _showError("Role not found for the current user.");
            }
            break; // Exit the loop
          }
        } else {
          break;
        }
      }
    }
  }

  Future<void> handlePostVerification(String uid) async {
    try {
      // Add a delay before navigating to RoleChooser
      debugPrint("Navigating to RoleChooser for user: $uid.");
      await Future.delayed(const Duration(seconds: 3)); // 3-second delay
      navigateToRoleChooser();
    } catch (e) {
      debugPrint("Error in post-verification: ${e.toString()}");
      _showError('An error occurred during verification.');
    }
  }

  void handleTimeout() async {
    setState(() {
      isVerifying = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Verification timed out. Please verify your email and try again.'),
      ),
    );
    // Add a delay before redirecting to RoleChooser
    await Future.delayed(const Duration(seconds: 5)); // 3-second delay
    navigateToRoleChooser();
  }

  Future<String?> getUserRoleBySearching(String uid) async {
    const roleCollections = [
      'admin',
      'caregiver',
      'doctor',
      'patient',
      'unregistered'
    ];
    for (String collection in roleCollections) {
      final userDoc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(uid)
          .get();
      if (userDoc.exists) {
        return collection;
      }
    }
    return null;
  }

  Future<void> navigateToHome() async {
    if (mounted) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final uid = currentUser.uid;
        final role = await getUserRoleBySearching(uid);

        if (role != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Home(uid: uid, role: role),
            ),
          );
        } else {
          _showError("Role not found for the current user.");
        }
      } else {
        _showError("User is not authenticated.");
      }
    }
  }

  void navigateToEditProfileScreen() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(),
        ),
      );
    }
  }

  Future<void> navigateToRoleChooser() async {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RoleChooser(
            onRoleSelected: (String role) async {
              final userRole = UserData.getUserRoleFromString(role);
              if (userRole != null) {
                final user = FirebaseAuth.instance.currentUser!;
                await AuthService().initializeUserDocument(
                  uid: user.uid,
                  email: user.email ?? '',
                  userRole: userRole,
                  isVerified: true,
                  newUser: true,
                );
                // Navigate to EditProfileScreen after the role is selected
                navigateToEditProfileScreen();
              } else {
                _showError('Invalid role selected.');
              }
            },
          ),
        ),
      );
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
        setState(() {
          resendCooldown--;
        });
      } else {
        timer.cancel();
        setState(() {
          isResendDisabled = false;
        });
      }
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
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
              Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Verifying your account...',
                    style: TextStyle(color: AppColors.white, fontSize: 18),
                  ),
                ],
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
