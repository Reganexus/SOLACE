// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/admin/user_row.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  @override
  Widget build(BuildContext context) {

    final users = Provider.of<List<UserData>?>(context);

    if(users == null){
      print('No user list');
      return Text('List is null');
    } else if(users.isEmpty) {
      print('User list is empty');
      return Text('List is empty');
    } else {
      for(int i = 0; i < users.length; i++) {
        print('User $i: ${users[i].userRole == UserRole.admin}');
      }
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        return UserRow(user: users[index]);
      },
    );
  
  }
}