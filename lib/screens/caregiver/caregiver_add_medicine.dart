// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, no_leading_underscores_for_local_identifiers, unnecessary_null_comparison, avoid_print, unnecessary_string_interpolations, prefer_final_fields

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/controllers/notification_service.dart';
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
  final NotificationService notificationService = NotificationService();
  DatabaseService databaseService = DatabaseService();
  MedicineUtility medicineUtility = MedicineUtility();
  List<Map<String, dynamic>> medicines = [];
  List<FocusNode> _focusNodes = [];
  bool isLoading = true;

  TextEditingController _dosageController = TextEditingController();
  TextEditingController _usageController = TextEditingController();
  String dosageUnit = "milligrams";
  String frequency = "Once daily";
  late String patientName = '';

  @override
  void initState() {
    super.initState();
    _fetchPatientMedicines();
    _loadPatientName();
    _focusNodes = List.generate(5, (index) => FocusNode());
  }

  @override
  void dispose() {
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
  }

  void refreshValues() {
    setState(() {
      _dosageController.clear();
      _usageController.clear();
      dosageUnit = "milligrams"; // Reset dosage unit to default
      frequency = "Once daily"; // Reset frequency to default
    });
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

  String getMedicineNameById(String medicineId) {
    final medicine = medicines.firstWhere(
      (med) => med['medicineId'] == medicineId,
      orElse:
          () => {'medicineName': 'Unknown Medicine'}, // Default if not found
    );
    return medicine['medicineName'] ?? 'Unknown Medicine';
  }

  Future<void> _fetchPatientMedicines() async {
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
                final frequency = data['frequency'] ?? 'No Frequency';
                final usage = data['usage'] ?? 'No Usage';

                return {
                  'medicineId': doc.id,
                  'medicineName': medicineName,
                  'dosage': dosage,
                  'frequency': frequency,
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
      //     debugPrint("Error loading medicine: $e");
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
    String usage,
  ) async {
    try {
      // Get the caregiver ID (logged-in user)
      String caregiverId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (caregiverId.isEmpty) {
        showToast("No doctor logged in.", backgroundColor: AppColors.red);
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

      String medicineId = FirebaseFirestore.instance.collection('_').doc().id;

      final caregiverRole = await databaseService.fetchAndCacheUserRole(
        caregiverId,
      );
      final patientRole = await databaseService.fetchAndCacheUserRole(
        widget.patientId,
      );

      if (caregiverRole == null || patientRole == null) {
        showToast(
          "Failed to add task. Roles not found.",
          backgroundColor: AppColors.red,
        );
        return;
      }

      await medicineUtility.saveMedicine(
        userId: widget.patientId,
        medicineId: medicineId,
        collectionName: patientRole,
        subCollectionName: 'medicines',
        medicineTitle: medicineName,
        dosage: dosage,
        frequency: frequency,
        usage: usage,
      );

      final String role =
          '${caregiverRole.substring(0, 1).toUpperCase()}${caregiverRole.substring(1)}';
      final String? name = await databaseService.fetchUserName(caregiverId);

      await notificationService.sendInAppNotificationToTaggedUsers(
        patientId: widget.patientId,
        currentUserId: caregiverId,
        notificationMessage:
            "$role $name prescribed $dosage of $medicineName $frequency to patient $patientName.",
        type: "medicine",
      );

      await notificationService.sendNotificationToTaggedUsers(
        widget.patientId,
        "Medicine Prescription Notice",
        "$role $name prescribed $dosage of $medicineName $frequency to patient $patientName.",
      );

      await _logService.addLog(
        userId: caregiverId,
        relatedUsers: widget.patientId,
        action:
            "$role $name prescribed $dosage of $medicineName $frequency to patient $patientName.",
      );

      refreshValues();
      _fetchPatientMedicines();

      showToast("Medicine added successfully");
    } catch (e) {
      //       debugPrint("Error adding medicine: $e");

      showToast(
        "Failed to add prescription: $e",
        backgroundColor: AppColors.red,
      );
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
        //         debugPrint("Failed to fetch roles. Caregiver or patient role is null.");
        showToast(
          "Failed to remove medicine. Roles not found.",
          backgroundColor: AppColors.red,
        );
        return;
      }

      // Remove the task for the patient
      await medicineUtility.removeMedicine(
        userId: patientId,
        medicineId: medicineId,
        collectionName: patientRole,
        subCollectionName: 'medicines',
      );

      final String medicineName = getMedicineNameById(medicineId);
      final String role =
          '${caregiverRole.substring(0, 1).toUpperCase()}${caregiverRole.substring(1)}';
      final String? name = await databaseService.fetchUserName(caregiverId);

      await _logService.addLog(
        userId: caregiverId,
        action: "Removed Medicine $medicineName from patient $patientName",
      );

      await notificationService.sendInAppNotificationToTaggedUsers(
        patientId: widget.patientId,
        currentUserId: caregiverId,
        notificationMessage:
            "$role $name removed $medicineName prescription from patient $patientName.",
        type: "medicine",
      );

      await notificationService.sendNotificationToTaggedUsers(
        widget.patientId,
        "Medicine Prescription Notice",
        "$role $name removed $medicineName prescription from patient $patientName.",
      );

      showToast('Medicine deleted successfully');
      refreshValues();
      _fetchPatientMedicines();
    } catch (e) {
      //       debugPrint("Error removing medicine: $e");

      showToast(
        'Failed to delete medicine: $e',
        backgroundColor: AppColors.red,
      );
    }
  }

  // Helper function to capitalize sentences
  String _capitalizeSentences(String text) {
    return text
        .split('. ')
        .map((sentence) {
          return sentence.isNotEmpty
              ? sentence[0].toUpperCase() + sentence.substring(1)
              : sentence;
        })
        .join('. ');
  }

  void _showAddMedicineDialog() {
    List<String> allMedicines = [];
    String selectedMedicine = '';
    bool isLoading = false;
    bool isAddingMedicine = false;

    Future<List<String>> _fetchGlobalMedicines() async {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('globals')
                .doc('medicines')
                .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['medicines'] is List) {
            final List<String> medicines =
                List<String>.from(data['medicines']).toSet().toList()
                  ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
            return medicines;
          }
        }
      } catch (e) {
        debugPrint('Error fetching global medicines: $e');
      }
      return [];
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FutureBuilder<List<String>>(
          future: _fetchGlobalMedicines(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading medicines: ${snapshot.error}'),
              );
            }

            allMedicines = snapshot.data ?? [];

            return StatefulBuilder(
              builder: (context, setModalState) {
                return Dialog(
                  child: SingleChildScrollView(
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
                          Text(
                            "Fields marked with * are required.",
                            style: Textstyle.body,
                          ),
                          const SizedBox(height: 20),
                          CustomDropdownField<String>(
                            enabled: !isLoading && !isAddingMedicine,
                            value:
                                allMedicines.contains(selectedMedicine)
                                    ? selectedMedicine
                                    : null,
                            focusNode: _focusNodes[0],
                            labelText: "Medicine Name *",
                            items: allMedicines,
                            onChanged:
                                (value) => setModalState(() {
                                  selectedMedicine = value ?? '';
                                }),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? "Please select a medicine"
                                        : null,
                            displayItem: (medicine) => medicine,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: CustomTextField(
                                  controller: _dosageController,
                                  focusNode: _focusNodes[1],
                                  labelText: "Dosage *",
                                  keyboardType: TextInputType.number,
                                  enabled: !isLoading && !isAddingMedicine,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*$'),
                                    ),
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: CustomDropdownField<String>(
                                  value: dosageUnit,
                                  focusNode: _focusNodes[2],
                                  labelText: "Unit *",
                                  items: const [
                                    "milligrams",
                                    "grams",
                                    "milliliters",
                                    "micrograms",
                                    "kilograms",
                                  ],
                                  onChanged:
                                      (value) => setModalState(() {
                                        dosageUnit = value ?? dosageUnit;
                                      }),
                                  displayItem: (item) => item,
                                  enabled: !isLoading && !isAddingMedicine,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: CustomDropdownField<String>(
                                  value: frequency,
                                  focusNode: _focusNodes[3],
                                  labelText: "Frequency *",
                                  items: const [
                                    "Once daily",
                                    "Twice daily (every 12 hours)",
                                    "Three times daily (every 8 hours)",
                                    "Every 6 hours",
                                    "Every 4 hours",
                                    "Once a week",
                                    "As needed (PRN)",
                                    "Custom (specify in instructions)",
                                  ],
                                  onChanged:
                                      (value) => setModalState(() {
                                        frequency = value ?? frequency;
                                      }),
                                  displayItem: (item) => item,
                                  enabled: !isLoading && !isAddingMedicine,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: _usageController,
                            focusNode: _focusNodes[4],
                            maxLines: 3,
                            labelText: "Instructions *",
                            enabled: !isLoading && !isAddingMedicine,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(200),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed:
                                      isLoading || isAddingMedicine
                                          ? null
                                          : () => Navigator.pop(context),
                                  style:
                                      isLoading || isAddingMedicine
                                          ? Buttonstyle.buttonGray
                                          : Buttonstyle.buttonRed,
                                  child: Text(
                                    "Cancel",
                                    style: Textstyle.smallButton,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextButton(
                                  onPressed:
                                      isAddingMedicine
                                          ? null
                                          : () async {
                                            setModalState(() {
                                              isLoading = true;
                                            });

                                            final String dosage =
                                                _dosageController.text.trim();
                                            final String usage =
                                                _usageController.text.trim();

                                            if (selectedMedicine.isEmpty) {
                                              showToast(
                                                "Please provide the name of the medicine.",
                                                backgroundColor: AppColors.red,
                                              );
                                            } else if (dosage.isEmpty) {
                                              showToast(
                                                "Please provide the dosage amount.",
                                                backgroundColor: AppColors.red,
                                              );
                                            } else if (num.parse(dosage) >
                                                100000) {
                                              showToast(
                                                "The dosage you entered is too high!",
                                                backgroundColor: AppColors.red,
                                              );
                                            } else if (usage.isEmpty) {
                                              showToast(
                                                "Please provide your instructed prescription.",
                                                backgroundColor: AppColors.red,
                                              );
                                            } else {
                                              final bool confirmAdd =
                                                  await _showMedicineConfirmationDialog(
                                                    selectedMedicine,
                                                    dosage,
                                                    dosageUnit,
                                                    usage,
                                                  );

                                              if (confirmAdd) {
                                                setModalState(() {
                                                  isAddingMedicine = true;
                                                });
                                                final String
                                                capitalizedMedicine =
                                                    _capitalizeSentences(
                                                      selectedMedicine,
                                                    );
                                                final String capitalizedUsage =
                                                    _capitalizeSentences(usage);

                                                await _addMedicine(
                                                  capitalizedMedicine,
                                                  "$dosage $dosageUnit",
                                                  frequency,
                                                  capitalizedUsage,
                                                );
                                                if (mounted) {
                                                  Navigator.pop(context);
                                                }
                                              }
                                            }

                                            setModalState(() {
                                              isLoading = false;
                                            });
                                          },
                                  style: Buttonstyle.buttonNeon,
                                  child:
                                      isAddingMedicine
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                          : Text(
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
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _showMedicineConfirmationDialog(
    String medicineName,
    String dosage,
    String dosageUnit,
    String usage,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text("Confirm Medicine Addition", style: Textstyle.subheader),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Are you sure you want to submit the following information for this prescription?",
                style: Textstyle.body,
              ),
              SizedBox(height: 20),
              Text(
                "Medicine",
                style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(medicineName, style: Textstyle.body),
              SizedBox(height: 10),
              Text(
                "Dosage",
                style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
              ),
              Text('$dosage $dosageUnit', style: Textstyle.body),
              SizedBox(height: 10),
              Text(
                "Frequency",
                style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(frequency, style: Textstyle.body),
              SizedBox(height: 10),
              Text(
                "Instructions",
                style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(usage, style: Textstyle.body),
            ],
          ),
          actions: <Widget>[
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: Buttonstyle.buttonRed,
                    child: Text("Cancel", style: Textstyle.smallButton),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: Buttonstyle.buttonNeon,
                    child: Text("Confirm", style: Textstyle.smallButton),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ).then((result) => result ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text("Prescriptions", style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        centerTitle: true,
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
        label: Text(
          'Add Prescription',
          style: Textstyle.smallButton.copyWith(fontWeight: FontWeight.bold),
        ),
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
    final String frequency = medicine['frequency'] ?? 'No Frequency';
    final String usage = medicine['usage'] ?? 'No Instruction';

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Frequency Text
                  Text(
                    frequency,
                    style: Textstyle.body.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 5),
                  // Usage Text
                  Text(usage, style: Textstyle.body),
                ],
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
    final String medicineName = medicine['medicineName'] ?? 'Untitled Medicine';
    final String medicineId = medicine['medicineId'] ?? '';
    bool _isRemovingMedicine = false; // State for tracking removal

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      "Do you want to remove this prescription?",
                      style: Textstyle.body,
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed:
                                _isRemovingMedicine
                                    ? null // Disable button while removing
                                    : () {
                                      Navigator.of(context).pop();
                                    },
                            style:
                                _isRemovingMedicine
                                    ? Buttonstyle.buttonGray
                                    : Buttonstyle.buttonNeon,
                            child: Text('Cancel', style: Textstyle.smallButton),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: TextButton(
                            onPressed:
                                _isRemovingMedicine
                                    ? null // Disable button while removing
                                    : () async {
                                      if (medicineId.isNotEmpty) {
                                        setState(() {
                                          _isRemovingMedicine =
                                              true; // Set removing state
                                        });
                                        String caregiverId =
                                            FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.uid ??
                                            '';
                                        await _removeMedicine(
                                          widget.patientId,
                                          medicineId,
                                          caregiverId,
                                        );
                                        if (mounted) {
                                          Navigator.of(
                                            context,
                                          ).pop(); // Close dialog
                                        }
                                      }
                                    },
                            style: Buttonstyle.buttonRed,
                            child:
                                _isRemovingMedicine
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Text(
                                      'Delete',
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
  }
}
