// ignore_for_file: avoid_print, use_build_context_synchronously, unnecessary_this

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
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

  Future<String> _determineUserRole(String userId) async {
    List<String> userCollections = ['caregiver', 'doctor', 'admin', 'patient', 'unregistered'];
    for (String collection in userCollections) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .get();
      if (userDoc.exists) {
        return collection; // Return the role corresponding to the collection
      }
    }
    throw Exception('User role not found');
  }

  Future<void> deleteAllNotifications() async {
    debugPrint("Function got called!");
    try {
      // Determine the correct user collection
      List<String> userCollections = ['caregiver', 'doctor', 'admin', 'patient', 'unregistered'];
      DocumentReference? userRef;

      for (String collection in userCollections) {
        DocumentReference ref = FirebaseFirestore.instance
            .collection(collection)
            .doc(widget.userId);
        DocumentSnapshot userDocSnapshot = await ref.get();
        if (userDocSnapshot.exists) {
          userRef = ref; // Assign only if document exists
          break; // Exit loop if user document is found
        }
      }

      if (userRef == null) {
        debugPrint('User document does not exist!');
        return;
      }

      // Fetch and clear notifications
      final userDocSnapshot = await userRef.get();
      final data = userDocSnapshot.data() as Map<String, dynamic>?;

      if (data == null ||
          data['notifications'] == null ||
          (data['notifications'] as List).isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No notifications to clear.')),
        );
        return;
      }

      // Clear notifications
      await userRef.update({'notifications': []});

      // Clear the local notifications list
      setState(() {
        this.notifications.clear(); // Refresh local state
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All notifications deleted successfully.')),
      );
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
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
      // List of possible user collections
      List<String> userCollections = ['caregiver', 'doctor', 'admin', 'patient', 'unregistered'];
      DocumentSnapshot? snapshot;

      // Iterate through collections to find the user document
      for (String collection in userCollections) {
        snapshot = await FirebaseFirestore.instance
            .collection(collection)
            .doc(widget.userId)
            .get();
        if (snapshot.exists) {
          break; // Exit loop if document is found
        }
      }

      if (snapshot == null || !snapshot.exists) {
        throw Exception('No notifications found for this user.');
      }

      // Safely cast the data to the expected type
      final data = snapshot.data() as Map<String, dynamic>?;

      if (data == null || data['notifications'] == null) {
        setState(() {
          notifications = []; // No notifications found
          _errorMessage = 'No notifications found.';
        });
        return;
      }

      // Safely cast the notifications list
      final notificationsData =
          List<Map<String, dynamic>>.from(data['notifications']);

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

      loadedNotifications.sort((a, b) {
        final aTimestamp = a['timestamp'] as DateTime?;
        final bTimestamp = b['timestamp'] as DateTime?;
        if (aTimestamp == null || bTimestamp == null) return 0;
        return bTimestamp.compareTo(aTimestamp);
      });

      setState(() {
        notifications = loadedNotifications; // Update local state
        _errorMessage = null;
      });
    } catch (e) {
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
                      String role = await _determineUserRole(widget.userId);
                      await markNotificationAsRead(
                          widget.userId, notification, role);

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
    final user = Provider.of<MyUser?>(context, listen: false);
    if (user == null) return;

    try {
      // Find the correct user collection
      List<String> userCollections = ['caregiver', 'doctor', 'admin', 'patient', 'unregistered'];
      DocumentReference? userDocRef;

      for (String collection in userCollections) {
        userDocRef =
            FirebaseFirestore.instance.collection(collection).doc(user.uid);
        DocumentSnapshot userDocSnapshot = await userDocRef.get();
        if (userDocSnapshot.exists) {
          break; // Exit loop if document is found
        }
      }

      if (userDocRef == null) {
        print('User document does not exist!');
        return;
      }

      // Fetch notifications and update
      final userDocSnapshot = await userDocRef.get();
      final data = userDocSnapshot.data() as Map<String, dynamic>?;

      if (data == null || data['notifications'] == null) {
        print('No notifications found.');
        return;
      }

      var notifications =
          List<Map<String, dynamic>>.from(data['notifications']);

      final notificationIndex = notifications
          .indexWhere((n) => n['notificationId'] == notificationId);

      if (notificationIndex != -1) {
        notifications.removeAt(notificationIndex);
        await userDocRef.update({'notifications': notifications});

        setState(() {
          this.notifications = notifications; // Refresh local state
        });

        print("Notification successfully deleted");
      } else {
        print('Notification not found');
      }
    } catch (e) {
      print('Error deleting notification: $e');
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
