import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/user_data_form.dart';

class UserProfile extends StatelessWidget {
  UserProfile({super.key});

  @override
  Widget build(BuildContext context) {

    final user = Provider.of<MyUser?>(context);

    return Scaffold(
      backgroundColor: Colors.purple[100],
      body: StreamBuilder<UserData>(
        stream: DatabaseService(uid: user?.uid).userData,
        builder: (context, snapshot) {
          print('Snapshot: $snapshot');
          if(snapshot.hasData) {
            UserData? userData = snapshot.data;
            return UserDataForm(isSignUp: false, userData: userData, onButtonPressed: () {});
          } else {
            return Center(child: Text('Loading...'));
          }
        }
      ),
    );
  }
}