import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/user.dart';
import 'package:solace/screens/get_started_screen.dart';
import 'package:solace/services/auth.dart';
import 'screens/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:solace/screens/user/user_main.dart';
// import 'package:solace/screens/caregiver/caregiver_main.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<MyUser?>.value(
      catchError: (_,__) => null,
      initialData: null,
      value: AuthService().user,
      child: const MaterialApp(
        title: 'SOLACE',
        // home: UserMainScreen(),
        // home: CaregiverMainScreen(),
        //home: GetStarted(), // Set your initial page here
        home: Wrapper(),
      ),
    );
  } 
}