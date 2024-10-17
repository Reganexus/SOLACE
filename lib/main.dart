import 'package:flutter/material.dart';
import 'package:solace/screens/get_started_screen.dart';
import 'package:solace/screens/user/user_main.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'SOLACE',
      home: UserMainScreen(), // Set your initial page here
    );
  }
}