import 'package:solace/screens/authenticate/login.dart';
import 'package:flutter/material.dart';
import 'package:solace/screens/authenticate/sign_up.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool showLogInPage = true;
  toggleView() { setState(() => showLogInPage = !showLogInPage); }

  @override
  Widget build(BuildContext context) {
    if(showLogInPage) {
      return LogIn(toggleView: toggleView);
    } else {
      return SignUp(toggleView: toggleView);
    }
  }
}
