import 'package:flutter/material.dart';
import 'package:solace/models/my_user.dart';

class UserRow extends StatefulWidget {
  final UserData user;
  const UserRow({super.key, required this.user});

  @override
  UserRowState createState() => UserRowState();
}

class UserRowState extends State<UserRow> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        margin: EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 0.0),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 25.0,
                backgroundColor: widget.user.userRole == UserRole.admin
                    ? Colors.tealAccent
                    : Colors.purple[400],
              ),
              title: Text('${widget.user.lastName}, ${widget.user.firstName} ${widget.user.middleName}'),
              subtitle: Text(UserData.getUserRoleString(widget.user.userRole)),
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
            ),
            if (isExpanded) ..._buildRoleSpecificButtons(),
          ],
        ),
      ),
    );
  }

  // Build role-specific action buttons
  List<Widget> _buildRoleSpecificButtons() {
    List<Widget> buttons = [];

    // Doctor buttons
    if (widget.user.userRole == UserRole.doctor) {
      buttons.addAll([
        _buildButton('Assign as Admin', onPressed: () {
          // Handle "Assign as Admin" action
        }),
        _buildButton('Assign to Patients', onPressed: () {
          // Handle "Assign to Patients" action
        }),
      ]);
    }

    // Caregiver buttons
    else if (widget.user.userRole == UserRole.caregiver) {
      buttons.add(
        _buildButton('Assign to Patients', onPressed: () {
          // Handle "Assign to Patients" action
        }),
      );
    }

    // Patient buttons
    else if (widget.user.userRole == UserRole.patient) {
      buttons.addAll([
        _buildButton('Assign Doctors', onPressed: () {
          // Handle "Assign Doctors" action
        }),
        _buildButton('Assign Caregivers', onPressed: () {
          // Handle "Assign Caregivers" action
        }),
      ]);
    }

    return buttons;
  }

  // Helper to build individual buttons
  Widget _buildButton(String text, {required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}
