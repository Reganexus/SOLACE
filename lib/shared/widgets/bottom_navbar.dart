import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/themes/colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String role; // Add a role parameter for differentiating user roles
  final BuildContext context;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: _buildNavBarItems(context),
      selectedItemColor: AppColors.neon,   // Color for selected icon and text
      unselectedItemColor: AppColors.black, // Color for unselected icon and text
      backgroundColor: AppColors.white,     // Background color of the navigation bar
    );
  }

  List<BottomNavigationBarItem> _buildNavBarItems(BuildContext context) {
    final parentContext = context;

    switch (role) {
      case 'Admin':
        return [
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 0
                  ? 'lib/assets/images/admin/home_selected.png'
                  : 'lib/assets/images/admin/home.png',
              width: 30,
              height: 30,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 1
                  ? 'lib/assets/images/admin/users_selected.png'
                  : 'lib/assets/images/admin/users.png',
              width: 30,
              height: 30,
            ),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 2
                  ? 'lib/assets/images/admin/profile_selected.png'
                  : 'lib/assets/images/admin/profile.png',
              width: 30,
              height: 30,
            ),
            label: 'Profile',
          ),
        ];
      case 'Doctor':
        return [
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 0
                  ? 'lib/assets/images/doctor/home_selected.png'
                  : 'lib/assets/images/doctor/home.png',
              width: 30,
              height: 30,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 1
                  ? 'lib/assets/images/doctor/users_selected.png'
                  : 'lib/assets/images/doctor/users.png',
              width: 30,
              height: 30,
            ),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 2
                  ? 'lib/assets/images/doctor/tasks_selected.png'
                  : 'lib/assets/images/doctor/tasks.png',
              width: 30,
              height: 30,
            ),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 3
                  ? 'lib/assets/images/doctor/profile_selected.png'
                  : 'lib/assets/images/doctor/profile.png',
              width: 30,
              height: 30,
            ),
            label: 'Profile',
          ),
        ];
      case 'Caregiver':
        return [
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 0
                  ? 'lib/assets/images/caregiver/home_selected.png'
                  : 'lib/assets/images/caregiver/home.png',
              width: 30,
              height: 30,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 1
                  ? 'lib/assets/images/caregiver/patients_selected.png'
                  : 'lib/assets/images/caregiver/patients.png',
              width: 30,
              height: 30,
            ),
            label: 'Intervention',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 2
                  ? 'lib/assets/images/caregiver/tracking_selected.png'
                  : 'lib/assets/images/caregiver/tracking.png',
              width: 30,
              height: 30,
            ),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 3
                  ? 'lib/assets/images/caregiver/profile_selected.png'
                  : 'lib/assets/images/caregiver/profile.png',
              width: 30,
              height: 30,
            ),
            label: 'Profile',
          ),
        ];
      default:
        return [
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 0
                  ? 'lib/assets/images/user/home_selected.png'
                  : 'lib/assets/images/user/home.png',
              width: 30,
              height: 30,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(Provider.of<MyUser?>(parentContext)?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return Image.asset(
                    currentIndex == 1
                        ? 'lib/assets/images/user/inbox_selected.png'
                        : 'lib/assets/images/user/inbox.png',
                    width: 30,
                    height: 30,
                  );
                }

                // Get notifications and check for unread ones
                List<dynamic> notifications = snapshot.data!['notifications'] ?? [];
                int unreadCount =
                    notifications.where((n) => n['read'] == false).length;

                return Stack(
                  children: [
                    Image.asset(
                      currentIndex == 1
                          ? 'lib/assets/images/user/inbox_selected.png'
                          : 'lib/assets/images/user/inbox.png',
                      width: 30,
                      height: 30,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 2
                  ? 'lib/assets/images/user/tracking_selected.png'
                  : 'lib/assets/images/user/tracking.png',
              width: 30,
              height: 30,
            ),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 3
                  ? 'lib/assets/images/user/profile_selected.png'
                  : 'lib/assets/images/user/profile.png',
              width: 30,
              height: 30,
            ),
            label: 'Profile',
          ),
        ];

    }
  }
}
