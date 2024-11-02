import 'package:flutter/material.dart';
import 'package:solace/screens/patient/patient_contacts.dart';
import 'package:solace/screens/patient/patient_dashboard.dart';
import 'package:solace/screens/patient/patient_history.dart';
import 'package:solace/screens/patient/patient_profile.dart';
import 'package:solace/screens/patient/patient_tracking.dart';
import 'package:solace/shared/widgets/bottom_navbar.dart';
import 'package:solace/themes/colors.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  PatientHomeState createState() => PatientHomeState();
}

class PatientHomeState extends State<PatientHome> {

  int _currentIndex = 3;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      PatientDashboard(
        navigateToHistory: _navigateToHistory,
      ),
      PatientHistory(),
      PatientTracking(),
      PatientContacts(),
      PatientProfile(),
    ];
  }

  void _navigateToHistory() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildLeftAppBar() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20.0,
          backgroundImage: AssetImage('lib/assets/images/shared/placeholder.png'),
        ),
        const SizedBox(width: 10.0),
        const Text(
          'Hello, User!',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

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

  PreferredSizeWidget _buildAppBar() {
    final appBar = AppBar(
      backgroundColor: AppColors.white,
      scrolledUnderElevation: 0.0,
      elevation: 0.0,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(15.0, 20.0, 15.0, 10.0),
        child: _currentIndex == 0
            ? Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLeftAppBar(),
            _buildRightAppBar(context),
          ],
        )
            : Text(
          _currentIndex == 1 ? 'History' :
          _currentIndex == 2 ? 'Tracking' :
          _currentIndex == 3 ? 'Contacts' :
          'Profile',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );

    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: appBar,
    );
  }

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
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

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
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
        role: 'Patient',
      ),
    );
  }
}
