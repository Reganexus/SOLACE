import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/user/user_dashboard.dart';
import 'package:solace/screens/user/user_history.dart';
import 'package:solace/screens/user/user_profile.dart';
import 'package:solace/screens/user/user_tracking.dart';
import 'package:solace/shared/widgets/bottom_navbar.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/database.dart'; // Import your database service

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  UserHomeState createState() => UserHomeState();
}

class UserHomeState extends State<UserHome> {
  // Current selected index for the navigation bar
  int _currentIndex = 0;

  // Screens for each tab in the bottom navigation
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      UserDashboard(
        navigateToHistory: _navigateToHistory, // Pass the callback here
      ),
      UserHistory(),
      UserTracking(),
      UserProfile(),
    ];
  }

  void _navigateToHistory() {
    setState(() {
      _currentIndex = 1; // Update index to show History screen
    });
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Build AppBar based on the selected index
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      scrolledUnderElevation: 0.0,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(15.0, 20.0, 15.0, 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLeftAppBar(),
            _buildRightAppBar(context),
          ],
        ),
      ),
    );
  }

  // Left side of AppBar
  Widget _buildLeftAppBar() {
    final userData = Provider.of<UserData?>(context); // Get user data from provider
    final firstName = userData?.firstName ?? 'User'; // Use default if first name is null

    return Row(
      children: [
        const CircleAvatar(
          radius: 20.0,
          backgroundImage: AssetImage('lib/assets/images/shared/placeholder.png'),
        ),
        const SizedBox(width: 10.0),
        Text(
          'Welcome, $firstName!',
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  // Right side of AppBar
  Widget _buildRightAppBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Image.asset(
            'lib/assets/images/shared/header/message.png',
            height: 30,
          ),
          onPressed: () => _showMessages(context),
        ),
        const SizedBox(width: 10.0),
        IconButton(
          icon: Image.asset(
            'lib/assets/images/shared/header/notification.png',
            height: 30,
          ),
          onPressed: () => _showNotifications(context),
        ),
      ],
    );
  }

  // Function to show notifications dialog
  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notifications'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Notification 1: System update available.'),
                Text('Notification 2: New message received.'),
                Text('Notification 3: Your profile has been updated.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Function to show messages dialog
  void _showMessages(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Messages'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Message 1: Welcome to Solace!'),
                Text('Message 2: Don’t forget to update your profile.'),
                Text('Message 3: Your password has been changed.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get user data from the provider
    final userData = Provider.of<UserData?>(context);

    return StreamProvider<UserData?>.value(
      value: userData != null
          ? DatabaseService(uid: userData.uid).userData
          : Stream.value(null), // Provide a default stream if userData is null
      initialData: null,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: _buildAppBar(),
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          role: 'Patient',
        ),
      ),
    );
  }
}
