// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/screens/wrapper.dart';
import 'package:solace/services/database.dart'; // Import your DatabaseService
import 'package:solace/themes/colors.dart'; // Make sure to import your colors

class Verify extends StatefulWidget {
  const Verify({super.key});

  @override
  State<Verify> createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {
  @override
  void initState() {
    sendVerifyLink();
    super.initState();
  }

  void sendVerifyLink() async {
    final user = FirebaseAuth.instance.currentUser!;
    if (!user.emailVerified) {
      await user.sendEmailVerification().then((_) {
        debugPrint('Email verification link sent.');
      });
    }
  }

  // Reloads user and updates verification status in Firestore if verified
  Future<void> reloadUser() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.reload();
    if (user.emailVerified) {
      // Update the user's verification status in Firestore
      await DatabaseService(uid: user.uid).setUserVerificationStatus(user.uid, true);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Wrapper()),
            (Route<dynamic> route) => false,
      );
    } else {
      setState(() {}); // Trigger UI update if still not verified
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, // Set the background color here
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Email verification sent. Check your email and click the link.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: reloadUser,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
