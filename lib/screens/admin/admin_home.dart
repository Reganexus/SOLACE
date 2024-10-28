import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/admin/admin_dashboard.dart';
import 'package:solace/screens/admin/admin_settings.dart';
import 'package:solace/screens/admin/user_list.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/bottom_navbar.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  AdminHomeState createState() => AdminHomeState();
}

class AdminHomeState extends State<AdminHome> {
  final AuthService _auth = AuthService();

  // Current selected index for the navigation bar
  int _currentIndex = 0;

  // Screens for each tab in the bottom navigation
  final List<Widget> _screens = [
    UserList(),
    AdminDashboard(),
    AdminSettings(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<UserData>>.value(
      initialData: [],
      value: DatabaseService().users,
      child: Scaffold(
        backgroundColor: Colors.purple[100],
        appBar: AppBar(
          title: const Text('Welcome Admin'),
          backgroundColor: Colors.purple[400],
          elevation: 0.0,
          actions: <Widget>[
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[100],
              ),
              onPressed: () async {
                await _auth.signOut();
              },
            ),
          ],
        ),
        body: _screens[_currentIndex], // Display the current screen based on the selected index
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          role: 'Admin', // Specify role for admin
        ),
      ),
    );
  }
}
