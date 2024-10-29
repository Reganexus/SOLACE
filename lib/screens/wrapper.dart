import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/screens/authenticate/verify.dart';
import 'package:solace/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:solace/services/auth.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // // Get the user from the provider (auth state)
    // final user = Provider.of<MyUser?>(context);

    // if (user == null){
    //   return Authenticate();
    // } else {
    //   AuthService().displayValues();
    //   return Home();
    // }
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          print('Snapshot: $snapshot');
          if(snapshot.hasData) {
            print('Verified: ${snapshot.data!.emailVerified}');
            if(snapshot.data!.emailVerified) {
              return Home();
            } else {
              return Verify();
            }
          } else {
            return Authenticate();
          }
        }
      ),
    );
  }
}