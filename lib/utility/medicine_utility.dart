import 'package:solace/services/database.dart';

class MedicineUtility {
  final DatabaseService _databaseService = DatabaseService();
  Future<void> saveMedicine({
    required String userId,
    required String medicineId,
    required String collectionName,
    required String subCollectionName,
    required String medicineTitle,
    required String dosage,
    required String usage,
  }) async {
    final medicineData = {
      "medicineId": medicineId,
      "medicineName": medicineTitle,
      "dosage": dosage,
      "usage": usage,
    };

    await _databaseService.performFirestoreOperation(
      userId: userId,
      collectionName: collectionName,
      subCollectionName: subCollectionName,
      documentId: medicineId,
      data: medicineData,
      type: "medicine",
    );
  }

  Future<void> removeMedicine({
    required String userId,
    required String medicineId,
    required String collectionName,
    required String subCollectionName,
  }) async {
    await _databaseService.removeDataFromUserCollection(
      userId: userId,
      collectionName: collectionName,
      subCollectionName: subCollectionName,
      documentId: medicineId,
      type: "medicine",
    );
  }
}
