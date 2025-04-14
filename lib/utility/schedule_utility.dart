import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/services/database.dart';

class ScheduleUtility {
  final DatabaseService _databaseService = DatabaseService();
  Future<void> saveSchedule({
    required String userId,
    required String scheduleId,
    required String collectionName,
    required String subCollectionName,
    required DateTime scheduledDateTime,
    Map<String, dynamic>? extraData,
  }) async {
    final timestamp = Timestamp.fromDate(scheduledDateTime);

    final scheduleData = {
      'scheduleId': scheduleId,
      'date': timestamp,
      ...?extraData,
    };

    await _databaseService.performFirestoreOperation(
      userId: userId,
      collectionName: collectionName,
      subCollectionName: subCollectionName,
      documentId: scheduleId,
      data: scheduleData,
      type: "schedule",
    );
  }

  Future<void> removePastSchedules(String userId) async {
    try {
      // Fetch the user role (caregiver or patient)
      final userRole = await _databaseService.fetchAndCacheUserRole(userId);
      final now = DateTime.now();

      if (userRole == null) {
        //         debugPrint("Failed to fetch user role for userId: $userId");
        throw Exception("User role not found.");
      }

      // Reference to the user's schedules subcollection
      final schedulesRef = FirebaseFirestore.instance
          .collection(userRole) // Collection based on userRole
          .doc(userId)
          .collection('schedules');

      // Fetch all schedule documents for this user
      final snapshot = await schedulesRef.get();

      if (snapshot.docs.isEmpty) {
        //         debugPrint("No schedules found for userId: $userId");
        return;
      }

      //       debugPrint(
      //       "Remove Past Schedules Snapshot: ${snapshot.docs.map((doc) => doc.data()).toList()}",
      //     );
      //       debugPrint("Remove Past Schedules User Id: $userId");
      //       debugPrint("Remove Past Schedules User Role: $userRole");

      // Initialize Firestore batch
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      // Process each schedule document
      for (final doc in snapshot.docs) {
        final scheduleData = doc.data();

        // Ensure 'date' field exists and is of type Timestamp
        if (scheduleData.containsKey('date') &&
            scheduleData['date'] is Timestamp) {
          final Timestamp timestamp = scheduleData['date'] as Timestamp;
          final scheduleDate = timestamp.toDate();

          //           debugPrint("Schedule Date: ${scheduleDate.toString()}");
          //           debugPrint("Schedule Date (formatted): ${scheduleDate.toLocal()}");
          //           debugPrint("Schedule Date Now: ${now.toLocal()}");

          if (scheduleDate.isBefore(now)) {
            // This schedule is in the past, add to batch for deletion
            batch.delete(doc.reference);
            //             debugPrint("Scheduled for deletion: ${doc.id}");
          }
        } else {
          //           debugPrint(
          //        "Skipping document ${doc.id} due to missing or invalid date field.",
          //        );
        }
      }

      // Commit the batch
      await batch.commit();
      //       debugPrint("Batch deletion completed for userId: $userId");
    } catch (e) {
      //       debugPrint("Error removing past schedules: $e");
      throw Exception("Failed to remove past schedules.");
    }
  }
}
