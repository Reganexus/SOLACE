import 'package:cloud_firestore/cloud_firestore.dart';

class LogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String logsCollection = "logs"; // Firestore collection name

  /// Adds a log entry to Firestore for a given user.
  Future<void> addLog({
    required String userId,
    required String action,
    String? relatedUsers, // Admin ID or name
  }) async {
    try {
      await _firestore.collection(logsCollection).doc(userId).set({
        'logs': FieldValue.arrayUnion([
          {
            'action': action,
            'relatedUsers': relatedUsers ?? '',
            'timestamp': Timestamp.now(),
          }
        ]),
      }, SetOptions(merge: true)); // Merge to avoid overwriting existing logs
    } catch (e) {
      throw Exception("Failed to add log: $e");
    }
  }

  /// Fetches logs for a specific user, ordered by timestamp.
  Stream<List<Map<String, dynamic>>> getLogsForUser(String userId) {
    return _firestore.collection(logsCollection).doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      List<dynamic> logs = snapshot.data()?['logs'] ?? [];
      return logs.cast<Map<String, dynamic>>().reversed.toList();
    });
  }

  /// Deletes a specific log entry by document ID.
  Future<void> deleteLog(String logId) async {
    try {
      await _firestore.collection(logsCollection).doc(logId).delete();
    } catch (e) {
      throw Exception("Failed to delete log: $e");
    }
  }

  /// Clears all logs for a specific user.
  Future<void> clearUserLogs(String userId) async {
    try {
      var logsQuery = await _firestore
          .collection(logsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in logsQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception("Failed to clear logs: $e");
    }
  }
}


