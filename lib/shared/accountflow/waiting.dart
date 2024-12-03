// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solace/screens/home/home.dart';

class WaitingScreen extends StatelessWidget {
  final String? userRole;
  final String? institution;
  final String status;

  const WaitingScreen({
    super.key,
    this.userRole,
    this.institution,
    required this.status,
  });

  void _navigateToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              const Home()), // Replace with your HomeScreen widget
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text("User not logged in."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Waiting for Verification')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.hasData) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final verificationStatus = userData['verify'];

            if (verificationStatus == 'verified') {
              // Navigate to HomeScreen when verified
              Future.microtask(() => _navigateToHome(context));
              return const SizedBox(); // Prevent rendering unnecessary UI while navigating
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Your application is under review.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Current status: $verificationStatus',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ),
            );
          }

          return const Center(child: Text('No data available.'));
        },
      ),
    );
  }
}
