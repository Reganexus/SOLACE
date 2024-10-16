import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/screens/get_started_screen.dart';
import 'package:solace/screens/login_screen.dart';
import 'package:solace/screens/signup_screen.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'SOLACE',
      home: GetStarted(), // Set your initial page here
    );
  }
}