import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:solace/services/database.dart';

class TaskUtility {
  final DatabaseService _databaseService = DatabaseService();
  Future<void> saveTask({
    required String userId,
    required String taskId,
    required String collectionName,
    required String subCollectionName,
    required String taskTitle,
    required String taskDescription,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final taskData = {
      "taskId": taskId,
      "title": taskTitle,
      "description": taskDescription,
      "startDate": Timestamp.fromDate(startDate),
      "endDate": Timestamp.fromDate(endDate),
      "isCompleted": false,
    };

    await _databaseService.performFirestoreOperation(
      userId: userId,
      collectionName: collectionName,
      subCollectionName: subCollectionName,
      documentId: taskId,
      data: taskData,
      type: "task",
    );
  }

  Future<void> removeTask({
    required String userId,
    required String taskId,
    required String collectionName,
    required String subCollectionName,
  }) async {
    await _databaseService.removeDataFromUserCollection(
      userId: userId,
      collectionName: collectionName,
      subCollectionName: subCollectionName,
      documentId: taskId,
      type: "task",
    );
  }

  Future<void> updateTask({
    required String taskId,
    required String userId,
    required String collectionName,
    required String subCollectionName,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _databaseService.performFirestoreOperation(
        userId: userId,
        collectionName: collectionName,
        subCollectionName: subCollectionName,
        documentId: taskId,
        data: updates,
        isUpdate: true,
        type: "task",
      );
    } catch (e) {
      debugPrint("Error updating task: $e");
    }
  }
}
