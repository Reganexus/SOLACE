import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientMedicine extends StatefulWidget {
  const PatientMedicine({super.key, required this.patientId});
  final String patientId;

  @override
  PatientMedicineState createState() => PatientMedicineState();
}

class PatientMedicineState extends State<PatientMedicine> {
  List<Map<String, dynamic>> patientMedicines = [];
  final DatabaseService db = DatabaseService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchPatientMedicines();
  }

  Future<void> fetchPatientMedicines() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in.';
        });
      }
      return;
    }

    try {
      final caregiverMedicinesSnapshot = await FirebaseFirestore.instance
          .collection('patient')
          .doc(widget.patientId)
          .collection('medicines')
          .get();

      if (caregiverMedicinesSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            patientMedicines = [];
            _isLoading = false;
          });
        }
        return;
      }

      final List<Map<String, dynamic>> medicines = [];
      for (var caregiverDoc in caregiverMedicinesSnapshot.docs) {
        final caregiverData = caregiverDoc.data();
        final caregiverId = caregiverDoc.id;
        final caregiverMedicines = List<Map<String, dynamic>>.from(
          caregiverData['medicines'] ?? [],
        );

        // Fetch caregiver details
        final caregiverRole = await db.getTargetUserRole(caregiverId);
        if (caregiverRole == null) continue;

        final caregiverSnapshot = await FirebaseFirestore.instance
            .collection(caregiverRole)
            .doc(caregiverId)
            .get();
        if (caregiverSnapshot.exists) {
          for (var medicine in caregiverMedicines) {
            final medicineName = medicine['medicineName'] as String?;
            final dosage = medicine['dosage'] as String?;
            final usage = medicine['usage'] as String?;
            final medicineId = medicine['medicineId'] as String?;
            if (medicineName == null || dosage == null || usage == null || medicineId == null) continue;

            medicines.add({
              'medicineName': medicineName,
              'dosage': dosage,
              'usage': usage,
              'medicineId': medicineId,
            });
          }
        }
      }

      medicines.sort((a, b) => a['medicineName'].compareTo(b['medicineName']));

      if (mounted) {
        setState(() {
          patientMedicines = medicines;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch medicines: $e';
        });
      }
    }
  }


  void _showMedicineDetailsDialog(Map<String, dynamic> medicine) {
    final String medicineName = medicine['medicineName'] ?? 'Untitled Medicine';
    final String dosage = medicine['dosage'] ?? '';
    final String usage = medicine['usage'] ?? '';
    debugPrint("Medicine $medicine");
    debugPrint("MedicineName: $medicineName");
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicineName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  "Use $dosage of this medicine for $usage",
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pop(); // Close dialog without doing anything
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          backgroundColor: AppColors.neon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Medicines',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child:
            _isLoading

                ? _buildLoadingState()
                : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : patientMedicines.isEmpty
                ? _buildNoMedicineState()
                : _buildMedicineList(),
      ),
    );
  }

  Widget _buildMedicineList() {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (var i = 0; i < patientMedicines.length; i++) ...[
            _buildMedicineCard(patientMedicines[i]),
            if (i < patientMedicines.length - 1) const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    final String medicineName = medicine['medicineName'] ?? 'Untitled Medicine';
    final String dosage = medicine['dosage'] ?? 'No Dosage';
    final String usage = medicine['usage'] ?? 'No Usage';

    return GestureDetector(
      onTap: () => _showMedicineDetailsDialog(medicine),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.gray,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'lib/assets/images/shared/vitals/medicine_black.png',
                  height: 25,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    medicineName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Divider(thickness: 1.0),
            const SizedBox(height: 5),

            // Description
            const Text(
              "Dosage",
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            Text(
              dosage,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.normal,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 10.0),
            const Text(
              "Usage",
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            Text(
              usage,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.normal,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 20.0),
          Text(
            "Loading... Please Wait",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.black, size: 80),
          const SizedBox(height: 20.0),
          Text(
            _errorMessage,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: AppColors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20.0),
          TextButton(
            onPressed: fetchPatientMedicines,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              backgroundColor: AppColors.neon,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMedicineState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.error_outline_rounded, color: AppColors.black, size: 80),
          SizedBox(height: 20.0),
          Text(
            "No Medicines Yet",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
