import 'package:flutter/material.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/themes/colors.dart';

class UserDetailsDialog extends StatelessWidget {
  final UserData user;
  final VoidCallback? onAddContact;
  final VoidCallback? onCall;

  const UserDetailsDialog({
    super.key,
    required this.user,
    this.onAddContact,
    this.onCall,
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

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onAddContact,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
              SizedBox(
                width: 10,
              ),
              TextButton(
                onPressed: onCall,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
