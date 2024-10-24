import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/firestore_user.dart';
import 'package:solace/screens/admin/user_row.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  @override
  Widget build(BuildContext context) {

    final users = Provider.of<List<FirestoreUser>?>(context);

    if(users == null){
      print('No list');
    } else if(users.isEmpty) {
      print('List is empty');
    } else {
      for(int i = 0; i < users.length; i++) {
        print('User $i: ${users[i].isAdmin}');
      };
    }

    return ListView.builder(
      itemCount: users!.length,
      itemBuilder: (context, index) {
        return UserRow(user: users[index]);
      },
    );
  
  }
}