import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/admin/admin_dashboard.dart';
import 'package:solace/screens/admin/admin_settings.dart';
import 'package:solace/screens/admin/admin_users.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/bottom_navbar.dart';
import 'package:solace/themes/colors.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  AdminHomeState createState() => AdminHomeState();
}

class AdminHomeState extends State<AdminHome> {
  final GlobalKey<AdminUsersState> _adminUsersKey = GlobalKey<AdminUsersState>();
  int _currentIndex = 0; // Initialize with a valid index (e.g., 0)
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screens = [
      AdminDashboard(),
      AdminUsers(key: _adminUsersKey),
      AdminSettings(),
    ];
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  PreferredSizeWidget _buildAppBar() {
    final user = Provider.of<MyUser?>(context);

    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: StreamBuilder<UserData?>(
        stream: DatabaseService(uid: user?.uid).userData,
        builder: (context, snapshot) {
          return AppBar(
            backgroundColor: AppColors.white,
            scrolledUnderElevation: 0.0,
            automaticallyImplyLeading: false,
            elevation: 0.0,
            title: Padding(
              padding: const EdgeInsets.fromLTRB(15.0, 20.0, 15.0, 10.0),
              child: _currentIndex == 0
                  ? const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              )
                  : _currentIndex == 1
                  ? Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Users List',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Access the AdminUsersState to toggle sort order
                      _adminUsersKey.currentState?.toggleSortOrder();
                    },
                    child: Image.asset(
                      'lib/assets/images/shared/navigation/ascending.png', // Adjust based on _isAscending in AdminUsers
                      height: 24,
                      width: 24,
                    ),
                  ),

                ],
              )
                  : Text(
                'Export',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(),
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
