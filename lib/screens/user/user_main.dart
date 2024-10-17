import 'package:flutter/material.dart';
import 'package:solace/screens/user/user_home.dart';
import 'package:solace/screens/user/user_history.dart';
import 'package:solace/screens/user/user_tracking.dart';
import 'package:solace/screens/user/user_profile.dart';
import 'package:solace/themes/colors.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({Key? key}) : super(key: key);

  @override
  _UserMainScreenState createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _selectedIndex = 0;

  // List of pages to navigate between
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    // Initialize the pages list here
    _pages.addAll([
      UserHomeScreen(
          navigateToHistory: navigateToHistory), // Pass the function here
      const UserHistoryScreen(),
      const UserTrackingScreen(),
      const UserProfileScreen(),
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
            iconPath: 'lib/assets/images/user/home.png',
            selectedIconPath: 'lib/assets/images/user/home_selected.png',
            label: 'Home',
          ),
          _buildBottomNavItem(
            index: 1,
            iconPath: 'lib/assets/images/user/history.png',
            selectedIconPath: 'lib/assets/images/user/history_selected.png',
            label: 'History',
          ),
          _buildBottomNavItem(
            index: 2,
            iconPath: 'lib/assets/images/user/tracking.png',
            selectedIconPath: 'lib/assets/images/user/tracking_selected.png',
            label: 'Tracking',
          ),
          _buildBottomNavItem(
            index: 3,
            iconPath: 'lib/assets/images/user/profile.png',
            selectedIconPath: 'lib/assets/images/user/profile_selected.png',
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
