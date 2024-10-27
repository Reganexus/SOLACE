import 'package:solace/screens/authenticate/login.dart';
import 'package:flutter/material.dart';
import 'package:solace/screens/authenticate/sign_up.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {

  // ************* for testing ************* //
  bool isTesting = true;
  bool isTestAdmin = false;
  // ************* for testing ************* //

  bool showLogInPage = false;
  toggleView() { setState(() => showLogInPage = !showLogInPage); }

  @override
  Widget build(BuildContext context) {
    if(isTesting){
      return LogIn(isTesting: isTesting, isTestAdmin: isTestAdmin);
    }

    if(showLogInPage) {
      return LogIn(toggleView: toggleView, isTesting: isTesting, isTestAdmin: isTestAdmin);
    } else {
      return SignUp(toggleView: toggleView);
    }
  }
}