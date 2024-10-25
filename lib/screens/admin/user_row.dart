import 'package:flutter/material.dart';
import 'package:solace/models/my_user.dart';

class UserRow extends StatelessWidget {
  final UserData user;
  const UserRow({ super.key, required this.user });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        margin: EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 0.0),
        child: ListTile(
          leading: CircleAvatar(
            radius: 25.0,
            backgroundColor: user.isAdmin ? Colors.tealAccent : Colors.purple[400],
          ),
          title: Text('${user.lastName}, ${user.firstName} ${user.middleName}'),
          subtitle: Text(user.isAdmin ? 'Admin' : 'User'),
        ),
      ),
    );
  }
}