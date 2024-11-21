// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/themes/colors.dart';

class NotificationList extends StatelessWidget {
  final String userId;

  const NotificationList({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: NotificationsList(userId: userId),
        ),
      ),
    );
  }
}

class NotificationsList extends StatefulWidget {
  final String userId;

  const NotificationsList({super.key, required this.userId});

  @override
  NotificationsListState createState() => NotificationsListState();
}

class NotificationsListState extends State<NotificationsList> {
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (snapshot.exists) {
        final notificationsData = snapshot.data()?['notifications'] ?? [];

        // Convert notifications
        final loadedNotifications = notificationsData.map((notification) {
          final timestamp = notification['timestamp'];
          DateTime? convertedTimestamp;

          if (timestamp is Timestamp) {
            convertedTimestamp = timestamp.toDate(); // Convert to DateTime
          } else if (timestamp is DateTime) {
            convertedTimestamp = timestamp; // Already DateTime
          }

          return {
            'message': notification['message'] ?? 'No message available',
            'notificationId': notification['notificationId'] ?? '',
            'timestamp': convertedTimestamp,
            'type': notification['type'] ?? 'unknown',
            'read': notification['read'] ?? false,
          };
        }).toList();

        // Sort notifications by timestamp in descending order (newest first)
        loadedNotifications.sort((a, b) {
          final aTimestamp = a['timestamp'] as DateTime?;
          final bTimestamp = b['timestamp'] as DateTime?;
          if (aTimestamp == null || bTimestamp == null) return 0;
          return bTimestamp.compareTo(aTimestamp); // Newest first
        });

        setState(() {
          notifications = List<Map<String, dynamic>>.from(loadedNotifications);
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(
      String userId, Map<String, dynamic> notification) async {
    final notificationId =
        notification['notificationId']; // Use the notificationId

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Retrieve the current notifications array
      final docSnapshot = await userRef.get();
      final notificationsData = docSnapshot.data()?['notifications'] ?? [];

      // Update the notification that matches the notificationId
      final updatedNotifications =
          notificationsData.map((existingNotification) {
        if (existingNotification['notificationId'] == notificationId) {
          return {
            ...existingNotification, // Spread the existing notification data
            'read': true, // Only update the 'read' flag
          };
        }
        return existingNotification;
      }).toList();

      // Update the notifications array in Firestore with the updated notifications
      await userRef.update({
        'notifications': updatedNotifications,
      });

      // Update the local state to reflect the change
      setState(() {
        final index = notifications
            .indexWhere((n) => n['notificationId'] == notificationId);
        if (index != -1) {
          notifications[index]['read'] =
              true; // Update the local state to remove the badge
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> deleteNotification(
      BuildContext context, String notificationId) async {
    final user =
        Provider.of<MyUser?>(context, listen: false); // Get the current user
    if (user == null) return;

    try {
      // Get the user document reference
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Fetch the current notifications
      final userDocSnapshot = await userDocRef.get();

      if (!userDocSnapshot.exists) {
        print('User document does not exist!');
        return;
      }

      // Cast notifications to List<Map<String, dynamic>>
      var notifications = List<Map<String, dynamic>>.from(
          userDocSnapshot.data()?['notifications'] ?? []);

      // Find the index of the notification by notificationId
      final notificationIndex = notifications
          .indexWhere((n) => n['notificationId'] == notificationId);

      if (notificationIndex != -1) {
        // Remove the notification from the list
        notifications.removeAt(notificationIndex);

        // Update the notifications field in Firestore (this will remove the notification)
        await userDocRef.update({
          'notifications':
              notifications, // Update notifications array without the deleted notification
        });

        // Update the local notifications list by calling setState()
        setState(() {
          this.notifications = notifications; // Refresh the local state
        });

        print("Notification successfully deleted");
      } else {
        print('Notification not found');
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return notifications.isEmpty
        ? Center(
            child: Text(
              'No notifications yet',
              style: TextStyle(fontSize: 18, color: AppColors.black),
            ),
          )
        : Column(
            children: notifications.map((notification) {
              final timestampRaw = notification['timestamp'];
              final DateTime? timestamp = timestampRaw is Timestamp
                  ? timestampRaw.toDate() // Convert Timestamp to DateTime
                  : timestampRaw as DateTime?; // Use as-is if already DateTime

              final formattedTimestamp = _formatTimestamp(timestamp);
              final notificationIcon =
                  _getNotificationIcon(notification['type']);
              final notificationBadge = _buildNotificationBadge(notification);

              // Modify the title based on the notification type
              String notificationTitle = notification['type'] == 'task'
                  ? notification['message']?.contains('You assigned') ??
                          false
                      ? 'Task Assigned'
                      : 'Task Available'
                  : notification['type'] == 'schedule'
                      ? 'Schedule Confirmation'
                      : 'Notification';

              // Return your UI widget
              return GestureDetector(
                onTap: () async {
                  await markNotificationAsRead(widget.userId, notification);
                  _showNotificationDetails(context, notification);
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.gray,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          notificationIcon,
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notificationTitle, // Updated title
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Outfit',
                                    fontSize: 18,
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                if (formattedTimestamp.isNotEmpty)
                                  Text(
                                    'Received on $formattedTimestamp',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      notificationBadge,
                    ],
                  ),
                ),
              );
            }).toList(),
          );
  }

  Icon _getNotificationIcon(String type) {
    switch (type) {
      case 'schedule':
        return Icon(Icons.calendar_today, color: AppColors.black, size: 24);
      case 'task':
        return Icon(Icons.assignment, color: AppColors.black, size: 24);
      default:
        return Icon(Icons.notifications, color: AppColors.black, size: 24);
    }
  }

  Widget _buildNotificationBadge(Map<String, dynamic> notification) {
    if (notification['read'] == true) {
      return const SizedBox.shrink(); // No badge if read
    }

    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown Date';
    return DateFormat('MMMM dd, yyyy h:mm a').format(timestamp);
  }

  void _showNotificationDetails(
      BuildContext context, Map<String, dynamic> notification) {
    String title = notification['type'] == 'schedule'
        ? 'Schedule Details'
        : notification['type'] == 'task'
            ? 'Task Details'
            : 'Notification Details';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        content: Text(
          notification['message'] ?? 'No message available.',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Outfit',
            color: AppColors.black,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              backgroundColor: AppColors.neon,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: Colors.white,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              deleteNotification(context, notification['notificationId']);
              Navigator.of(context).pop(); // Close dialog
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
