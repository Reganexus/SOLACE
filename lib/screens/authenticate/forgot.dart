import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  
  TextEditingController email = TextEditingController();
  String error = '';

  void resetPassword() async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);
    setState(() => error = 'Email sent');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: email,
              decoration: InputDecoration(hintText: 'Enter email'),
            ),
            ElevatedButton(
              onPressed: () => resetPassword(),
              child: Text('Send Link'),
            ),
            if (error.isNotEmpty) ...[
              SizedBox(
                height: 20,
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}