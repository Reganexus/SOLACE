import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';

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
      child: StreamProvider<UserData?>.value(
        catchError: (_,__) => null,
        initialData: null,
        value: AuthService().currentUser != null
            ? DatabaseService(uid: AuthService().currentUser!.uid).userData
            : null, // Ensure user is logged in
        child: MaterialApp(
          title: 'SOLACE',
          home: Wrapper(),
        ),
      ),
    );
  }
}

