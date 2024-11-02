// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/admin/user_row.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  UserRole? selectedRole;
  List<UserData>? filteredUsers;

  @override
  Widget build(BuildContext context) {
    final users = Provider.of<List<UserData>?>(context) ?? [];
    _updateFilteredUsers(users);

    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                'Role:',
                style: TextStyle(fontSize: 16),
              ),
            ),
            DropdownButton<UserRole?>(
              value: selectedRole,
              hint: Text("Select User Role"),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text("All"),
                ),
                DropdownMenuItem(
                  value: UserRole.admin,
                  child: Text("Admins"),
                ),
                DropdownMenuItem(
                  value: UserRole.doctor,
                  child: Text("Doctors"),
                ),
                DropdownMenuItem(
                  value: UserRole.caregiver,
                  child: Text("Caregivers"),
                ),
                DropdownMenuItem(
                  value: UserRole.family,
                  child: Text("Family"),
                ),
                DropdownMenuItem(
                  value: UserRole.patient,
                  child: Text("Patients"),
                ),
              ],
              onChanged: (UserRole? newValue) {
                setState(() {
                  selectedRole = newValue;
                  _updateFilteredUsers(users);
                });
              },
            ),
          ],
        ),
        Expanded(
          child: filteredUsers == null
              ? Text('Loading users...')
              : filteredUsers!.isEmpty
                  ? Text('No users for this role')
                  : ListView.builder(
                      itemCount: filteredUsers!.length,
                      itemBuilder: (context, index) {
                        return UserRow(user: filteredUsers![index]);
                      },
                    ),
        ),
      ],
    );
  }

  void _updateFilteredUsers(List<UserData> users) {
    // Filter and sort the users based on the selected role
    filteredUsers = users.where((user) {
      return selectedRole == null || user.userRole == selectedRole;
    }).toList();

    // Sort the list alphabetically by last name, then first name
    filteredUsers?.sort((a, b) {
      int lastNameComparison = (a.lastName ?? '').compareTo(b.lastName ?? '');
      if (lastNameComparison != 0) {
        return lastNameComparison;
      } else {
        return (a.firstName ?? '').compareTo(b.firstName ?? '');
      }
    });
  }
}
