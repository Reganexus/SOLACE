import 'package:flutter/material.dart';
import 'package:solace/services/auth.dart';

class UserHome extends StatelessWidget {
  UserHome({super.key});

  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[100],
      appBar: AppBar(
        title: Text('Welcome User'),
        backgroundColor: Colors.purple[400],
        elevation: 0.0,
        actions: <Widget>[
          ElevatedButton.icon(
            icon: Icon(Icons.logout),
            label: Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[100],
            ),
            onPressed: () async {
              await _auth.signOut();
            },
          )
        ],
      ),

    );
  }
}