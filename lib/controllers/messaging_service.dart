// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:solace/services/database.dart';

import '../firebase_options.dart';

class MessagingService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static String? _cachedAccessToken;
  static DateTime? _tokenExpiry;

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

    // Register background message handler
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
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    print("Handling a background message: ${message.messageId}");
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
    try {
      DatabaseService db = DatabaseService();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('No authenticated user found to fetch the token.');
        return;
      }

      final String? userRole = await db.getTargetUserRole(user.uid);

      if (userRole == null) {
        debugPrint('User role not found for UID: ${user.uid}');
        return;
      }

      final String? token = await _firebaseMessaging.getToken();

      if (token == null) {
        debugPrint('Failed to fetch FCM token.');
        return;
      }

      await _saveTokenToDatabase(token, user.uid, userRole);
      debugPrint('FCM token successfully fetched and saved.');
    } catch (e, stackTrace) {
      debugPrint('Error in fetchAndSaveToken: $e');
      debugPrint('Stack trace: $stackTrace');
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
        final role = await DatabaseService().getTargetUserRole(user.uid);
        if (role == null) {
          debugPrint('User role not found for UID: ${user.uid}');
          return;
        }
        await _saveTokenToDatabase(token, user.uid, role);
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }
    } else {
      debugPrint('No authenticated user found for token update.');
    }
  }

  /// Fetch access token for Firebase Admin API
  static Future<String> getAccessToken() async {
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAccessToken!;
    }

    try {
      final jsonString = await rootBundle.loadString(
          'lib/assets/solace-28954-firebase-adminsdk-xa5bk-d441055ef8.json');
      final serviceAccount = json.decode(jsonString);

      final accountCredentials =
          ServiceAccountCredentials.fromJson(serviceAccount);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final authClient =
          await clientViaServiceAccount(accountCredentials, scopes);

      _cachedAccessToken = authClient.credentials.accessToken.data;
      _tokenExpiry = authClient.credentials.accessToken.expiry;

      return _cachedAccessToken!;
    } catch (e) {
      print('Error fetching access token: $e');
      throw Exception(
          'Failed to fetch access token. Check network or credentials.');
    }
  }

  /// Get FCM endpoint
  static Future<String> getFcmEndpoint() async {
    final jsonString = await rootBundle.loadString(
        'lib/assets/solace-28954-firebase-adminsdk-xa5bk-d441055ef8.json');
    final serviceAccount = json.decode(jsonString);
    final projectId = serviceAccount['project_id'];
    return 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
  }

  /// Send FCM message
  static Future<void> sendFCMMessage(
      String targetToken, String title, String body) async {
    try {
      final String accessToken = await getAccessToken();
      final String fcmEndpoint = await getFcmEndpoint();

      final payload = {
        "message": {
          "token": targetToken,
          "notification": {
            "title": title,
            "body": body,
          },
          "data": {
            "key1": "value1",
            "key2": "value2",
          }
        }
      };

      final response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM message sent successfully.');
      } else {
        throw Exception('Failed to send FCM message: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error sending FCM message: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Send a test notification
  static Future<void> sendTestNotification() async {
    try {
      final targetToken = await FirebaseMessaging.instance.getToken();

      if (targetToken == null) {
        print(
            'Error: FCM token is null. Ensure Firebase is initialized properly.');
        return;
      }

      const title = 'Hello!';
      const body = 'This is a notification sent via HTTP v1.';

      await sendFCMMessage(targetToken, title, body);
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }
}
