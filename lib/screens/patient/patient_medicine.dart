import 'package:flutter/material.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';

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

    try {
      // Fetch all medicine documents under the patient's medicines subcollection
      final medicinesSnapshot =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(widget.patientId)
              .collection('medicines')
              .get();

      //       debugPrint(
      //       "Fetched ${medicinesSnapshot.docs.length} medicine documents.",
      //      );

      if (medicinesSnapshot.docs.isEmpty) {
        //         debugPrint("No medicines found under patient ${widget.patientId}.");
        if (mounted) {
          setState(() {
            patientMedicines = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Process medicine documents
      final List<Map<String, dynamic>> medicines =
          medicinesSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'medicineName': data['medicineName'] ?? 'Unknown',
              'dosage': data['dosage'] ?? 'Unknown',
              'usage': data['usage'] ?? 'Unknown',
              'medicineId': doc.id, // Use document ID as medicineId
            };
          }).toList();

      // Sort medicines alphabetically by medicineName
      medicines.sort((a, b) => a['medicineName'].compareTo(b['medicineName']));

      if (mounted) {
        setState(() {
          patientMedicines = medicines;
          _isLoading = false;
        });
      }
    } catch (e) {
      //       debugPrint("Error fetching medicines: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch medicines. Please try again.';
        });
      }
    }
  }

  void _showMedicineDetailsDialog(Map<String, dynamic> medicine) {
    final String medicineName = medicine['medicineName'] ?? 'Untitled Medicine';
    final String dosage = medicine['dosage'] ?? '';
    final String usage = medicine['usage'] ?? '';
    //     debugPrint("Medicine $medicine");
    //     debugPrint("MedicineName: $medicineName");
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
    return Container(
      color: AppColors.black.withValues(alpha: 0.8),
      width: double.infinity,
      height: 700,
      padding: EdgeInsets.all(16),
      child:
          _isLoading
              ? _buildLoadingState()
              : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : patientMedicines.isEmpty
              ? _buildNoMedicineState()
              : _buildMedicineList(),
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
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      medicineName,
                      style: Textstyle.body.copyWith(
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      dosage,
                      style: Textstyle.bodySmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.blackTransparent),

            // Description
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: Text(usage, style: Textstyle.body),
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
        children: [Loader.loaderPurple],
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
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.whiteTransparent,
            size: 70,
          ),
          SizedBox(height: 10.0),
          Text(
            "No Medicines Yet",
            style: Textstyle.bodyWhite.copyWith(
              color: AppColors.whiteTransparent,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
