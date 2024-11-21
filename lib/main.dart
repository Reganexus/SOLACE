import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/hive_boxes.dart';
import 'package:solace/models/local_user.dart';
import 'package:solace/models/local_users.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/models/time_stamp_adapter.dart';
import 'package:solace/screens/wrapper.dart';
import 'package:solace/services/auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Activate Firebase App Check for development (using debug token)
  FirebaseAppCheck appCheck = FirebaseAppCheck.instance;

  // Use a debug token for testing (remove this for production)
  await appCheck.activate();

  // Optionally sign out any user (if you need this)
  await AuthService().signOut();

  await Hive.initFlutter();

  // Register the adapters
  Hive.registerAdapter(LocalUserAdapter());
  Hive.registerAdapter(LocalUsersAdapter());
  Hive.registerAdapter(TimestampAdapter());  // Register the Timestamp adapter

  // Open the box
  localUsersBox = await Hive.openBox<LocalUser>('LocalUsers');
  
  // Lock orientation to portrait mode
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
      catchError: (_, __) => null, // Catch errors and return null (safe fallback)
      initialData: null, // Initial value when the stream is not yet available
      value: AuthService().user, // Stream of user authentication state
      child: MaterialApp(
        title: 'SOLACE',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const Wrapper(), // Main entry point widget
      ),
    );
  }
}
