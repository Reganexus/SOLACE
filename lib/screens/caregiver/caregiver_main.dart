import 'package:flutter/material.dart';
import 'package:solace/screens/caregiver/caregiver_home.dart';
import 'package:solace/screens/caregiver/caregiver_patients.dart';
import 'package:solace/screens/caregiver/caregiver_tracking.dart';
import 'package:solace/screens/caregiver/caregiver_profile.dart';
import 'package:solace/themes/colors.dart';

class CaregiverMainScreen extends StatefulWidget {
  const CaregiverMainScreen({super.key});

  @override
  CaregiverMainScreenState createState() => CaregiverMainScreenState();
}

class CaregiverMainScreenState extends State<CaregiverMainScreen> {
  int _selectedIndex = 0;

  // List of pages to navigate between
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    // Initialize the pages list here
    _pages.addAll([
      const CaregiverHomeScreen(), // Pass the function here
      const CaregiverPatientsScreen(),
      const CaregiverTrackingScreen(),
      const CaregiverProfileScreen(),
    ]);
  }

  // This method handles the bottom navigation bar tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Method to navigate to History screen
  void navigateToHistory() {
    setState(() {
      _selectedIndex = 1; // Index for History
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.white, // Set body background color to white
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Labels always visible
        currentIndex: _selectedIndex, // Highlight selected item
        onTap: _onItemTapped, // Update the index when user taps a button
        backgroundColor:
            Colors.white, // Set bottom navigation bar background to white
        items: [
          _buildBottomNavItem(
            index: 0,
            iconPath: 'lib/assets/images/caregiver/home.png',
            selectedIconPath: 'lib/assets/images/caregiver/home_selected.png',
            label: 'Home',
          ),
          _buildBottomNavItem(
            index: 1,
            iconPath: 'lib/assets/images/caregiver/patients.png',
            selectedIconPath: 'lib/assets/images/caregiver/patients_selected.png',
            label: 'Patients',
          ),
          _buildBottomNavItem(
            index: 2,
            iconPath: 'lib/assets/images/caregiver/tracking.png',
            selectedIconPath: 'lib/assets/images/caregiver/tracking_selected.png',
            label: 'Tracking',
          ),
          _buildBottomNavItem(
            index: 3,
            iconPath: 'lib/assets/images/caregiver/profile.png',
            selectedIconPath: 'lib/assets/images/caregiver/profile_selected.png',
            label: 'Profile',
          ),
        ],
        selectedItemColor: AppColors.neon, // Color when selected
        unselectedItemColor: AppColors.black, // Color when not selected
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem({
    required int index,
    required String iconPath,
    required String selectedIconPath,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 3.0), // Adjust vertical padding here
        child: Image.asset(
          _selectedIndex == index ? selectedIconPath : iconPath,
          height: 30,
        ),
      ),
      label: label,
    );
  }
}
