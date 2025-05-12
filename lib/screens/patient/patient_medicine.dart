import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/controllers/notification_service.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/buttonstyle.dart';
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
  final DatabaseService databaseService = DatabaseService();
  final NotificationService notificationService =
      NotificationService(); // Instantiate NotificationService
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchPatientMedicines();
  }

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  Future<void> fetchPatientMedicines() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final medicinesSnapshot =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(widget.patientId)
              .collection('medicines')
              .get();

      if (medicinesSnapshot.docs.isEmpty) {
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
              'frequency': data['frequency'] ?? 'Unknown',
              'usage': data['usage'] ?? 'Unknown',
              'isTaken':
                  data['isTaken'] ?? false, // Ensure isTaken is a boolean
              'medicineId': doc.id,
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

      showToast('Medicines fetched successfully.');
    } catch (e) {
      // Error fetching medicines
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch medicines. Please try again.';
        });
      }
      showToast('Error fetching medicines: $e');
    }
  }

  void _showMedicineDetailsDialog(
    Map<String, dynamic> medicine,
    String medicineId,
  ) {
    final String medicineName = medicine['medicineName'] ?? 'Untitled Medicine';
    final String dosage = medicine['dosage'] ?? '';
    final String frequency = medicine['frequency'] ?? '';
    final String usage = medicine['usage'] ?? '';
    final bool isTaken = medicine['isTaken'] == true;

    // Function to update the medicine status (mark as taken or drop)
    void toggleMedicineStatus(
      String patientId,
      String medicineId,
      bool isCurrentlyTaken,
    ) async {
      try {
        await FirebaseFirestore.instance
            .collection('patient')
            .doc(patientId)
            .collection('medicines')
            .doc(medicineId)
            .update({'isTaken': !isCurrentlyTaken}); // Toggle the status

        final String action = isCurrentlyTaken ? 'dropped' : 'marked as taken';
        showToast('Medicine has been $action.');
        fetchPatientMedicines();

        final User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return showToast("User not authenticated");
        }

        final String caregiverId = user.uid;
        if (caregiverId != null) {
          final String? caregiverRole = await databaseService
              .fetchAndCacheUserRole(caregiverId);
          final String role =
              '${caregiverRole?.substring(0, 1).toUpperCase()}${caregiverRole?.substring(1)}';
          final String? caregiverName = await databaseService.fetchUserName(
            caregiverId,
          );
          final String? patientName = await databaseService.fetchUserName(
            patientId,
          );

          final String notificationMessage =
              "$role $caregiverName $action medicine '$medicineName' for patient $patientName.";

          await databaseService.addNotification(
            caregiverId,
            notificationMessage,
            'medicine',
          );

          // In-app notification
          await notificationService.sendInAppNotificationToTaggedUsers(
            patientId: widget.patientId,
            currentUserId: caregiverId,
            notificationMessage: notificationMessage,
            type: "medicine",
          );

          // Push notification
          await notificationService.sendNotificationToTaggedUsers(
            widget.patientId,
            "Medicine Status Update",
            notificationMessage,
          );

          // Log the action (you might want a dedicated logging service)
          showToast('Medicine $medicineName has $action');
        } else {
          showToast(
            'Warning: Caregiver ID not set, cannot send notification or log.',
          );
        }
        // --- End Notification and Logging ---
      } catch (error) {
        showToast('Failed to update medicine status: $error');
        debugPrint('Error updating medicine status: $error');
      }
    }

    // Function to show the confirmation dialog for taking/dropping medicine
    void showConfirmationDialog(bool isCurrentlyTaken) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.white,
            title: Text(
              isCurrentlyTaken ? 'Drop Medicine' : 'Take Medicine',
              style: Textstyle.subheader,
            ),
            content: Text(
              isCurrentlyTaken
                  ? 'Are you sure you want to drop $medicineName?'
                  : 'Are you sure you want to take $medicineName?',
              style: Textstyle.body,
            ),
            actions: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(); // Close the confirmation dialog
                      },
                      style: Buttonstyle.buttonRed,
                      child: Text('Cancel', style: Textstyle.smallButton),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        toggleMedicineStatus(
                          widget.patientId,
                          medicineId,
                          isCurrentlyTaken,
                        );
                        Navigator.of(
                          context,
                        ).pop(); // Close the confirmation dialog
                      },
                      style: Buttonstyle.buttonNeon,
                      child: Text(
                        isCurrentlyTaken ? 'Drop' : 'Take',
                        style: Textstyle.smallButton,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }

    // Show the main medicine details dialog
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
                Text(medicineName, style: Textstyle.subheader),
                const SizedBox(height: 10.0),
                Text(
                  "Use $dosage of this medicine $frequency. $usage",
                  style: Textstyle.body,
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: Buttonstyle.buttonRed,
                        child: Text('Close', style: Textstyle.smallButton),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          debugPrint("Take Medicine button pressed!");
                          Navigator.of(context).pop();
                          showConfirmationDialog(isTaken);
                        },
                        style: Buttonstyle.buttonNeon,
                        child: Text(
                          isTaken ? 'Drop Medicine' : 'Take Medicine',
                          style: Textstyle.smallButton,
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
    final String frequency = medicine['frequency'] ?? 'No Frequency';
    final String usage = medicine['usage'] ?? 'No Usage';
    final String medicineId = medicine['medicineId'];
    final bool isTaken = medicine['isTaken'] ?? false;

    return GestureDetector(
      onTap: () => _showMedicineDetailsDialog(medicine, medicineId),
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
                      color: isTaken ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      isTaken ? 'Taking' : 'Not Taken',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dosage, style: Textstyle.body),
                  Text(frequency, style: Textstyle.body),
                  Text(usage, style: Textstyle.body),
                ],
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
            "No Prescriptions Yet",
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
