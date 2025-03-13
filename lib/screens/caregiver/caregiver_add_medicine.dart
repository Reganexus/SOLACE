// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, no_leading_underscores_for_local_identifiers, unnecessary_null_comparison, avoid_print, unnecessary_string_interpolations, prefer_final_fields

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';

class ViewPatientMedicine extends StatefulWidget {
  final String patientId;

  const ViewPatientMedicine({
    super.key,
    required this.patientId,
  });

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
    _focusNodes = List.generate(3, (index) => FocusNode());
    databaseService = DatabaseService();
    _loadMedicines();
  }

  @override
  void dispose() {
    // Dispose focus nodes to prevent memory leaks
    for (var node in _focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  Future<void> _loadMedicines() async {
    print("Fetching medicines for patient: ${widget.patientId}");

    try {
      if (mounted) {
        setState(() {
          isLoading = true; // Show loading indicator
        });
      }

      final patientDoc = await FirebaseFirestore.instance
          .collection('patient')
          .doc(widget.patientId)
          .get();

      if (patientDoc.exists) {
        if (mounted) {
          setState(() {
            medicines = List<Map<String, dynamic>>.from(
                patientDoc.data()?['medicine'] ?? []);
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            medicines = [];
            isLoading = false;
          });
        }
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
      String title,
      String dosage,
      String usage,
      ) async {
    try {
      String doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (doctorId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No doctor logged in.")),
        );
        return;
      }

      // Capitalize inputs
      String capitalize(String input) {
        return input.isNotEmpty
            ? input[0].toUpperCase() + input.substring(1).toLowerCase()
            : input;
      }

      title = capitalize(title);
      dosage = capitalize(dosage);
      usage = capitalize(usage);

      // Generate a unique medicine ID
      String medicineId =
          '${doctorId}_${Timestamp.now().seconds}_${widget.patientId}';

      // Save the medicines for the patient
      await databaseService.saveMedicineForPatient(
        widget.patientId,
        medicineId,
        title,
        dosage,
        usage,
        doctorId,
      );

      // Save the medicine for the doctor
      await databaseService.saveMedicineForDoctor(
        doctorId,
        medicineId,
        title,
        dosage,
        usage,
        widget.patientId,
      );

      // Reload medicine after saving the new one
      _loadMedicines();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Medicine added successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add medicine: $e")),
      );
    }
  }


  Future<void> _removeMedicine(String patientId, String medicineId) async {
    try {
      debugPrint("Patient ID: $patientId");
      debugPrint("Medicine ID: $medicineId");

      // Fetch the patient document to get the list of medicine
      final patientDoc = await FirebaseFirestore.instance
          .collection('patient')
          .doc(patientId)
          .get();

      if (!patientDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Patient not found")),
        );
        return;
      }

      // Get the list of medicine from the patient document
      final medicineList =
          List<Map<String, dynamic>>.from(patientDoc.data()?['medicine'] ?? []);

      // Find the medicine to remove by medicineId, return an empty map if not found
      final medicineToRemove = medicineList.firstWhere(
        (medicine) => medicine['id'] == medicineId,
        orElse: () => {}, // Return an empty map if the medicine is not found
      );

      if (medicineToRemove.isEmpty) {
        debugPrint("Medicine with ID $medicineId not found");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Medicine not found")),
        );
        return;
      }

      // Remove the medicine from the Firestore array
      await FirebaseFirestore.instance
          .collection('patient')
          .doc(patientId)
          .update({
        'medicine': FieldValue.arrayRemove([medicineToRemove]),
      });

      // Show a snackbar to notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('medicine removed successfully!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Error removing medicine: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _showAddMedicineDialog() {
    String medicineTitle = '';
    String dosage = '';
    String usage = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return AlertDialog(
                  backgroundColor: AppColors.white,
                  title: Text(
                    "Add Medicine",
                    style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  content: SizedBox(
                    width: constraints.maxWidth * 0.9, // Adjust width here
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Medicine Title Field
                          TextFormField(
                            onChanged: (value) => medicineTitle = value,
                            focusNode:
                                _focusNodes[0], // Focus for medicine Title
                            decoration: InputDecoration(
                              labelText: "Medicine Title",
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
                                color: _focusNodes[0].hasFocus
                                    ? AppColors.neon
                                    : AppColors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Medicine Description Field
                          TextFormField(
                            onChanged: (value) => dosage = value,
                            focusNode: _focusNodes[
                                1], // Focus for Medicine Description
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
                                color: _focusNodes[1].hasFocus
                                    ? AppColors.neon
                                    : AppColors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            onChanged: (value) => usage = value,
                            focusNode: _focusNodes[
                                2], // Focus for Medicine Description
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
                                color: _focusNodes[2].hasFocus
                                    ? AppColors.neon
                                    : AppColors.black,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 20.0,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 5),
                                    backgroundColor: AppColors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 10.0,
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    if (medicineTitle.isNotEmpty &&
                                        dosage.isNotEmpty &&
                                        usage.isNotEmpty) {
                                      _addMedicine(
                                        medicineTitle,
                                        dosage,
                                        usage,
                                      );
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text("Invalid inputs!")),
                                      );
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 5),
                                    backgroundColor: AppColors.neon,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    "Add",
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.white,
                                    ),
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

  Future<void> fetchPatientMedicines() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patient')
          .doc(widget.patientId) // Use the patientId passed to the widget
          .get();

      if (snapshot.exists) {
        final List<dynamic> medicineData = snapshot.data()?['medicine'] ?? [];
        final List<Map<String, dynamic>> filteredMedicine = [];

        for (var medicine in medicineData) {
          // Extract medicine details, handle missing fields
          final String medicineId = medicine['id'] ?? '';
          final String title = medicine['title'] ?? 'Untitled Medicine';
          final String dosage = medicine['dosage'] ?? 'No dosage';
          final String usage = medicine['usage'] ?? 'No usage';

          // Add the extracted data to the filteredMedicine list
          filteredMedicine.add({
            'id': medicineId,
            'title': title,
            'dosage': dosage,
            'usage': usage,
          });
        }

        if (mounted) {
          setState(() {
            medicines = filteredMedicine;
          });
        }
      } else {
        debugPrint("No document found for patientId: ${widget.patientId}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch medicines: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Stream<DocumentSnapshot> _getPatientMedicineStream(String patientId) {
    return Stream<DocumentSnapshot>.multi((controller) async {
      debugPrint("Searching in for patientId: $patientId");
      final snapshots = FirebaseFirestore.instance
          .collection("patient")
          .doc(patientId)
          .snapshots();

      await for (final snapshot in snapshots) {
        if (snapshot.exists) {
          debugPrint("Document found: ${snapshot.data()}");
          controller.add(snapshot);
          return; // Exit after emitting the first valid snapshot
        }
      }

      // If no document is found, add an error
      debugPrint("Patient not found for patientId: $patientId");
      controller.addError('Patient not found in the patient collection.');
    });
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
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _getPatientMedicineStream(widget.patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint("Error: ${snapshot.error}");
            return const Center(child: Text("Error fetching tasks"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final medicines =
              List<Map<String, dynamic>>.from(data['medicine'] ?? []);

          // If the tasks list is empty
          if (medicines.isEmpty) {
            return _buildNoMedicineState();
          }

          // If the medicines list is empty
          if (medicines.isEmpty) {
            return Center(
              child: Text(
                "No medicines available",
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final medicine = medicines[index];
                final String title = medicine['title'] ?? 'Untitled Medicine';
                final String dosage = medicine['dosage'] ?? 'No Dosage';
                final String usage = medicine['usage'] ?? 'No Usage';
                final String medicineId = medicine[
                    'id']; // Extract the medicineId from the medicine data

                return GestureDetector(
                  onTap: () {
                    // Show the alert dialog modal when the container is tapped
                    showDialog(
                      context: context,
                      builder: (context) => LayoutBuilder(
                        builder: (context, constraints) {
                          return AlertDialog(
                            backgroundColor: AppColors.white,
                            contentPadding: const EdgeInsets.all(20.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 10.0),

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
                                const SizedBox(height: 20.0),

                                // Buttons Section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () async {
                                          await _removeMedicine(
                                              widget.patientId, medicineId);
                                          Navigator.of(context).pop();
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 5),
                                          backgroundColor: AppColors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
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

                                    // Close Button
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 5),
                                          backgroundColor: AppColors.neon,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                          );
                        },
                      ),
                    );
                  },
                  child: Card(
                    color: AppColors.white,
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          10.0), // Apply border radius to the Container
                      child: Container(
                        color: AppColors.gray,
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.medical_services,
                                  size: 30,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(thickness: 1.0),
                            const SizedBox(height: 10),
                            const Text(
                              "Dosage",
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(dosage, style: TextStyle(fontSize: 16)),
                            SizedBox(height: 20),
                            const Text(
                              "Usage",
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(usage, style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neon,
        onPressed: _showAddMedicineDialog,
        child: Icon(
          Icons.add,
          color: AppColors.white,
        ),
      ),
    );
  }

  Widget _buildNoMedicineState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.error_outline_outlined,
            color: AppColors.black,
            size: 80,
          ),
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
}
