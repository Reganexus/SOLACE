// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, no_leading_underscores_for_local_identifiers, unnecessary_null_comparison, avoid_print, unnecessary_string_interpolations, prefer_final_fields

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';

class ViewPatientMedicine extends StatefulWidget {
  final String patientId;

  const ViewPatientMedicine({super.key, required this.patientId});

  @override
  _ViewPatientMedicineState createState() => _ViewPatientMedicineState();
}

class _ViewPatientMedicineState extends State<ViewPatientMedicine> {
  late DatabaseService databaseService;
  List<Map<String, dynamic>> medicines = [];
  List<FocusNode> _focusNodes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(4, (index) => FocusNode());
    databaseService = DatabaseService();
    _fetchPatientMedicines();
  }

  @override
  void dispose() {
    // Dispose focus nodes to prevent memory leaks
    for (var node in _focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  Future<void> _fetchPatientMedicines() async {
    print("Fetching medicines for patient: ${widget.patientId}");

    try {
      if (mounted) {
        setState(() {
          isLoading = true; // Show loading indicator
        });
      }

      final caregiverTasksSnapshot =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(widget.patientId)
              .collection('medicines')
              .get();

      if (caregiverTasksSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            medicines = [];
            isLoading = false;
          });
        }
        return;
      }

      // Accumulate all tasks from different caregiver documents
      final List<Map<String, dynamic>> loadedMedicines = [];
      for (var caregiverDoc in caregiverTasksSnapshot.docs) {
        final caregiverData = caregiverDoc.data();
        final caregiverId = caregiverDoc.id;
        final caregiverMedicines = List<Map<String, dynamic>>.from(
          caregiverData['medicines'] ?? [],
        );

        // Fetch caregiver details
        final caregiverRole = await databaseService.getTargetUserRole(
          caregiverId,
        );
        if (caregiverRole == null) continue;

        final caregiverSnapshot =
            await FirebaseFirestore.instance
                .collection(caregiverRole)
                .doc(caregiverId)
                .get();

        if (caregiverSnapshot.exists) {
          for (var medicine in caregiverMedicines) {
            final medicineId = medicine['medicineId'] ?? 'defaultMedicineId';
            if (medicineId.isEmpty) {
              continue;
            }

            loadedMedicines.add({
              'medicineName': medicine['medicineName'],
              'dosage': medicine['dosage'],
              'usage': medicine['usage'],
              'medicineId': medicineId,
            });
          }
        }
      }

      loadedMedicines.sort(
        (a, b) => a['medicineName'].compareTo(b['medicineName']),
      );
      if (mounted) {
        setState(() {
          medicines = loadedMedicines;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading medicines: $e");
      if (mounted) {
        setState(() {
          medicines = [];
          isLoading = false;
        });
      }
    }
  }

  Future<void> _addMedicine(
    String medicineName,
    String dosage,
    String frequency,
  ) async {
    try {
      String caregiverId = FirebaseAuth.instance.currentUser?.uid ?? '';
      debugPrint("Add medicine caregiver id: $caregiverId");

      if (caregiverId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("No caregiver logged in.")));
        return;
      }

      // Capitalize medicine name
      String capitalizeWords(String input) {
        return input
            .split(' ')
            .map(
              (word) =>
                  word.isNotEmpty
                      ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                      : word,
            )
            .join(' ');
      }

      medicineName = capitalizeWords(medicineName);

      // Generate a unique medicine ID
      String medicineId = FirebaseFirestore.instance.collection('_').doc().id;

      // Save the medicine for the patient
      await databaseService.saveMedicineForPatient(
        widget.patientId,
        medicineId,
        medicineName,
        dosage,
        frequency,
        caregiverId,
      );

      await databaseService.saveMedicineForDoctor(
        caregiverId,
        medicineId,
        medicineName,
        dosage,
        frequency,
        widget.patientId,
      );

      // Reload medicines after saving the new one
      _fetchPatientMedicines();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Medicine added successfully")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to add medicine: $e")));
    }
  }

  void _showAddMedicineDialog() {
    String medicineName = '';
    String dosageValue = '';
    String dosageUnit = 'mg'; // Default dosage unit
    String usage = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    const Text(
                      "Add Medicine",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      onChanged: (value) => medicineName = value,
                      decoration: InputDecoration(
                        labelText: "Medicine Name",
                        filled: true,
                        fillColor: AppColors.gray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.neon,
                            width: 2,
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.normal,
                          color:
                              _focusNodes[0].hasFocus
                                  ? AppColors.neon
                                  : AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            onChanged: (value) => dosageValue = value,
                            decoration: InputDecoration(
                              labelText: "Dosage",
                              filled: true,
                              fillColor: AppColors.gray,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.neon,
                                  width: 2,
                                ),
                              ),
                              labelStyle: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.normal,
                                color:
                                    _focusNodes[1].hasFocus
                                        ? AppColors.neon
                                        : AppColors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: dosageUnit,
                            dropdownColor: AppColors.white,
                            onChanged:
                                (value) => setModalState(
                                  () => dosageUnit = value ?? dosageUnit,
                                ),
                            items:
                                ["mg", "g", "mml", "l", "mcg"]
                                    .map(
                                      (unit) => DropdownMenuItem(
                                        value: unit,
                                        child: Text(
                                          unit,
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.normal,
                                            fontFamily: 'Inter',
                                            color: AppColors.black,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.gray,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.neon,
                                  width: 2,
                                ),
                              ),
                              labelStyle: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.normal,
                                color:
                                    _focusNodes[2].hasFocus
                                        ? AppColors.neon
                                        : AppColors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      onChanged: (value) => usage = value,
                      decoration: InputDecoration(
                        labelText: "Usage",
                        filled: true,
                        fillColor: AppColors.gray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.neon,
                            width: 2,
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.normal,
                          color:
                              _focusNodes[3].hasFocus
                                  ? AppColors.neon
                                  : AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 5,
                              ),
                              backgroundColor: AppColors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              if (medicineName.isNotEmpty &&
                                  dosageValue.isNotEmpty &&
                                  usage.isNotEmpty) {
                                _addMedicine(
                                  medicineName,
                                  "$dosageValue$dosageUnit",
                                  usage,
                                );
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Please fill in all fields"),
                                  ),
                                );
                              }
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
                            child: Text(
                              "Add Medicine",
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
      },
    );
  }

  Future<void> _removeMedicine(
    String patientId,
    String medicineId,
    String caregiverId,
  ) async {
    debugPrint("Remove Patient Id: $patientId");
    debugPrint("Remove Medicine Id: $medicineId");
    debugPrint("Remove Caregiver Id: $caregiverId");
    try {
      DatabaseService db = DatabaseService();
      await db.removeMedicine(patientId, medicineId, caregiverId);

      // Show snackbar indicating the task was deleted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Fetch the updated list of tasks after the removal
      _fetchPatientMedicines();
    } catch (e) {
      print("Error removing medicine: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete medicine'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          "View Medicines",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : medicines.isEmpty
              ? _buildNoMedicineState()
              : _buildMedicineList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neon,
        onPressed: _showAddMedicineDialog,
        child: Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildMedicineList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 10.0),
        itemCount: medicines.length,
        itemBuilder: (context, index) {
          final medicine = medicines[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: _buildMedicineCard(medicine),
          );
        },
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

  Widget _buildNoMedicineState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.error_outline_outlined, color: AppColors.black, size: 80),
          SizedBox(height: 20.0),
          Text(
            "No Medicine Yet",
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

  void _showMedicineDetailsDialog(Map<String, dynamic> medicine) {
    debugPrint("Medicine $medicine");
    final String medicineName = medicine['medicineName'] ?? 'Untitled Medicine';
    final String medicineId = medicine['medicineId'] ?? '';
    debugPrint("MedicineName: $medicineName");
    debugPrint("Medicine ID: $medicineId");
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
                  "Do you want to delete this medicine?",
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
                        onPressed: () async {
                          if (medicineId.isNotEmpty) {
                            String caregiverId =
                                FirebaseAuth.instance.currentUser?.uid ?? '';
                            await _removeMedicine(
                              widget.patientId,
                              medicineId,
                              caregiverId,
                            ); // Remove task and refresh
                            Navigator.of(context).pop(); // Close dialog
                          }
                        },

                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          backgroundColor: AppColors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
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
}
