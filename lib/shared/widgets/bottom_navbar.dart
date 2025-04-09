// ignore_for_file: unused_local_variable, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String role;
  final BuildContext context;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: _buildNavBarItems(context),
      selectedItemColor: AppColors.neon,
      unselectedItemColor: AppColors.black,
      selectedFontSize: 14,
      unselectedFontSize: 14,
      backgroundColor: AppColors.white,
    );
  }

  Future<DocumentSnapshot> getUserDocument(BuildContext context) async {
    final userId = Provider.of<MyUser?>(context, listen: false)?.uid;

    if (userId == null) {
      throw Exception("User ID is null");
    }

    try {
      // Initialize DatabaseService
      final db = DatabaseService();

      // Fetch user role
      final userRole = await db.fetchAndCacheUserRole(userId);

      if (userRole == null || userRole.isEmpty) {
        throw Exception("User role not found for user ID: $userId");
      }

      // Fetch user document
      final doc =
          await FirebaseFirestore.instance
              .collection(userRole)
              .doc(userId)
              .get();

      if (doc.exists) {
        return doc;
      } else {
        throw Exception("User document not found in the $userRole collection");
      }
    } catch (e) {
      // Log the error (if you have a logging mechanism) and rethrow
      print("Error fetching user document: $e");
      throw Exception("Failed to fetch user document: $e");
    }
  }

  List<BottomNavigationBarItem> _buildNavBarItems(BuildContext context) {
    final parentContext = context;

    switch (role) {
      case 'Admin':
        return [
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 0
                  ? 'lib/assets/images/admin/home_selected.png'
                  : 'lib/assets/images/admin/home.png',
              width: 26,
              height: 26,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 1
                  ? 'lib/assets/images/admin/profile_selected.png'
                  : 'lib/assets/images/admin/profile.png',
              width: 26,
              height: 26,
            ),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 2
                  ? 'lib/assets/images/admin/export_selected.png'
                  : 'lib/assets/images/admin/export.png',
              width: 26,
              height: 26,
            ),
            label: 'Logs',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 3
                  ? 'lib/assets/images/caregiver/profile_selected.png'
                  : 'lib/assets/images/caregiver/profile.png',
              width: 26,
              height: 26,
            ),
            label: 'Settings',
          ),
        ];
      case 'Caregiver':
        return [
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 0
                  ? 'lib/assets/images/caregiver/home_selected.png'
                  : 'lib/assets/images/caregiver/home.png',
              width: 26,
              height: 26,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: FutureBuilder<String?>(
              future: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  return null; // Return null if the user is not logged in
                }
                final userId = user.uid;

                DatabaseService db = DatabaseService();
                return await db.fetchAndCacheUserRole(
                  userId,
                ); // Fetch user role
              }(),
              builder: (context, userRoleSnapshot) {
                if (!userRoleSnapshot.hasData ||
                    userRoleSnapshot.data == null) {
                  // Show default icon while loading or if userRole is null
                  return Image.asset(
                    currentIndex == 1
                        ? 'lib/assets/images/caregiver/inbox_selected.png'
                        : 'lib/assets/images/caregiver/inbox.png',
                    width: 26,
                    height: 26,
                  );
                }

                final userRole = userRoleSnapshot.data!;
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  return Image.asset(
                    currentIndex == 1
                        ? 'lib/assets/images/caregiver/inbox_selected.png'
                        : 'lib/assets/images/caregiver/inbox.png',
                    width: 26,
                    height: 26,
                  );
                }

                // StreamBuilder for notifications
                return StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection(userRole)
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection(
                            'notifications',
                          ) // Access the subcollection
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      // Show default icon while loading notifications
                      return Image.asset(
                        currentIndex == 1
                            ? 'lib/assets/images/caregiver/inbox_selected.png'
                            : 'lib/assets/images/caregiver/inbox.png',
                        width: 26,
                        height: 26,
                      );
                    }

                    // Count unread notifications in the subcollection
                    final notifications = snapshot.data!.docs;
                    final int unreadCount =
                        notifications
                            .where((doc) => (doc['read'] ?? false) == false)
                            .length;

                    return Stack(
                      children: [
                        Image.asset(
                          currentIndex == 1
                              ? 'lib/assets/images/caregiver/inbox_selected.png'
                              : 'lib/assets/images/caregiver/inbox.png',
                          width: 26,
                          height: 26,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
            label: 'Inbox',
          ),

          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 2
                  ? 'lib/assets/images/caregiver/schedule_selected.png'
                  : 'lib/assets/images/caregiver/schedule.png',
              width: 26,
              height: 26,
            ),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              currentIndex == 3
                  ? 'lib/assets/images/caregiver/profile_selected.png'
                  : 'lib/assets/images/caregiver/profile.png',
              width: 26,
              height: 26,
            ),
            label: 'Profile',
          ),
        ];
      default:
        throw Exception();
    }
  }
}
