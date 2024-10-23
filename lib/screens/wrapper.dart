import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/screens/home/home.dart';
import 'package:flutter/material.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {

    final user = Provider.of<MyUser?>(context);
    print('Provided user id: $user');

    // return either Home or Authenticate widget
    if(user == null) {
      return Authenticate();
    } else {
      return Home();
    }
  }
}