// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/auth.dart';

class CloudMessagingService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize Firebase Messaging and Notification Handling
  static Future<void> initialize() async {
    // Request permissions for notifications (especially for iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications.');
    } else {
      print('User declined or has not accepted permission for notifications.');
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await _localNotificationsPlugin.initialize(initializationSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle background and terminated state messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Manage FCM token
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      if (newToken != null) {
        await _handleTokenRefresh(newToken);
      }
    });

    // Fetch and save the initial token
    await fetchAndSaveToken();
  }

  /// Handle messages received in the foreground
  static void _onForegroundMessage(RemoteMessage message) {
    print('Received message in the foreground: ${message.notification?.title}');
    _showLocalNotification(message);
  }

  /// Background message handler
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Received message in the background: ${message.notification?.title}');
    // Handle the background message here
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Channel for default notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
    );
  }

  /// Fetch and save the FCM token to Firestore
  static Future<void> fetchAndSaveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Iterate through role-based collections to find the user's document
      final List<String> roles = [
        'caregiver',
        'admin',
        'doctor',
        'patient',
        'unregistered'
      ];
      String? userRole; // Variable to store the user's role

      for (String role in roles) {
        final String collectionName =
            role; // Pluralize the role for the collection name
        final userDoc = await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          userRole = role; // Found the user's role
          break;
        }
      }

      if (userRole != null) {
        // Fetch the token and save it to Firestore
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _saveTokenToDatabase(
            token,
            user.uid,
            userRole, // Save the token to the correct role-based collection
          );
        } else {
          print('Failed to fetch FCM token.');
        }
      } else {
        print('User role not found in role-based collections.');
      }
    } else {
      print('No authenticated user found to fetch the token.');
    }
  }

  /// Save FCM Token to Firestore
  static Future<void> _saveTokenToDatabase(
      String token, String userId, String collection) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(userId)
        .update({'fcmToken': token});

    print('FCM Token saved successfully: $token');
  }

  /// Handle FCM token refresh and save to Firestore
  static Future<void> _handleTokenRefresh(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Use AuthService's initializeUserDocument to update the user document
        await AuthService().initializeUserDocument(
          uid: user.uid,
          email: user.email!,
          isVerified: user.emailVerified,
          newUser: false, // For token refresh, user is not new
          userRole:
              UserRole.caregiver, // Adjust this logic for dynamic role handling
          profileImageUrl:
              user.photoURL, // Pass the user's profile image if available
        );
        print('FCM token updated successfully: $token');
      } catch (e) {
        print('Error saving FCM token: $e');
      }
    } else {
      print('No authenticated user found for token update.');
    }
  }
}
