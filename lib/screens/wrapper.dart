import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:solace/services/auth.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the user from the provider (auth state)
    final user = Provider.of<MyUser?>(context);

    return StreamProvider<MyUser?>.value(
      catchError: (_,__) => null,
      initialData: null,
      value: AuthService().user,
      child: user == null ? Authenticate() : Home(), // Conditionally render Authenticate or Home
  );
  }
}
