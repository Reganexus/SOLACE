import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/get_started.dart';
import 'package:solace/services/auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:solace/shared/accountflow/requirements.dart';

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
        home: const GetStarted(), // Main entry point widget
        // home: const RoleChooser(),
        // home: const RequirementsScreen(),
      ),
    );
  }
}