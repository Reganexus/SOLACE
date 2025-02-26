// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/doctor/doctor_dashboard.dart';
import 'package:solace/screens/doctor/doctor_schedule.dart';
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
  int _currentIndex = 0;
  late final List<Widget> _screens;
  final GlobalKey<NotificationsListState> notificationsListKey = GlobalKey<NotificationsListState>();

  @override
  void initState() {
    super.initState();
    _screens = [
      DoctorDashboard(),
      NotificationList(
        userId: '', // Placeholder, updated in `didChangeDependencies`
        notificationsListKey: notificationsListKey,
      ),
      DoctorSchedule(),
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
          return const Row(
            children: [
              CircleAvatar(
                radius: 20.0,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              SizedBox(width: 10.0),
              Text(
                'Hello, User',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          );
        }

        final firstName = userData.firstName.split(' ')[0];
        final profileImageUrl = userData.profileImageUrl;

        return Row(
          children: [
            CircleAvatar(
              radius: 20.0,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : const AssetImage('lib/assets/images/shared/placeholder.png')
              as ImageProvider,
            ),
            const SizedBox(width: 10.0),
            Text(
              'Hello, $firstName',
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
                  GestureDetector(
                    onTap: () {
                      _showQrModal(
                        context,
                        fullName,
                        user?.uid ?? '',
                        user?.profileImageUrl ??
                            '', // Pass profileImageUrl
                      );
                    },
                    child: Image.asset(
                      'lib/assets/images/shared/profile/qr.png',
                      height: 30,
                    ),
                  ),
                ],
              )
                  : _currentIndex == 1
                  ? Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Show confirmation dialog before deleting all notifications
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.white,
                          title: const Text(
                            'Delete all Notifications?',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: AppColors.black,
                            ),
                          ),
                          content: const Text(
                            'This will permanently delete all notifications. Are you sure?',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.normal,
                              fontSize: 18,
                              color: AppColors.black,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 5),
                                backgroundColor: AppColors.neon,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Use the key to access the method in NotificationsListState
                                notificationsListKey.currentState
                                    ?.deleteAllNotifications();
                                Navigator.of(context)
                                    .pop(); // Close the dialog
                              },
                              style: TextButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 5),
                                backgroundColor: AppColors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Delete All',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.delete,
                      size: 30.0,
                    ),
                  ),
                ],
              )
                  : Text(
                'Schedule',
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
        context: context,
      ),
    );
  }
}
