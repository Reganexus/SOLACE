// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class FCMHelper {
  static String? _cachedAccessToken;
  static DateTime? _tokenExpiry;

  /// Fetch access token
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
      rethrow;
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
      print('FCM message sent successfully.');
    } else {
      print('Failed to send FCM message: ${response.body}');
    }
  }

  /// Test notification
  static Future<void> sendTestNotification() async {
    try {
      // Get the FCM token dynamically
      final targetToken = await FirebaseMessaging.instance.getToken();

      if (targetToken == null) {
        print('Error: FCM token is null. Ensure Firebase is initialized properly.');
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
