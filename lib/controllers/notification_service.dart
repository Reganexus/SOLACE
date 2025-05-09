import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/controllers/messaging_service.dart';
import 'package:solace/services/database.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService db = DatabaseService();

  Future<void> sendNotificationToTaggedUsers(
    String patientId,
    String title,
    String body,
  ) async {
    try {
      // Step 1: Fetch all tagged user IDs
      final taggedUserIds = await _getTaggedUserIds(patientId);

      if (taggedUserIds.isEmpty) {
        return;
      }

      // Step 2: Fetch FCM tokens of each tagged user
      final fcmTokens = await _getFcmTokens(taggedUserIds);

      if (fcmTokens.isEmpty) {
        //         debugPrint("No FCM tokens found for tagged users.");
        return;
      }

      // Step 3: Send notifications
      for (String token in fcmTokens) {
        await MessagingService.sendDataMessage(token, title, body);
      }
    } catch (e) {
      //       debugPrint("Error in sendNotificationToTaggedUsers: $e");
    }
  }

  Future<void> sendInAppNotificationToTaggedUsers({
    required String patientId,
    required String currentUserId,
    required String notificationMessage,
    required String type,
  }) async {
    try {
      // Step 1: Fetch all tagged user IDs
      final taggedUserIds = await _getTaggedUserIds(patientId);

      // Step 2: Filter out the current user ID
      final filteredUserIds =
          taggedUserIds.where((id) => id != currentUserId).toList();

      if (filteredUserIds.isEmpty) {
        // No tagged users to notify after filtering
        return;
      }

      // Step 3: Send in-app notifications to each tagged user
      for (String userId in filteredUserIds) {
        await db.addNotification(userId, notificationMessage, type);
      }
    } catch (e) {
      // Handle any errors during the notification process
      // debugPrint("Error in sendInAppNotificationToTaggedUsers: $e");
      throw Exception("Failed to send in-app notifications.");
    }
  }

  /// Fetch all tagged user IDs under the patient's 'tags' subcollection
  Future<List<String>> _getTaggedUserIds(String patientId) async {
    try {
      final snapshot =
          await _firestore
              .collection('patient')
              .doc(patientId)
              .collection('tags')
              .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      //       debugPrint("Error fetching tagged user IDs: $e");
      return [];
    }
  }

  Future<void> sendNotificationToAllAdmins(String title, String body) async {
    try {
      final adminsSnapshot = await _firestore.collection('admin').get();

      final fcmTokens =
          adminsSnapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                return data?['fcmToken'] as String?;
              })
              .where((token) => token != null && token.isNotEmpty)
              .cast<String>()
              .toList();

      if (fcmTokens.isEmpty) {
        return;
      }

      for (String token in fcmTokens) {
        await MessagingService.sendDataMessage(token, title, body);
      }
    } catch (e) {
      // debugPrint("Error in sendNotificationToAllAdmins: $e");
    }
  }

  /// Fetch the FCM tokens of the tagged users
  Future<List<String>> _getFcmTokens(List<String> userIds) async {
    List<String> tokens = [];

    for (String userId in userIds) {
      try {
        // Fetch user document directly from Firestore
        final docSnapshot = await db.fetchUserDocument(userId);

        if (docSnapshot != null && docSnapshot.exists) {
          final data =
              docSnapshot.data() as Map<String, dynamic>?; // Convert to Map
          final token = data?['fcmToken'] as String?; // Extract fcmToken

          if (token != null && token.isNotEmpty) {
            tokens.add(token);
          }
        }
      } catch (e) {
        //         debugPrint("Error fetching FCM token: $e");
      }
    }

    return tokens;
  }
}
