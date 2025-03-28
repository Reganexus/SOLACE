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
    try {
      // Request permissions for notifications
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for notifications.');
      } else {
        debugPrint('User denied notification permissions.');
      }

      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@drawable/notification_icon');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: androidSettings);

      await _localNotificationsPlugin.initialize(initializationSettings);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Manage FCM token
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        if (newToken != null) {
          await _handleTokenRefresh(newToken);
        }
      });

      // Fetch and save the initial token
      await fetchAndSaveToken();
    } catch (e, stackTrace) {
      debugPrint('Error initializing MessagingService: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Handle messages received in the foreground
  static void _onForegroundMessage(RemoteMessage message) {
    debugPrint(
      'Received message in the foreground: ${message.notification?.title}',
    );
    _showLocalNotification(message);
  }

  /// Background message handler
  @pragma('vm:entry-point') // Ensures this function is preserved for isolates
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    try {
      // Ensure Firebase is initialized in the isolate
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Handle the background message
      debugPrint("Handling a background message: ${message.messageId}");
    } catch (e, stackTrace) {
      debugPrint('Error in background message handler: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'default_channel',
            'Default Channel',
            channelDescription: 'Channel for default notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            icon: '@drawable/notification_icon',
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        notificationDetails,
      );
    } catch (e, stackTrace) {
      debugPrint('Error showing local notification: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Fetch and save the FCM token to Firestore
  static Future<void> fetchAndSaveToken() async {
    try {
      final DatabaseService db = DatabaseService();
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('No authenticated user found to fetch the token.');
        return;
      }

      final String? userRole = await db.fetchAndCacheUserRole(user.uid);

      if (userRole == null) {
        debugPrint('User role not found for UID: ${user.uid}');
        return;
      }

      final String? token = await _firebaseMessaging.getToken();

      if (token == null) {
        debugPrint('Failed to fetch FCM token.');
        return;
      }

      // Retry mechanism for saving the token
      const int maxRetries = 3;
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          final DocumentSnapshot<Map<String, dynamic>> doc =
              await FirebaseFirestore.instance
                  .collection(userRole)
                  .doc(user.uid)
                  .get();

          final String? existingToken = doc.data()?['fcmToken'];

          // Avoid updating if the token is already up-to-date
          if (existingToken == token) {
            debugPrint('FCM Token is already up-to-date.');
            return;
          }

          await FirebaseFirestore.instance
              .collection(userRole)
              .doc(user.uid)
              .update({'fcmToken': token});

          debugPrint('FCM Token successfully fetched and saved.');
          break; // Exit the retry loop on success
        } catch (e) {
          if (attempt == maxRetries - 1) {
            debugPrint('Max retries reached. Failed to save FCM token: $e');
            throw Exception(
              'Failed to save FCM token after $maxRetries attempts.',
            );
          }
          debugPrint('Retrying to save FCM token... (Attempt ${attempt + 1})');
          await Future.delayed(
            const Duration(seconds: 2),
          ); // Wait before retrying
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error in fetchAndSaveToken: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Save FCM Token to Firestore
  static Future<void> _saveTokenToDatabase(
    String token,
    String userId,
    String collection,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .update({'fcmToken': token});

      debugPrint('FCM Token saved successfully: $token');
    } catch (e, stackTrace) {
      debugPrint('Error saving FCM token: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Handle FCM token refresh and save to Firestore
  static Future<void> _handleTokenRefresh(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final role = await DatabaseService().fetchAndCacheUserRole(user.uid);
        if (role == null) {
          debugPrint('User role not found for UID: ${user.uid}');
          return;
        }
        await _saveTokenToDatabase(token, user.uid, role);
      } catch (e, stackTrace) {
        debugPrint('Error updating FCM token: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    } else {
      debugPrint('No authenticated user found for token update.');
    }
  }

  /// Load service account JSON from assets
  static Future<Map<String, dynamic>> _loadServiceAccountJson() async {
    try {
      final jsonString = await rootBundle.loadString(
        'lib/assets/solace-28954-firebase-adminsdk-xa5bk-d441055ef8.json',
      );
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      debugPrint('Error loading service account JSON: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to load service account JSON.');
    }
  }

  static Future<String> getAccessToken() async {
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(
          _tokenExpiry!.subtract(const Duration(minutes: 1)),
        )) {
      return _cachedAccessToken!;
    }

    try {
      final serviceAccount = await _loadServiceAccountJson();
      final accountCredentials = ServiceAccountCredentials.fromJson(
        serviceAccount,
      );
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final authClient = await clientViaServiceAccount(
        accountCredentials,
        scopes,
      );

      _cachedAccessToken = authClient.credentials.accessToken.data;
      _tokenExpiry = authClient.credentials.accessToken.expiry;

      return _cachedAccessToken!;
    } catch (e, stackTrace) {
      debugPrint('Error fetching access token: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception(
        'Failed to fetch access token. Check network or credentials.',
      );
    }
  }

  static Future<String> getFcmEndpoint() async {
    try {
      final serviceAccount = await _loadServiceAccountJson();
      final projectId = serviceAccount['project_id'];
      return 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
    } catch (e, stackTrace) {
      debugPrint('Error fetching FCM endpoint: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to fetch FCM endpoint.');
    }
  }

  /// Send custom data messages without notifications
  static Future<void> sendDataMessage(
    String targetToken,
    Map<String, String> data,
  ) async {
    try {
      final String accessToken = await getAccessToken();
      final String fcmEndpoint = await getFcmEndpoint();

      final payload = {
        "message": {"token": targetToken, "data": data},
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
        debugPrint('Data message sent successfully.');
      } else {
        throw Exception('Failed to send data message: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error sending data message: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
