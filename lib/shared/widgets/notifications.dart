// ignore_for_file: avoid_print, use_build_context_synchronously, unnecessary_this

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';

class NotificationList extends StatelessWidget {
  final String userId;
  final GlobalKey<NotificationsListState> notificationsListKey;

  const NotificationList({
    super.key,
    required this.userId,
    required this.notificationsListKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: NotificationsList(userId: userId, key: notificationsListKey),
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
  String? _errorMessage;
  List<Map<String, dynamic>> notifications = [];
  bool _isLoading = true; // To track loading state

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> deleteAllNotifications() async {
    debugPrint("deleteAllNotifications function called!");
    try {
      // Initialize the DatabaseService
      DatabaseService db = DatabaseService();

      // Fetch the user's role
      String? userRole = await db.getTargetUserRole(widget.userId);
      if (userRole == null) {
        debugPrint(
            'User role could not be determined for userId: ${widget.userId}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to determine user role.')),
        );
        return;
      }

      // Reference the user's document
      DocumentReference userRef =
          FirebaseFirestore.instance.collection(userRole).doc(widget.userId);

      // Fetch the user's document
      DocumentSnapshot userDocSnapshot = await userRef.get();
      if (!userDocSnapshot.exists) {
        debugPrint('User document does not exist for userId: ${widget.userId}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User document not found.')),
        );
        return;
      }

      // Get the notifications field
      final data = userDocSnapshot.data() as Map<String, dynamic>?;
      final notifications = data?['notifications'] as List<dynamic>?;

      if (notifications == null || notifications.isEmpty) {
        debugPrint('No notifications found for userId: ${widget.userId}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No notifications to clear.')),
        );
        return;
      }

      // Clear notifications in Firestore
      await userRef.update({'notifications': []});

      // Update local state
      setState(() {
        this.notifications.clear();
      });

      debugPrint('All notifications cleared for userId: ${widget.userId}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All notifications deleted successfully.')),
      );
    } catch (e) {
      debugPrint(
          'Error deleting all notifications for userId: ${widget.userId}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to delete notifications. Please try again.')),
      );
    }
  }

  Future<void> fetchNotifications() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      // Initialize DatabaseService and fetch user role
      DatabaseService db = DatabaseService();
      String? userRole = await db.getTargetUserRole(widget.userId);

      if (userRole == null) {
        throw Exception('Failed to determine user role.');
      }

      // Fetch the user's document
      DocumentReference userRef =
          FirebaseFirestore.instance.collection(userRole).doc(widget.userId);
      DocumentSnapshot snapshot = await userRef.get();

      if (!snapshot.exists) {
        throw Exception('No notifications found for this user.');
      }

      // Extract data safely
      final data = snapshot.data() as Map<String, dynamic>?;
      final notificationsData = data?['notifications'] as List<dynamic>?;

      if (notificationsData == null || notificationsData.isEmpty) {
        setState(() {
          notifications = []; // No notifications found
          _errorMessage = null; // Clear the error message
        });
        return;
      }

      // Process notifications
      final loadedNotifications = notificationsData.map((notification) {
        final timestamp = notification['timestamp'];
        DateTime? convertedTimestamp;

        if (timestamp is Timestamp) {
          convertedTimestamp = timestamp.toDate();
        } else if (timestamp is DateTime) {
          convertedTimestamp = timestamp;
        }

        return {
          'message': notification['message'] ?? 'No message available',
          'notificationId': notification['notificationId'] ?? '',
          'timestamp': convertedTimestamp,
          'type': notification['type'] ?? 'unknown',
          'read': notification['read'] ?? false,
        };
      }).toList();

      // Sort notifications by timestamp (newest first)
      loadedNotifications.sort((a, b) {
        final aTimestamp = a['timestamp'] as DateTime?;
        final bTimestamp = b['timestamp'] as DateTime?;
        if (aTimestamp == null || bTimestamp == null) return 0;
        return bTimestamp.compareTo(aTimestamp);
      });

      // Update local state
      setState(() {
        notifications = loadedNotifications;
        _errorMessage = null; // Clear error message
      });
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() {
        _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      });
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  Future<void> markNotificationAsRead(
      String userId, Map<String, dynamic> notification, String role) async {
    final notificationId =
        notification['notificationId']; // Use the notificationId

    try {
      // Determine the role-based collection
      final userRef = FirebaseFirestore.instance
          .collection(role) // Replace 'users' with the role collection
          .doc(userId);

      // Retrieve the current notifications array
      final docSnapshot = await userRef.get();
      final notificationsData =
          (docSnapshot.data()?['notifications'] ?? []) as List<dynamic>;

      final updatedNotifications =
          notificationsData.map((existingNotification) {
        final notificationMap = existingNotification as Map<String, dynamic>;
        if (notificationMap['notificationId'] == notificationId) {
          return {
            ...notificationMap, // Spread the existing notification data
            'read': true, // Only update the 'read' flag
          };
        }
        return notificationMap;
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
          notifications[index]['read'] = true; // Update the local state
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.neon),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(fontSize: 18, color: AppColors.black),
          textAlign: TextAlign.center,
        ),
      );
    }

    return notifications.isEmpty
        ? Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_read,
                color: AppColors.black,
                size: 80,
              ),
              const SizedBox(height: 20.0),
              Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.black,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ))
        : SingleChildScrollView(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: notifications.map((notification) {
                  final timestampRaw = notification['timestamp'];
                  final DateTime? timestamp = timestampRaw is Timestamp
                      ? timestampRaw.toDate()
                      : timestampRaw as DateTime?;

                  final formattedTimestamp = _formatTimestamp(timestamp);
                  final notificationIcon =
                      _getNotificationIcon(notification['type']);
                  final notificationBadge =
                      _buildNotificationBadge(notification);

                  String notificationTitle = notification['type'] == 'task'
                      ? notification['message']?.contains('You assigned') ??
                              false
                          ? 'Task Assigned'
                          : 'Task Available'
                      : notification['type'] == 'schedule'
                          ? 'Schedule Confirmation'
                          : notification['type'] == 'friend_request'
                              ? 'Friend Request'
                              : 'Notification';

                  return GestureDetector(
                    onTap: () async {
                      DatabaseService db = DatabaseService();
                      String? userRole =
                          await db.getTargetUserRole(widget.userId);
                      await markNotificationAsRead(
                          widget.userId, notification, userRole!);

                      _showNotificationDetails(context, notification);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
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
                                      notificationTitle,
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
                                            fontSize: 12,
                                            color: Colors.black54),
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
              ),
            ),
          );
  }

  Icon _getNotificationIcon(String type) {
    switch (type) {
      case 'schedule':
        return Icon(Icons.calendar_today, color: AppColors.black, size: 24);
      case 'task':
        return Icon(Icons.assignment, color: AppColors.black, size: 24);
      case 'friend_request':
        return Icon(Icons.group_add,
            color: AppColors.black, size: 24); // New icon for friend request
      default:
        return Icon(Icons.notifications, color: AppColors.black, size: 24);
    }
  }

  Future<void> deleteNotification(
      BuildContext context, String notificationId) async {
    // Get the current user
    final user = Provider.of<MyUser?>(context, listen: false);
    if (user == null) {
      debugPrint('User is not logged in.');
      return;
    }

    try {
      // Fetch user role
      DatabaseService db = DatabaseService();
      String? userRole = await db.getTargetUserRole(user.uid);

      if (userRole == null) {
        debugPrint('User role could not be determined.');
        return;
      }

      // Reference to the user's document
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection(userRole).doc(user.uid);

      // Fetch the document snapshot
      DocumentSnapshot userDocSnapshot = await userDocRef.get();
      if (!userDocSnapshot.exists) {
        debugPrint('User document does not exist!');
        return;
      }

      // Extract notifications data
      final data = userDocSnapshot.data() as Map<String, dynamic>?;
      final notificationsData = data?['notifications'] as List<dynamic>?;

      if (notificationsData == null || notificationsData.isEmpty) {
        debugPrint('No notifications found.');
        return;
      }

      // Find and remove the notification by ID
      List<Map<String, dynamic>> notifications =
          List<Map<String, dynamic>>.from(notificationsData);
      final notificationIndex = notifications
          .indexWhere((n) => n['notificationId'] == notificationId);

      if (notificationIndex == -1) {
        debugPrint('Notification not found.');
        return;
      }

      notifications.removeAt(notificationIndex);

      // Update the user's document
      await userDocRef.update({'notifications': notifications});

      // Update local state
      setState(() {
        this.notifications = notifications;
      });

      debugPrint('Notification successfully deleted.');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
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
