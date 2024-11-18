// delete_user_dialog.dart

// delete_user_dialog.dart
import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';

class DeleteUserDialog extends StatelessWidget {
  final String userName; // The name of the user being deleted
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const DeleteUserDialog({
    super.key,
    required this.userName,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      title: Text(
        'Confirm Deletion',
        style: const TextStyle(
          fontSize: 24,
          fontFamily: 'Outfit',
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
      ),
      content: Text(
        'Are you sure you want to delete $userName from the database?',
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Inter',
          fontWeight: FontWeight.normal,
          color: AppColors.black,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: onCancel, // Trigger cancel action
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            backgroundColor: AppColors.neon,
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
        TextButton(
          onPressed: onConfirm, // Trigger confirm action
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            backgroundColor: AppColors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
