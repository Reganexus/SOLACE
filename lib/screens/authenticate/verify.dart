import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/screens/wrapper.dart';

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
    await user.sendEmailVerification().then((val) => {
      print('Email verification link sent.')
    });
  }

  // Reloads user and redirects to Wrapper if verified
  Future<void> reloadUser() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.reload();
    if (user.emailVerified) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Wrapper()),
        (Route<dynamic> route) => false,
      );
    } else {
      setState(() {}); // Trigger UI update if not verified yet
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Email verification sent. Check your email and click the link.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: reloadUser,
              child: Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}