// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/screens/caregiver/caregiver_dashboard.dart';
import 'package:solace/screens/caregiver/caregiver_schedule.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/bottom_navbar.dart';
import 'package:solace/shared/widgets/help_page.dart';
import 'package:solace/shared/widgets/notifications.dart';
import 'package:solace/shared/widgets/profile.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class CaregiverHome extends StatefulWidget {
  const CaregiverHome({super.key});

  @override
  CaregiverHomeState createState() => CaregiverHomeState();
}

class CaregiverHomeState extends State<CaregiverHome> {
  DatabaseService db = DatabaseService();
  int _currentIndex = 0;
  late final List<Widget> _screens;
  late final String currentUserId;
  final GlobalKey<NotificationsListState> notificationsListKey =
      GlobalKey<NotificationsListState>();

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _screens = [
      CaregiverDashboard(),
      NotificationList(
        userId: '', // Placeholder, updated in `didChangeDependencies`
        notificationsListKey: notificationsListKey,
      ),
      CaregiverSchedule(),
      Profile(),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get userId from Provider
    final userId = Provider.of<MyUser?>(context)?.uid ?? '';

    // Update only the NotificationList widget with userId
    _screens[1] = NotificationList(
      userId: userId,
      notificationsListKey: notificationsListKey,
    );
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  UserData? _cachedUserData;

  Widget _buildLeftAppBar(BuildContext context) {
    final user = Provider.of<MyUser?>(context);
    return StreamBuilder<UserData?>(
      stream: DatabaseService(uid: user?.uid).userData,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _cachedUserData = snapshot.data; // Cache the data
        }

        final userData = _cachedUserData;
        if (userData == null) {
          return Row(
            children: [
              const CircleAvatar(
                radius: 20.0,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10.0),
              Text('Hello, User', style: Textstyle.body),
            ],
          );
        }

        final firstName = userData.firstName.split(' ')[0];
        final profileImageUrl = userData.profileImageUrl;

        return Row(
          children: [
            CircleAvatar(
              radius: 16.0,
              backgroundImage:
                  profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : const AssetImage(
                            'lib/assets/images/shared/placeholder.png',
                          )
                          as ImageProvider,
            ),
            const SizedBox(width: 10.0),
            Text(
              'Hello, $firstName',
              style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
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
          if (_currentIndex == 0) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_buildLeftAppBar(context)],
            );
          } else if (_currentIndex == 3) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Profile', style: Textstyle.subheader)),
                Row(
                  children: [
                    buildHelp(),
                    const SizedBox(width: 18),
                    buildLogOut(),
                  ],
                ),
              ],
            );
          } else if (_currentIndex == 1) {
            return Row(
              children: [
                Expanded(
                  child: Text('Notifications', style: Textstyle.subheader),
                ),
                buildDeleteNotifications(),
              ],
            );
          } else {
            return Text('Schedule', style: Textstyle.subheader);
          }
        },
      ),
    );
  }

  Widget buildDeleteNotifications() {
    return FutureBuilder<String?>(
      future: db.fetchAndCacheUserRole(currentUserId), // Fetch userRole
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Icon(Icons.delete, size: 24.0);
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          //     debugPrint('Error fetching userRole: ${snapshot.error}');
          return const Icon(Icons.delete, size: 24.0);
        }

        final userRole = snapshot.data!;

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection(userRole)
                  .doc(currentUserId)
                  .collection('notifications')
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Icon(Icons.delete, size: 24.0);
            }

            if (snapshot.hasError) {
              //     debugPrint('Error fetching notifications: ${snapshot.error}');
              return const Icon(Icons.error, size: 24.0);
            }

            final notificationCount = snapshot.data?.docs.length ?? 0;

            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        backgroundColor: AppColors.white,
                        title: Text(
                          notificationCount > 0
                              ? 'Delete all $notificationCount Notifications?'
                              : 'No Notifications to Delete',
                          style: Textstyle.subheader,
                        ),
                        content: Text(
                          notificationCount > 0
                              ? 'This will permanently delete all $notificationCount notifications. Are you sure?'
                              : 'There are no notifications to delete.',
                          style: Textstyle.body,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: Buttonstyle.buttonNeon,
                            child: Text(
                              notificationCount > 0 ? 'Cancel' : 'Close',
                              style: Textstyle.smallButton,
                            ),
                          ),
                          if (notificationCount > 0)
                            TextButton(
                              onPressed: () {
                                notificationsListKey.currentState
                                    ?.deleteAllNotifications();
                                Navigator.of(context).pop();
                              },
                              style: Buttonstyle.buttonRed,
                              child: Text(
                                'Delete All',
                                style: Textstyle.smallButton,
                              ),
                            ),
                        ],
                      ),
                );
              },
              child: Row(
                children: [
                  Icon(Icons.delete, size: 24.0, color: AppColors.black),
                  SizedBox(width: 5), // Space between icon and text
                  Text("Clear", style: TextStyle(fontSize: 14, color: AppColors.black)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildHelp() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HelpPage()),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline_rounded, size: 24.0),
          const SizedBox(width: 4),
          const Text(
            'Support',
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.logout_rounded, size: 24.0, color: AppColors.red),
          const SizedBox(width: 4),
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
        role: 'Caregiver',
        context: context,
      ),
    );
  }
}
