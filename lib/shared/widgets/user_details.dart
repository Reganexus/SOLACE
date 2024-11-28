import 'package:flutter/material.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/themes/colors.dart';

class UserDetailsDialog extends StatelessWidget {
  final UserData user;
  final VoidCallback? onEditRole; // Optional for specific contexts
  final VoidCallback? onDeleteUser; // Optional for specific contexts
  final VoidCallback? onAddContact; // Optional for doctor view
  final VoidCallback? onCall; // Optional for doctor view
  final bool isAdminView; // Flag to toggle context

  const UserDetailsDialog({
    super.key,
    required this.user,
    this.onEditRole,
    this.onDeleteUser,
    this.onAddContact,
    this.onCall,
    required this.isAdminView,
  });

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
          // User Name Header
          Center(
            child: Text(
              '${user.firstName} ${user.lastName}',
              style: const TextStyle(
                fontSize: 24,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
          ),
          const SizedBox(height: 20.0),

          // Phone Number with Icon
          Row(
            children: [
              const Icon(Icons.phone, color: AppColors.black),
              const SizedBox(width: 10.0),
              Text(
                user.phoneNumber,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15.0),

          // Address with Icon
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.black),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  user.address,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),

          // Action Buttons
          if (isAdminView)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onEditRole,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    backgroundColor: AppColors.neon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Edit Role',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10,),
                TextButton(
                  onPressed: onDeleteUser,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    backgroundColor: AppColors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Delete User',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onAddContact,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    backgroundColor: AppColors.neon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Add Contact',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10,),
                TextButton(
                  onPressed: onCall,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Call',
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
