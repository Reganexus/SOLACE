import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String role; // Add a role parameter for differentiating user roles

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: _buildNavBarItems(),
      selectedItemColor: AppColors.neon,   // Color for selected icon and text
      unselectedItemColor: AppColors.black, // Color for unselected icon and text
      backgroundColor: AppColors.white,     // Background color of the navigation bar
    );
  }

  List<BottomNavigationBarItem> _buildNavBarItems() {
    switch (role) {
      case 'Admin':
        return [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
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
            label: 'Patients',
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
      default: // Patient by default
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
            icon: Image.asset(
              currentIndex == 1
                  ? 'lib/assets/images/user/history_selected.png'
                  : 'lib/assets/images/user/history.png',
              width: 30,
              height: 30,
            ),
            label: 'History',
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
