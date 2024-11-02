// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/screens/authenticate/verify.dart';
import 'package:solace/screens/home/home.dart';
import 'package:flutter/material.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool enableVerification = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if(snapshot.hasData) {
            if(enableVerification) {
              if(snapshot.data!.emailVerified) {
                return Home();
              } else {
                return Verify();
              }
            } else {
              return Home();
            }
          } else {
            return Authenticate();
          }
        }
      ),
    );
  }
}