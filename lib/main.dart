// ignore_for_file: avoid_print, unused_import

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:solace/controllers/cloud_messaging.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/get_started.dart';
import 'package:solace/services/auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  // Initialize Firebase Cloud Messaging
  await CloudMessagingService.initialize();

  // Initialize Firebase App Check
  FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  // Set Firebase language
  FirebaseAuth.instance.setLanguageCode('en');

  // Sign out any existing user
  await AuthService().signOut();

  // Lock screen orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<MyUser?>.value(
      catchError: (_, __) => null,
      initialData: null,
      value: AuthService().user,
      child: MaterialApp(
        title: 'SOLACE',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const GetStarted(),
      ),
    );
  }
}
