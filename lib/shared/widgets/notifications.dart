// ignore_for_file: avoid_print, use_build_context_synchronously, unnecessary_this

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';

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
  bool _isLoading = true;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  Future<void> deleteAllNotifications() async {
    //     debugPrint("deleteAllNotifications function called!");
    try {
      // Initialize the DatabaseService
      DatabaseService db = DatabaseService();

      // Fetch the user's role
      String? userRole = await db.fetchAndCacheUserRole(widget.userId);
      if (userRole == null) {
        //         debugPrint(
        //      'User role could not be determined for userId: ${widget.userId}',
        //     );
        showToast(
          'Failed to determine user role.',
          backgroundColor: AppColors.red,
        );
        return;
      }

      // Reference the user's notifications subcollection
      CollectionReference notificationsRef = FirebaseFirestore.instance
          .collection(userRole)
          .doc(widget.userId)
          .collection('notifications');

      // Delete all documents in the notifications subcollection
      var batch = FirebaseFirestore.instance.batch();
      var snapshots = await notificationsRef.get();
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      showToast('All notifications deleted successfully.');
      // Update local state
      setState(() {
        notifications.clear();
      });

      //       debugPrint('All notifications cleared for userId: ${widget.userId}');
    } catch (e) {
      //       debugPrint(
      //      'Error deleting all notifications for userId: ${widget.userId}: $e',
      //     );
      showToast(
        'Failed to delete notifications. Please try again.',
        backgroundColor: AppColors.red,
      );
    }
  }

  Future<void> deleteNotification(
    BuildContext context,
    String notificationId,
  ) async {
    try {
      // Fetch user role
      DatabaseService db = DatabaseService();
      String? userRole = await db.fetchAndCacheUserRole(widget.userId);

      if (userRole == null) {
        //         debugPrint('User role could not be determined.');
        return;
      }

      // Reference to the notification document
      DocumentReference notificationDocRef = FirebaseFirestore.instance
          .collection(userRole)
          .doc(widget.userId)
          .collection('notifications')
          .doc(notificationId);

      // Delete the notification document
      await notificationDocRef.delete();

      showToast('Notification successfully deleted.');
      // Update local state
      setState(() {
        notifications.removeWhere(
          (notification) => notification['notificationId'] == notificationId,
        );
      });

      //       debugPrint('Notification successfully deleted.');
    } catch (e) {
      //       debugPrint('Error deleting notification: $e');
      showToast(
        'Error deleting notification. Please try again.',
        backgroundColor: AppColors.red,
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
      String? userRole = await db.fetchAndCacheUserRole(widget.userId);

      if (userRole == null) {
        throw Exception('Failed to determine user role.');
      }

      // Reference the user's notifications subcollection
      CollectionReference notificationsRef = FirebaseFirestore.instance
          .collection(userRole)
          .doc(widget.userId)
          .collection('notifications');

      // Fetch all notifications
      QuerySnapshot snapshot = await notificationsRef.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          notifications = []; // No notifications found
          _errorMessage = null; // Clear the error message
        });
        return;
      }

      // Process notifications
      final loadedNotifications =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'message': data['message'] ?? 'No message available',
              'notificationId': data['notificationId'] ?? '',
              'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
              'type': data['type'] ?? 'unknown',
              'read': data['read'] ?? false,
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
      //       debugPrint('Error fetching notifications: $e');
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
    String userId,
    Map<String, dynamic> notification,
    String role,
  ) async {
    final notificationId = notification['notificationId'];

    try {
      // Reference the specific notification document
      DocumentReference notificationRef = FirebaseFirestore.instance
          .collection(role)
          .doc(userId)
          .collection('notifications')
          .doc(notificationId);

      // Update the 'read' field
      await notificationRef.update({'read': true});

      // Update the local state to reflect the change
      setState(() {
        final index = notifications.indexWhere(
          (n) => n['notificationId'] == notificationId,
        );
        if (index != -1) {
          notifications[index]['read'] = true;
        }
      });

      //       debugPrint('Notification marked as read.');
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Icon _getNotificationIcon(String type) {
    switch (type) {
      case 'schedule':
        return Icon(Icons.calendar_today, color: AppColors.black, size: 24);
      case 'task':
        return Icon(Icons.assignment, color: AppColors.black, size: 24);
      case 'medicine':
        return Icon(Icons.healing, color: AppColors.black, size: 24);
      case 'tag':
        return Icon(Icons.how_to_reg_sharp, color: AppColors.black, size: 24);
      case 'update':
        return Icon(Icons.info, color: AppColors.black, size: 24);
      case 'patient':
        return Icon(Icons.person, color: AppColors.black, size: 24);
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
    BuildContext context,
    Map<String, dynamic> notification,
  ) async {
    if (_isDialogOpen) return; // Prevent multiple dialogs
    setState(() {
      _isDialogOpen = true;
    });

    String title;

    switch (notification['type']) {
      case 'schedule':
        title = 'Schedule Details';
        break;
      case 'task':
        title = 'Task Details';
        break;
      case 'medicine':
        title = 'Medicine Details';
        break;
      case 'update':
        title = 'Account Update';
        break;
      case 'tag':
        title = 'Tagging Details';
        break;
      case 'patient':
        title = 'Patient Notice';
        break;
      default:
        title = 'Notification Details';
        break;
    }

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.white,
            title: Text(title, style: Textstyle.heading),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  notification['message'] ?? 'No message available.',
                  style: Textstyle.body,
                ),
                if (notification['timestamp'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Date: ${_formatTimestamp(notification['timestamp'])}',
                      style: Textstyle.subtitle,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                style: Buttonstyle.buttonNeon,
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: Text('Close', style: Textstyle.smallButton),
              ),
              TextButton(
                style: Buttonstyle.buttonRed,
                onPressed: () {
                  deleteNotification(context, notification['notificationId']);
                  Navigator.of(context).pop(); // Close dialog
                },
                child: Text('Delete', style: Textstyle.smallButton),
              ),
            ],
          ),
    );

    setState(() {
      _isDialogOpen = false; // Reset the flag
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: Loader.loaderNeon);
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: Textstyle.body,
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
              Text('No notifications yet', style: Textstyle.body),
            ],
          ),
        )
        : SingleChildScrollView(
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  notifications.map((notification) {
                    final timestampRaw = notification['timestamp'];
                    final DateTime? timestamp =
                        timestampRaw is Timestamp
                            ? timestampRaw.toDate()
                            : timestampRaw as DateTime?;

                    final formattedTimestamp = _formatTimestamp(timestamp);
                    final notificationIcon = _getNotificationIcon(
                      notification['type'],
                    );
                    final notificationBadge = _buildNotificationBadge(
                      notification,
                    );

                    String notificationTitle =
                        notification['type'] == 'task'
                            ? notification['message']?.contains(
                                      'You assigned',
                                    ) ??
                                    false
                                ? 'Task Assigned'
                                : 'Task Available'
                            : notification['type'] == 'schedule'
                            ? 'Schedule Confirmation'
                            : notification['type'] == 'update'
                            ? 'Account Update'
                            : notification['type'] == 'tag'
                            ? 'Tagging Details'
                            : notification['type'] == 'patient'
                            ? 'Patient Notice'
                            : 'Notification';

                    return GestureDetector(
                      onTap: () async {
                        DatabaseService db = DatabaseService();
                        String? userRole = await db.fetchAndCacheUserRole(
                          widget.userId,
                        );
                        if (userRole == null) {
                          //                           debugPrint('User role could not be determined.');
                          return;
                        }
                        await markNotificationAsRead(
                          widget.userId,
                          notification,
                          userRole,
                        );

                        _showNotificationDetails(context, notification);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notificationTitle,
                                        style: Textstyle.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (formattedTimestamp.isNotEmpty)
                                        Text(
                                          'Received on $formattedTimestamp',
                                          style: Textstyle.bodySuperSmall,
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
}
