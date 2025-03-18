// ignore_for_file: avoid_print, unused_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'firebase_options.dart';
import 'package:solace/controllers/messaging_service.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/get_started.dart';
import 'package:solace/services/auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await initializeFirebase();

  // Lock screen orientation
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);


  // Check if the app is a new install
  bool isNewInstall = await checkFirstInstall();

  runApp(MyApp(
    initialScreen: isNewInstall ? const GetStarted() : const Authenticate(),
  ));
}

Future<void> initializeFirebase() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: 'solace',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Activate Firebase App Check
  FirebaseAppCheck.instance
      .activate(androidProvider: AndroidProvider.playIntegrity);

  // Set Firebase Auth language
  FirebaseAuth.instance.setLanguageCode('en');
}

Future<bool> checkFirstInstall() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isNewInstall') == null) {
      await prefs.setBool('isNewInstall', false);
      return true;
    }
  } catch (e) {
    print('Error checking installation state: $e');
  }
  return false;
}

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
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: initialScreen,
      ),
    );
  }
}
