import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/firestore_user.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/admin/admin_home.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/screens/user/user_home.dart';
import 'package:solace/services/auth.dart';

class Home extends StatelessWidget {
  Home({super.key});

  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {

    final user = Provider.of<MyUser?>(context);
    print('Is user admin?: ${user?.isAdmin}');
    
    if(user == null){
      return Authenticate();
    } else {
      if(user.isAdmin) {
        print('ADMIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIN');
        return AdminHome();
      } else {
        print('USEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEER');
        return UserHome();
      }
    }
  }
}