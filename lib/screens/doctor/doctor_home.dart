// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/doctor/doctor_dashboard.dart';
import 'package:solace/screens/doctor/doctor_tasks.dart';
import 'package:solace/screens/doctor/doctor_users.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/bottom_navbar.dart';
import 'package:solace/shared/widgets/notifications.dart';
import 'package:solace/shared/widgets/profile.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/shared/widgets/show_qr.dart';

class DoctorHome extends StatefulWidget {
  const DoctorHome({super.key});

  @override
  DoctorHomeState createState() => DoctorHomeState();
}

class DoctorHomeState extends State<DoctorHome> {
  int _currentIndex = 3;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DoctorDashboard(),
      DoctorUsers(),
      DoctorTasks(),
      Profile(),
    ];
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildLeftAppBar(BuildContext context) {
    final user = Provider.of<MyUser?>(context);
    return StreamBuilder<UserData?>(
      stream: DatabaseService(uid: user?.uid).userData,
      builder: (context, snapshot) {
        String firstName = 'User';
        String profileImageUrl = '';

        if (snapshot.hasData) {
          final userData = snapshot.data!;
          firstName = userData.firstName.split(' ')[0]; // Use first name
          profileImageUrl = userData.profileImageUrl; // Set profile image URL
        }

        return Row(
          children: [
            CircleAvatar(
              radius: 20.0,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : const AssetImage('lib/assets/images/shared/placeholder.png')
              as ImageProvider,
              onBackgroundImageError: (error, stackTrace) {
                print('Error loading image: $error');
              },
              child: profileImageUrl.isEmpty
                  ? const Icon(Icons.person,
                  color: Colors.grey) // Placeholder icon
                  : null,
            ),
            const SizedBox(width: 10.0),
            Text(
              'Hello, Dr. $firstName',
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRightAppBar(BuildContext context) {
    final user = Provider.of<MyUser?>(context); // Get the user using Provider.

    if (user == null) {
      return IconButton(
        icon: Image.asset(
          'lib/assets/images/shared/header/notification.png',
          height: 30,
        ),
        onPressed: () => _showNotifications(context),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return IconButton(
            icon: Image.asset(
              'lib/assets/images/shared/header/notification.png',
              height: 30,
            ),
            onPressed: () => _showNotifications(context),
          );
        }

        // Check if there are unread notifications
        List<dynamic> notifications = snapshot.data!['notifications'] ?? [];
        bool hasUnread = notifications.any((n) => n['read'] == false);

        return Stack(
          children: [
            IconButton(
              icon: Image.asset(
                'lib/assets/images/shared/header/notification.png',
                height: 30,
              ),
              onPressed: () => _showNotifications(context),
            ),
            if (hasUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final user = Provider.of<MyUser?>(context);

    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: StreamBuilder<UserData?>(
        stream: DatabaseService(uid: user?.uid).userData,
        builder: (context, snapshot) {
          String fullName = snapshot.hasData
              ? '${snapshot.data?.firstName ?? 'User'} ${snapshot.data?.middleName ?? ''} ${snapshot.data?.lastName ?? 'User'}'
              : 'User';

          return AppBar(
            backgroundColor: AppColors.white,
            scrolledUnderElevation: 0.0,
            automaticallyImplyLeading: false,
            elevation: 0.0,
            title: Padding(
              padding: const EdgeInsets.fromLTRB(15.0, 20.0, 15.0, 10.0),
              child: _currentIndex == 0
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLeftAppBar(context),
                        _buildRightAppBar(context),
                      ],
                    )
                  : _currentIndex == 3
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                            IconButton(
                              icon: Image.asset(
                                'lib/assets/images/shared/profile/qr.png',
                                height: 30,
                              ),
                              onPressed: () {
                                _showQrModal(
                                  context,
                                  fullName,
                                  user?.uid ?? '',
                                  user?.profileImageUrl ??
                                      '', // Make sure to pass the profileImageUrl
                                );
                              },
                            ),
                          ],
                        )
                      : Text(
                          _currentIndex == 1 ? 'Users' : 'Tasks',
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

  void _showNotifications(BuildContext context) {
    final user =
        Provider.of<MyUser?>(context, listen: false); // Add listen: false

    if (user == null) {
      // Handle case where user is not available (optional)
      return;
    }

    // Pass user.uid to NotificationList widget
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationList(
            userId: user.uid), // Pass userId to NotificationView
      ),
    );
  }

  // Function to show QR modal
  void _showQrModal(BuildContext context, String fullName, String uid,
      String profileImageUrl) {
    final imageUrl = profileImageUrl.isNotEmpty
        ? profileImageUrl
        : 'lib/assets/images/shared/placeholder.png';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShowQrPage(
          fullName: fullName,
          uid: uid,
          profileImageUrl: imageUrl, // Pass the profileImageUrl here
        ),
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
        role: 'Doctor',
      ),
    );
  }
}
