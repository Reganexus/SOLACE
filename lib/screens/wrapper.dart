import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/user.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/screens/user/user_home.dart';
import 'package:solace/screens/user/user_main.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {

    final user = Provider.of<MyUser?>(context);
    print("Current user: ${user}");

    // return Authenticate or Home widget
    if(user == null) {
      return Authenticate();
    } else {
      return UserMainScreen();
    }
  }
}