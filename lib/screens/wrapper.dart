import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/screens/home/home.dart';
import 'package:flutter/material.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the user from the provider (auth state)
    final user = Provider.of<MyUser?>(context);

    // If user is null, show the authentication page; otherwise, home page
    return user == null ? Authenticate() : Home();
  }
}
