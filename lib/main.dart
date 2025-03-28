// ignore_for_file: avoid_print, unused_import

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';
import 'firebase_options.dart';
import 'package:solace/controllers/messaging_service.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/get_started.dart';
import 'package:solace/services/auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and related services
  await _initializeFirebaseAndMessaging();

  // Lock screen orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Determine the initial screen
  final bool isNewInstall = await _isFirstInstall();

  DatabaseService db = DatabaseService();
  await db.clearUserRoleCache();
  // Run the app
  runApp(
    MyApp(
      initialScreen: isNewInstall ? const GetStarted() : const Authenticate(),
    ),
  );
}

/// Initializes Firebase and messaging services.
Future<void> _initializeFirebaseAndMessaging() async {
  try {
    // Check if Firebase has already been initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        name: 'solace-28954',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully.');
    } else {
      debugPrint('Firebase already initialized.');
    }

    // Activate Firebase App Check
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );

    // Initialize Messaging Service
    await MessagingService.initialize();
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }
}

/// Checks if the app is being run for the first time.
Future<bool> _isFirstInstall() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool isNewInstall = prefs.getBool('isNewInstall') ?? true;
  if (isNewInstall) {
    await prefs.setBool('isNewInstall', false);
  }
  return isNewInstall;
}

/// Main application widget.
class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

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
          primaryColor: AppColors.white,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: initialScreen,
      ),
    );
  }
}
