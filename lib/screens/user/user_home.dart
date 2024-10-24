import 'package:flutter/material.dart';
import 'package:solace/screens/user/user_dashboard.dart';
import 'package:solace/screens/user/user_history.dart';
import 'package:solace/screens/user/user_profile.dart';
import 'package:solace/screens/user/user_tracking.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/shared/widgets/bottom_navbar.dart';

class UserHome extends StatefulWidget {
  UserHome({super.key});

  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final AuthService _auth = AuthService();

  // Current selected index for the navigation bar
  int _currentIndex = 0;

  // Screens for each tab in the bottom navigation
  final List<Widget> _screens = [
    UserDashboard(),  // Add your dashboard or main screen
    UserHistory(),
    UserTracking(),
    UserProfile(),  // User profile page]
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[100],
      appBar: AppBar(
        title: Text('Welcome User'),
        backgroundColor: Colors.purple[400],
        elevation: 0.0,
        actions: <Widget>[
          ElevatedButton.icon(
            icon: Icon(Icons.logout),
            label: Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[100],
            ),
            onPressed: () async {
              await _auth.signOut();
            },
          )
        ],
      ),
      body: _screens[_currentIndex],  // Display the current screen based on selected index
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        isAdmin: false,  // Indicate that this is the user home
      ),
    );
  }
}
