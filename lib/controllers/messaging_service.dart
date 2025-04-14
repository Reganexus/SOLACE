// ignore_for_file: avoid_print, unused_element

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solace/services/database.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MessagingService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static String? _cachedAccessToken;
  static DateTime? _tokenExpiry;

  static Future<void> initialize() async {
    try {
      requestNotificationPermission();
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        //         debugPrint('User granted permission for notifications.');
      } else {
        //         debugPrint('User denied notification permissions.');
      }

      // Initialize Local Notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: androidSettings);

      await _localNotificationsPlugin.initialize(initializationSettings);

      // Listen for messages in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        //         debugPrint(
        //          'Received message in foreground: ${message.notification?.title}',
        //        );
        showLocalNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("Notification clicked! Data: ${message.data}");
      });

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        if (newToken != null) {
          await _handleTokenRefresh(newToken);
        }
      });

      await fetchAndSaveToken();
    } catch (e) {
      return;
      //       debugPrint('Error initializing MessagingService: $e');
      //       debugPrint('Stack trace: $stackTrace');
    }
  }

  static Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    //     debugPrint('Received message in foreground: ${message.data}');
    showLocalNotification(message);
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    try {
      //       debugPrint('Preparing to show local notification');

      // Wake up the device (only for the duration of the notification)
      WakelockPlus.enable();

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Channel for default notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            icon: '@drawable/ic_notification',
            fullScreenIntent: true,
            timeoutAfter: 30000,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      final String title = message.notification?.title ?? 'New Notification';
      final String body = message.notification?.body ?? 'Tap to open the app';

      //       debugPrint('Showing notification: Title: $title, Body: $body');

      await _localNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        notificationDetails,
      );

      // Release wake lock after a short delay
      await Future.delayed(const Duration(seconds: 5));
      WakelockPlus.disable();

      //       debugPrint('Notification displayed successfully.');
    } catch (e) {
      //       debugPrint('Error showing local notification: $e');
      //       debugPrint('Stack trace: $stackTrace');
    }
  }

  static Future<void> fetchAndSaveToken() async {
    try {
      final DatabaseService db = DatabaseService();
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        //         debugPrint('No authenticated user found to fetch the token.');
        return;
      }

      final String? userRole = await db.fetchAndCacheUserRole(user.uid);

      if (userRole == null) {
        //         debugPrint('User role not found for UID: ${user.uid}');
        return;
      }

      final String? token = await _firebaseMessaging.getToken();

      if (token == null) {
        //         debugPrint('Failed to fetch FCM token.');
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
            //             debugPrint('FCM Token is already up-to-date.');
            return;
          }

          await FirebaseFirestore.instance
              .collection(userRole)
              .doc(user.uid)
              .update({'fcmToken': token});

          //           debugPrint('FCM Token successfully fetched and saved.');
          break; // Exit the retry loop on success
        } catch (e) {
          if (attempt == maxRetries - 1) {
            //             debugPrint('Max retries reached. Failed to save FCM token: $e');
            throw Exception(
              'Failed to save FCM token after $maxRetries attempts.',
            );
          }
          //           debugPrint('Retrying to save FCM token... (Attempt ${attempt + 1})');
          await Future.delayed(
            const Duration(seconds: 2),
          ); // Wait before retrying
        }
      }
    } catch (e) {
      //       debugPrint('Error in fetchAndSaveToken: $e');
      //       debugPrint('Stack trace: $stackTrace');
    }
  }

  static Future<void> _handleTokenRefresh(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await fetchAndSaveToken(); // Ensures proper handling
    } else {
      //       debugPrint('No authenticated user found for token update.');
    }
  }

  static Future<Map<String, dynamic>> _loadServiceAccountJson() async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'admin_sdk/service_account.json',
      );
      final String downloadUrl = await ref.getDownloadURL();

      //       debugPrint("Service account JSON URL: $downloadUrl");

      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode == 200) {
        //         debugPrint("Successfully fetched service account JSON.");
        return json.decode(response.body);
      } else {
        //         debugPrint(
        //          "Failed to fetch service account JSON. Status code: ${response.statusCode}",
        //        );
        throw Exception(
          'Failed to fetch service account JSON. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      //       debugPrint('Error loading service account JSON: $e');
      //       debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to load service account JSON.');
    }
  }

  static Future<String> getAccessToken() async {
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(
          _tokenExpiry!.subtract(const Duration(minutes: 1)),
        )) {
      //       debugPrint("Using cached access token.");
      return _cachedAccessToken!;
    }

    try {
      //       debugPrint("Fetching new access token...");
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

      //       debugPrint("Access token fetched successfully.");
      return _cachedAccessToken!;
    } catch (e) {
      //       debugPrint('Error fetching access token: $e');
      //       debugPrint('Stack trace: $stackTrace');
      throw Exception(
        'Failed to fetch access token. Check network or credentials.',
      );
    }
  }

  static Future<String> getFcmEndpoint() async {
    try {
      final serviceAccount = await _loadServiceAccountJson();
      final projectId = serviceAccount['project_id'];
      final fcmEndpoint =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      //       debugPrint("FCM endpoint: $fcmEndpoint");

      return fcmEndpoint;
    } catch (e) {
      //       debugPrint('Error fetching FCM endpoint: $e');
      //       debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to fetch FCM endpoint.');
    }
  }

  static Future<void> sendDataMessage(
    String token,
    String title,
    String body,
  ) async {
    try {
      //       debugPrint("Preparing data message to send.");
      //       debugPrint("Ttile $title");
      //       debugPrint("Body: $body");

      final accessToken = await getAccessToken();
      //       debugPrint("Access token: $accessToken");

      final messageTitle = title;
      final messageBody = body;

      final message = {
        "message": {
          "token": token,
          "notification": {"title": messageTitle, "body": messageBody},
        },
      };

      //       debugPrint("Sending message to FCM...");

      final endpoint = await getFcmEndpoint();
      //       debugPrint("FCM Endpoint: $endpoint");

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(message),
      );

      //       debugPrint("FCM Response Status: ${response.statusCode}");
      //       debugPrint("FCM Response Body: ${response.body}");

      if (response.statusCode == 200) {
        //         debugPrint('Notification sent successfully');
      } else {
        //         debugPrint('Error sending notification: ${response.body}');
      }
    } catch (e) {
      //       debugPrint('Error sending data message: $e');
      rethrow;
    }
  }
}
