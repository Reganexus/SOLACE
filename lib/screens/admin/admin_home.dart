import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/admin/admin_dashboard.dart';
import 'package:solace/screens/admin/admin_settings.dart';
import 'package:solace/screens/admin/admin_users.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/bottom_navbar.dart';
import 'package:solace/shared/widgets/notifications.dart';
import 'package:solace/shared/widgets/show_qr.dart';
import 'package:solace/themes/colors.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  AdminHomeState createState() => AdminHomeState();
}

class AdminHomeState extends State<AdminHome> {
  final GlobalKey<NotificationsListState> notificationsListKey =
      GlobalKey<NotificationsListState>();
  int _currentIndex = 0; // Initialize with a valid index (e.g., 0)
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize _screens here, where context and Provider are available
    final userId = Provider.of<MyUser?>(context)?.uid ?? '';
    _screens = [
      AdminDashboard(),
      NotificationList(
        userId: userId,
        notificationsListKey: notificationsListKey, // Pass the key
      ),
      AdminUsers(),
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
                  ? const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
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
                        user?.profileImageUrl ?? '', // Pass profileImageUrl
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 5),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 5),
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
                _currentIndex == 2 ? 'Tracking' : 'Profile',
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
        role: 'Admin',
        context: context,
      ),
    );
  }
}
