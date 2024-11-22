// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';
// Import UserRole from here

class EditRoleDialog extends StatefulWidget {
  final UserData user;
  final UserRole currentRole; // Accept currentRole from the parent
  final VoidCallback onRoleUpdated;

  const EditRoleDialog({
    super.key,
    required this.user,
    required this.currentRole, // Accept currentRole from the parent
    required this.onRoleUpdated,
  });

  @override
  EditRoleDialogState createState() => EditRoleDialogState();
}

class EditRoleDialogState extends State<EditRoleDialog> {
  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole; // Pre-select the user's current role
  }

  void _saveRole() async {
    if (_selectedRole != null && _selectedRole != widget.user.userRole) {
      // Call your service to update the role in Firestore
      await DatabaseService().updateUserRole(widget.user.uid, _selectedRole!);
      widget
          .onRoleUpdated(); // Notify the parent widget that the role was updated
      Navigator.pop(context); // Close the dialog
    } else {
      Navigator.pop(
          context); // Close the dialog without making changes if no change occurred
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title for Edit Role Dialog
          Center(
            child: Text(
              'Edit Role',
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20.0),

          // Role Dropdown - Using DropdownButtonFormField
          DropdownButtonFormField<UserRole>(
            dropdownColor: AppColors.white,
            value: _selectedRole,
            onChanged: (UserRole? newValue) {
              setState(() {
                _selectedRole = newValue;
              });
            },
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppColors.black,
            ),
            style: TextStyle(
              fontSize: 16.0,
              color: AppColors.black,
            ),
            decoration: InputDecoration(
              labelText: 'User Role',
              filled: true,
              fillColor: AppColors.gray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.neon, width: 2),
              ),
              labelStyle: TextStyle(
                color: AppColors.black, // Change label color if invalid
              ),
            ),
            items: UserRole.values
                .map<DropdownMenuItem<UserRole>>((UserRole value) {
              return DropdownMenuItem<UserRole>(
                value: value,
                child: Text(value
                    .toString()
                    .split('.')
                    .last), // Display role as "admin", "caregiver", etc.
              );
            }).toList(),
            isExpanded: true,
          ),

          const SizedBox(height: 25.0),

          // Buttons: Save and Cancel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _saveRole,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  backgroundColor: AppColors.neon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context), // Cancel action
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  backgroundColor: AppColors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
