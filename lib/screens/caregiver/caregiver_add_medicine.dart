// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, no_leading_underscores_for_local_identifiers, unnecessary_null_comparison, avoid_print, unnecessary_string_interpolations, prefer_final_fields

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/dropdownfield.dart';
import 'package:solace/themes/textformfield.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:solace/utility/medicine_utility.dart';

class ViewPatientMedicine extends StatefulWidget {
  final String patientId;

  const ViewPatientMedicine({super.key, required this.patientId});

  @override
  _ViewPatientMedicineState createState() => _ViewPatientMedicineState();
}

class _ViewPatientMedicineState extends State<ViewPatientMedicine> {
  final LogService _logService = LogService();
  DatabaseService databaseService = DatabaseService();
  MedicineUtility medicineUtility = MedicineUtility();
  List<Map<String, dynamic>> medicines = [];
  List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool isLoading = true;

  TextEditingController _medicineNameController = TextEditingController();
  TextEditingController _dosageController = TextEditingController();
  TextEditingController _usageController = TextEditingController();
  String dosageUnit = "milligrams";
  late String patientName = '';

  @override
  void initState() {
    super.initState();
    _fetchPatientMedicines();
    _loadPatientName();
    debugPrint("Patient Name: $patientName");
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _dosageController.dispose();
    _usageController.dispose();
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPatientName() async {
    final name = await databaseService.fetchUserName(widget.patientId);
    if (mounted) {
      setState(() {
        patientName = name ?? 'Unknown';
      });
    }
    debugPrint("Patient Name: $patientName");
  }

  void refreshValues() {
    setState(() {
      _medicineNameController.clear();
      _dosageController.clear();
      _usageController.clear();
      dosageUnit = "milligrams"; // Reset dosage unit to default
    });
  }

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  String getMedicineNameById(String medicineId) {
    final medicine = medicines.firstWhere(
      (med) => med['medicineId'] == medicineId,
      orElse:
          () => {'medicineName': 'Unknown Medicine'}, // Default if not found
    );
    return medicine['medicineName'] ?? 'Unknown Medicine';
  }

  Future<void> _fetchPatientMedicines() async {
    print("Fetching medicines for patient: ${widget.patientId}");

    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final medicinesRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(widget.patientId)
          .collection('medicines');

      final medicineSnapshots = await medicinesRef.get();

      if (medicineSnapshots.docs.isEmpty) {
        setState(() {
          medicines = [];
          isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> loadedMedicines =
          medicineSnapshots.docs
              .map((doc) {
                final data = doc.data();
                final medicineName =
                    data['medicineName'] ?? 'Untitled Medicine';
                final dosage = data['dosage'] ?? 'No Dosage';
                final usage = data['usage'] ?? 'No Usage';

                return {
                  'medicineId': doc.id,
                  'medicineName': medicineName,
                  'dosage': dosage,
                  'usage': usage,
                };
              })
              .where((medicine) => medicine['medicineName'] != null)
              .toList();

      loadedMedicines.sort(
        (a, b) => a['medicineName']!.compareTo(b['medicineName']!),
      );

      setState(() {
        medicines = loadedMedicines;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading medicine: $e");
      setState(() {
        medicines = [];
        isLoading = false;
      });
    }
  }

  Future<void> _addMedicine(
    String medicineName,
    String dosage,
    String frequency,
  ) async {
    try {
      // Get the caregiver ID (logged-in user)
      String caregiverId = FirebaseAuth.instance.currentUser?.uid ?? '';
      debugPrint("Add prescription doctor id: $caregiverId");

      if (caregiverId.isEmpty) {
        showToast("No doctor logged in.", 
            backgroundColor: AppColors.red);
        return;
      }

      // Capitalize the title and description
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

      // Generate a unique task ID
      String medicineId = FirebaseFirestore.instance.collection('_').doc().id;

      // Fetch the roles for both caregiver and patient
      final caregiverRole = await databaseService.fetchAndCacheUserRole(
        caregiverId,
      );
      final patientRole = await databaseService.fetchAndCacheUserRole(
        widget.patientId,
      );

      if (caregiverRole == null || patientRole == null) {
        debugPrint("Failed to fetch roles. Caregiver or patient role is null.");
        showToast("Failed to add task. Roles not found.", 
            backgroundColor: AppColors.red);
        return;
      }

      // Save the medicine for the patient
      await medicineUtility.saveMedicine(
        userId: widget.patientId,
        medicineId: medicineId,
        collectionName: patientRole,
        subCollectionName: 'medicines',
        medicineTitle: medicineName,
        dosage: dosage,
        usage: frequency,
      );

      // Save the medicine for the caregiver
      await medicineUtility.saveMedicine(
        userId: caregiverId,
        medicineId: medicineId,
        collectionName: caregiverRole,
        subCollectionName: 'medicines',
        medicineTitle: medicineName,
        dosage: dosage,
        usage: frequency,
      );

      await _logService.addLog(
        userId: caregiverId,
        action: "Added Medicine $medicineName to patient $patientName",
      );
      refreshValues();
      _fetchPatientMedicines();

      showToast("Medicine added successfully");
    } catch (e) {
      debugPrint("Error adding medicine: $e");

      showToast("Failed to add prescription: $e", 
          backgroundColor: AppColors.red);
    }
  }

  Future<void> _removeMedicine(
    String patientId,
    String medicineId,
    String caregiverId,
  ) async {
    try {
      // Fetch the roles for both caregiver and patient
      final caregiverRole = await databaseService.fetchAndCacheUserRole(
        caregiverId,
      );
      final patientRole = await databaseService.fetchAndCacheUserRole(
        patientId,
      );

      // Check if the roles were successfully fetched
      if (caregiverRole == null || patientRole == null) {
        debugPrint("Failed to fetch roles. Caregiver or patient role is null.");
        showToast("Failed to remove medicine. Roles not found.", 
            backgroundColor: AppColors.red);
        return;
      }

      // Remove the task for the patient
      await medicineUtility.removeMedicine(
        userId: patientId,
        medicineId: medicineId,
        collectionName: patientRole,
        subCollectionName: 'medicines',
      );

      // Remove the task for the caregiver
      await medicineUtility.removeMedicine(
        userId: caregiverId,
        medicineId: medicineId,
        collectionName: caregiverRole,
        subCollectionName: 'medicines',
      );

      await _logService.addLog(
        userId: caregiverId,
        action:
            "Removed Medicine ${getMedicineNameById(medicineId)} from patient $patientName",
      );

      showToast('Medicine deleted successfully');
      refreshValues();
      _fetchPatientMedicines();
    } catch (e) {
      debugPrint("Error removing medicine: $e");

      showToast('Failed to delete medicine: $e', 
          backgroundColor: AppColors.red);
    }
  }

  void _showAddMedicineDialog() {
    List<String> allMedicines = []; // List to store fetched medicines
    String selectedMedicine = ''; // Selected medicine from the dropdown

    // Fetch medicines from Firestore
    Future<void> _fetchGlobalMedicines() async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('globals')
            .doc('medicines')
            .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['medicines'] is List) {
            allMedicines = List<String>.from(data['medicines']);
            allMedicines.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          }
        }
      } catch (e) {
        debugPrint('Error fetching global medicines: $e');
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FutureBuilder(
          future: _fetchGlobalMedicines(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

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
                        Text("Add Prescription", style: Textstyle.subheader),
                        const SizedBox(height: 20),

                        // Medicine Name Dropdown/Search Field
                        DropdownButtonFormField<String>(
                          value: selectedMedicine.isNotEmpty ? selectedMedicine : null,
                          decoration: InputDecoration(
                            labelText: "Medicine Name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: allMedicines.map((medicine) {
                            return DropdownMenuItem<String>(
                              value: medicine,
                              child: Text(medicine),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              selectedMedicine = value ?? '';
                            });
                          },
                          onSaved: (value) {
                            selectedMedicine = value ?? '';
                          },
                          isExpanded: true,
                          dropdownColor: AppColors.white,
                        ),
                        const SizedBox(height: 10),

                        // Dosage and Unit Fields
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: CustomTextField(
                                controller: _dosageController,
                                focusNode: _focusNodes[1],
                                labelText: "Dosage",
                                keyboardType: TextInputType.number,
                                enabled: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                                  LengthLimitingTextInputFormatter(6)
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: CustomDropdownField<String>(
                                value: dosageUnit,
                                focusNode: _focusNodes[2],
                                labelText: "Unit",
                                items: ["milligrams", "grams", "milliliters", "micrograms"],
                                onChanged: (value) => setModalState(() {
                                  dosageUnit = value ?? dosageUnit;
                                }),
                                displayItem: (item) => item,
                                enabled: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Usage Field
                        CustomTextField(
                          controller: _usageController,
                          focusNode: _focusNodes[3],
                          maxLines: 3,
                          labelText: "Usage",
                          enabled: true,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(200)
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: Buttonstyle.buttonRed,
                                child: Text("Cancel", style: Textstyle.smallButton),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  String dosage = _dosageController.text.trim();
                                  String usage = _usageController.text.trim();

                                  if (selectedMedicine.isEmpty) {
                                    showToast("Please provide the name of the medicine.", backgroundColor: AppColors.red);
                                  } else if (dosage.isEmpty) {
                                    showToast("Please provide the dosage amount.", backgroundColor: AppColors.red);
                                  } else if (num.parse(dosage) > 100000) {
                                    showToast("The dosage you entered is too high!", backgroundColor: AppColors.red);
                                  } else if (usage.isEmpty) {
                                    showToast("Please provide your instructed prescription usage.", backgroundColor: AppColors.red);
                                  } else {
                                    _addMedicine(
                                      selectedMedicine,
                                      "${_dosageController.text} $dosageUnit",
                                      _usageController.text,
                                    );
                                    Navigator.pop(context);
                                  }
                                },
                                style: Buttonstyle.buttonNeon,
                                child: Text(
                                  "Prescribe",
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text("View Prescriptions", style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : medicines.isEmpty
              ? _buildNoMedicineState()
              : _buildMedicineList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicineDialog,
        backgroundColor: AppColors.neon,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Prescription'),
      ),
    );
  }

  Widget _buildMedicineList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
        decoration: BoxDecoration(
          color: AppColors.gray,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      medicineName,
                      style: Textstyle.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      dosage,
                      style: Textstyle.bodySmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
            // Description
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(usage, style: Textstyle.body),
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
            "No Prescriptions Yet",
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
                          'Cancel',
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
                          'Delete',
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
