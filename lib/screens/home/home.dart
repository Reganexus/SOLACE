import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/home/admin_home.dart';
import 'package:solace/screens/home/user_home.dart';
import 'package:solace/services/auth.dart';

class Home extends StatelessWidget {
  Home({super.key});

  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {

    final user = Provider.of<MyUser?>(context);
    print('Provided user id: $user');

    // return either UserHome or AdminHome
    if(user!.isAdmin) {
      return AdminHome();
    } else {
      return UserHome();
    }
  }
}