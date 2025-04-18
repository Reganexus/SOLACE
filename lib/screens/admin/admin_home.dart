// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/admin/admin_dashboard.dart';
import 'package:solace/screens/admin/admin_logs.dart';
import 'package:solace/screens/admin/admin_settings.dart';
import 'package:solace/screens/admin/admin_users.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/bottom_navbar.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  AdminHomeState createState() => AdminHomeState();
}

class AdminHomeState extends State<AdminHome> {
  DatabaseService db = DatabaseService();
  int _currentIndex = 0;
  late final List<Widget> _screens;
  late final String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _screens = [
      AdminDashboard(),
      AdminUsers(),
      AdminLogs(currentUserId: currentUserId),
      AdminSettings(),
    ];
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  AppBar buildAppBar() {
    final user = Provider.of<MyUser?>(context);

    return AppBar(
      backgroundColor: AppColors.white,
      scrolledUnderElevation: 0.0,
      automaticallyImplyLeading: false,
      elevation: 0.0,
      title: StreamBuilder<UserData?>(
        stream: DatabaseService(uid: user?.uid).userData,
        builder: (context, snapshot) {
          return _currentIndex == 0
              ? Text('Dashboard', style: Textstyle.subheader)
              : _currentIndex == 1
              ? Text('Users', style: Textstyle.subheader)
              : _currentIndex == 2
              ? Text('Logs', style: Textstyle.subheader)
              : Row(
                children: [
                  Expanded(child: Text('Settings', style: Textstyle.subheader)),
                  const SizedBox(width: 8),
                  buildLogOut(),
                ],
              );
        },
      ),
    );
  }

  Widget buildLogOut() {
    return GestureDetector(
      onTap: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Log Out', style: Textstyle.heading),
                backgroundColor: AppColors.white,
                contentPadding: const EdgeInsets.all(20),
                content: Text(
                  'Are you sure you want to log out?',
                  style: Textstyle.body,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: Buttonstyle.buttonNeon,
                    child: Text('Cancel', style: Textstyle.smallButton),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: Buttonstyle.buttonRed,
                    child: Text('Log Out', style: Textstyle.smallButton),
                  ),
                ],
              ),
        );

        if (shouldLogout ?? false) {
          await AuthService().signOut();

          // Check if the widget is still mounted before navigating
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Authenticate()),
              (route) => false, // Remove all previous routes
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout_rounded, size: 24.0, color: AppColors.red),
            const SizedBox(width: 8),
            const Text(
              'Log out',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: buildAppBar(),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        role: 'Admin',
        context: context,
      ),
    );
  }
}
