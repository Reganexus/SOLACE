import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/firestore_user.dart';
import 'package:solace/screens/admin/user_list.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';

class AdminHome extends StatelessWidget {
  AdminHome({super.key});

  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<FirestoreUser>?>.value(
      catchError: (_,__) => null,
      initialData: [],
      value: DatabaseService().users,
      child: Scaffold(
        backgroundColor: Colors.purple[100],
        appBar: AppBar(
          title: Text('Welcome Admin'),
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
        body: UserList(),
      ),
    );
  }
}