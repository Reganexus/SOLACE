// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/themes/colors.dart';
import 'firebase_options.dart';
import 'package:solace/controllers/messaging_service.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/get_started.dart';
import 'package:solace/services/auth.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  MessagingService.showLocalNotification(message);
  FirebaseFirestore.instance.collection('messages').add({
    'text': 'background message',
  });
}

const String _isNewInstallKey = 'isNewInstall';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  await _initializeMessaging();

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("🚀 Notification Clicked! Data: ${message.data}");
  });

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final Widget initialScreen = await _determineInitialScreen();
  runApp(MyApp(initialScreen: initialScreen));
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      name: "solace-28954",
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
}

Future<void> _initializeMessaging() async {
  try {
    MessagingService.initialize();
  } catch (e) {
    print("Error initializing messaging service: $e");
  }
}

Future<Widget> _determineInitialScreen() async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isNewInstall = prefs.getBool(_isNewInstallKey) ?? true;
    if (isNewInstall) {
      await prefs.setBool(_isNewInstallKey, false);
      print("App is newly installed");
      return const GetStarted();
    }
    return const Authenticate();
  } catch (e) {
    print("Error determining initial screen: $e");
    return const Authenticate(); // Default to Authenticate on error
  }
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
          primaryColor: AppColors.white,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: initialScreen,
      ),
    );
  }
}
