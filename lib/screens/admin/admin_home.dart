import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/firestore_user.dart';
import 'package:solace/screens/admin/admin_dashboard.dart';
import 'package:solace/screens/admin/admin_settings.dart';
import 'package:solace/screens/admin/user_list.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/bottom_navbar.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final AuthService _auth = AuthService();
  
  // Current selected index for the navigation bar
  int _currentIndex = 0;

  // Screens for each tab in the bottom navigation
  final List<Widget> _screens = [
    UserList(),  // Replace this with your user list screen
    AdminDashboard(),  // Add your own dashboard screen
    AdminSettings()  // Add your settings screen
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<FirestoreUser>?>.value(
      catchError: (_,__) => null,
      initialData: [],
      value: DatabaseService().users,
      child: Scaffold(
        backgroundColor: Colors.purple[100],
        appBar: AppBar(
          title: Text('Welcome Admin'),
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
        body: _screens[_currentIndex],  // Display the current screen based on the selected index
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          isAdmin: true,  // Indicate that this is the admin home
        ),
      ),
    );
  }
}
