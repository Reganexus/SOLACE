import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientMedicine extends StatefulWidget {
  const PatientMedicine({super.key, required this.currentUserId});
  final String currentUserId;

  @override
  PatientMedicineState createState() => PatientMedicineState();
}

class PatientMedicineState extends State<PatientMedicine> {
  List<Map<String, dynamic>> medicines = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchPatientMedicine();
  }

  Future<void> fetchPatientMedicine() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String patientId = widget.currentUserId; // Use the passed user ID
      try {
        // Query the 'caregiver' collection for the document of the current user
        final snapshot = await FirebaseFirestore.instance
            .collection(
                'caregiver') // Assuming tasks are stored in the 'caregiver' collection
            .doc(patientId) // Fetch the specific caregiver document
            .get();

        debugPrint("Snapshot: $snapshot");

        if (snapshot.exists) {
          // Extract the tasks from the document
          final List<dynamic> medicineData = snapshot.data()?['medicine'] ??
              []; // Assuming 'tasks' is an array in the document
          debugPrint("Medicine Data: $medicineData");
          if (medicineData.isEmpty) {
            // No tasks available, handle it here
            setState(() {
              _isLoading = false;
              medicines = []; // Clear any previously fetched tasks
            });
            return;
          }

          // Process the tasks data
          final List<Map<String, dynamic>> medicineList = [];
          for (var medicine in medicineData) {
            medicineList.add({
              'id': medicine['id'], // Assuming task has an 'id' field
              'title': medicine['title'] ??
                  'No Medicine Title', // Assuming task has a 'title' field
              'dosage': medicine['dosage'] ??
                  'No Dosage', // Default description if null
              'usage': medicine['usage'] ?? 'No Usage',
              'isCompleted': medicine['isCompleted'],
            });
          }

          debugPrint("Medicine List: $medicineList");

          // Update the state with the fetched tasks
          setState(() {
            medicines = medicineList; // Assign tasks to your state variable
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No tasks found for the user.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch tasks: $e';
        });
      }
    }
  }

  void _showMedicineModal(
    BuildContext context,
    String medicineTitle,
    String dosage,
    String usage,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            medicineTitle,
            style: const TextStyle(
              fontSize: 24,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dosage: $dosage',
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black),
              ),
              const SizedBox(height: 10),
              Text(
                'Usage: $usage',
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  backgroundColor: AppColors.neon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
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
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : medicines.isEmpty
                    ? _buildNoTasksState()
                    : ListView.builder(
                        itemCount: medicines.length,
                        itemBuilder: (context, index) {
                          // Safely check if the values exist
                          final medicine = medicines[index];
                          final taskTitle =
                              medicine['title'] ?? 'No Medicine Title';
                          final dosage = medicine['dosage'] ?? 'No Dosage';
                          final usage = medicine['usage'] ?? 'No Usage';

                          if (taskTitle == null) {
                            // If task title or icon is null, skip this task
                            return SizedBox.shrink();
                          }

                          return GestureDetector(
                            onTap: () {
                              _showMedicineModal(
                                  context, taskTitle, dosage, usage);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 15.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: AppColors
                                    .gray, // Or whatever background color you want
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20.0, horizontal: 15.0),
                              child: Row(
                                children: [
                                  Text(
                                    taskTitle,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Outfit',
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
          const Icon(
            Icons.error_outline,
            color: AppColors.black,
            size: 80,
          ),
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
            onPressed: fetchPatientMedicine,
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

  Widget _buildNoTasksState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.black,
            size: 80,
          ),
          SizedBox(height: 20.0),
          Text(
            "No medicines available",
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
