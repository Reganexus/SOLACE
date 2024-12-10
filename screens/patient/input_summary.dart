// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/globals.dart';
import 'package:solace/themes/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReceiptScreen extends StatefulWidget {
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> algoInputs;
  final String uid;
  final Function resetInputsCallback;

  const ReceiptScreen({
    super.key,
    required this.uid,
    required this.inputs,
    required this.algoInputs,
    required this.resetInputsCallback,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _identifySymptoms() async {
    List<String> symptoms = [];

    // Clear symptoms in Firestore
    try {
      await _firestore.collection('users').doc(widget.uid).update({
        'symptoms': [],
      });
      debugPrint('Symptoms list cleared successfully.');
    } catch (e) {
      debugPrint('Error clearing symptoms list: $e');
    }

    // Analyze vital inputs
    Map<String, String> vitals =
        Map<String, String>.from(widget.inputs['Vitals']);
    vitals.forEach((key, value) {
      if (value.isEmpty) return;

      double vitalValue = 0;
      try {
        if (key != 'Blood Pressure') {
          vitalValue = double.parse(value);
        } else {}
      } catch (e) {
        debugPrint('$key value is invalid');
        return;
      }

      switch (key) {
        case 'Heart Rate':
          if (vitalValue < minHeartRate) {
            symptoms.add('Low Heart rRate');
          } else if (vitalValue > maxHeartRate) {
            symptoms.add('High Heart Rate');
          }
          break;

        case 'Oxygen Saturation':
          if (vitalValue < minOxygenSaturation) {
            symptoms.add('Low Oxygen Saturation');
          }
          break;

        case 'Respiration':
          if (vitalValue < minRespirationRate) {
            symptoms.add('Low Respiration Rate');
          } else if (vitalValue > maxRespirationRate) {
            symptoms.add('High Respiration Rate');
          }
          break;

        case 'Temperature':
          if (vitalValue < minTemperature) {
            symptoms.add('Low Temperature');
          } else if (vitalValue > maxTemperature) {
            symptoms.add('High Temperature');
          }
          break;

        case 'Blood Pressure':
          final parts = value.split('/');
          final systolic = int.tryParse(parts[0]);
          final diastolic = int.tryParse(parts[1]);
          if (systolic! > normalBloodPressureSystolic ||
              diastolic! > normalBloodPressureDiastolic) {
            symptoms.add('High Blood Pressure');
          } else if (systolic < normalBloodPressureSystolic &&
              diastolic < normalBloodPressureDiastolic) {
            symptoms.add('Low Blood Pressure');
          }
          break;

        case 'Cholesterol Level':
          if (vitalValue > highCholesterol) {
            symptoms.add('High Cholesterol Level');
          }
          break;

        case 'Pain':
          if (vitalValue > maxScale) {
            symptoms.add('Pain');
          }
          break;

        default:
          debugPrint('$key: Unable to determine status');
      }
    });

    // Analyze symptom inputs
    Map<String, int> symptomAssessment =
        Map<String, int>.from(widget.inputs['Symptom Assessment']);

    // Remove symptoms with a value of 0
    symptomAssessment
        .removeWhere((key, value) => value == 0 || key == 'Well-being');
    // Sort symptoms in descending order by value
    List<MapEntry<String, int>> sortedSymptoms = symptomAssessment.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedSymptoms) {
      symptoms.add(entry.key);
    }

    _updateFireStoreSymptoms(symptoms);
    _submitAlgoInputs(widget.uid);
  }

  void _updateFireStoreSymptoms(List<String> symptoms) async {
    try {
      await _firestore.collection('users').doc(widget.uid).update({
        'symptoms': FieldValue.arrayUnion(symptoms),
      });
      debugPrint('Identified symptoms successfully updated in Firestore');

      String status = '';
      if (symptoms.isEmpty) {
        status = 'stable';
        debugPrint('Status set to stable');
      } else {
        status = 'unstable';
        debugPrint('Status set to stable');
      }
      await _firestore.collection('users').doc(widget.uid).update({
        'status': status,
      });
    } catch (e) {
      debugPrint('Error updating Firestore: $e');
    }
  }

  void _submitAlgoInputs(String uid) async {
    final userData = await DatabaseService(uid: uid).getUserData();
    if (userData == null) {
      debugPrint('Submit Algo Input No User Data');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No User Data'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      try {
        // Convert mapped algo inputs to a list
        List<dynamic> algoInputs = widget.algoInputs.values.toList();
        debugPrint('Tracking algo inputs: $algoInputs');
<<<<<<< Updated upstream
        
=======

        // If there are fewer than 10 inputs, repeat the last one
        if (widget.algoInputs.length < 10) {
          final latestInput =
              widget.algoInputs.isNotEmpty ? algoInputs.last : widget.inputs;
          while (algoInputs.length < 10) {
            algoInputs.add(latestInput);
          }
        }

>>>>>>> Stashed changes
        // Send the inputs for prediction
        await getPrediction(algoInputs);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Handle any unexpected errors
        debugPrint("Unexpected error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> getPrediction(List<dynamic> algoInputs) async {
    // choose from these depending on testing device
    // final localHostAddress = '127.0.0.1'; // default
    final virtualAddress = '10.0.2.2'; // if using virtual device
    // if using physical device, use computer’s IP address instead of 127.0.0.1 or localhost.

    final url = Uri.parse('http://$virtualAddress:5000/predict');
    final headers = {"Content-Type": "application/json"};

    // Define mappings for Blood Pressure and Cholesterol Level
    const severityMapping = {
      "Low": 0,
      "Normal": 1,
      "High": 2,
    };

    // Format algoInputs to match the input size expected by the model (8 features)
    List<int>? formattedInputs;
    try {
      formattedInputs = [
        algoInputs[0] == true ? 1 : 0, // Fever
        algoInputs[1] == true ? 1 : 0, // Cough
        algoInputs[2] == true ? 1 : 0, // Fatigue
        algoInputs[3] == true ? 1 : 0, // Difficulty Breathing
        (algoInputs[4] ?? 0) as int, // Age
        algoInputs[5] == 'Male' ? 1 : 0, // Gender
        severityMapping[algoInputs[6]] ?? 0, // Blood Pressure
        severityMapping[algoInputs[7]] ?? 0, // Cholesterol Level
      ];

      debugPrint('Formatted Inputs: $formattedInputs');
    } catch (e, stackTrace) {
      debugPrint('Error formatting inputs: $e');
      debugPrint('StackTrace: $stackTrace');
    }

    try {
      // Wrap formattedInputs in a JSON object with the 'data' key
      final body = json.encode({
        'data': [formattedInputs]
      });

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      debugPrint("Json body: $body");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint(
            "Status: ${responseData['prediction']}  Type: ${(responseData['prediction']).runtimeType}");
        // set status to either stable or unstable here
        if(responseData['prediction'][0] == 0) {
          debugPrint('Prediction: Negative (No complications detected based on algo)');
        } else {
          debugPrint('Prediction: Positive (Complications detected based on algo but not specified what)');
        }
      } else {
        debugPrint("Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("wowow Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Summary'),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Assessment',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                'Vitals:',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              if (widget.inputs.containsKey('Vitals'))
                ...widget.inputs['Vitals'].entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${entry.key}:',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              const SizedBox(height: 20.0),
              Text(
                'Symptom Assessment:',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 10.0),
              if (widget.inputs.containsKey('Symptom Assessment'))
                ...widget.inputs['Symptom Assessment'].entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${entry.key}:',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              const SizedBox(height: 20),
              const Divider(thickness: 1.0),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () async {
                    try {
                      // Identify current symptoms based on inputs and save it in FireStore
                      _identifySymptoms();

                      // Get the current timestamp
                      final timestamp = Timestamp.now();

                      // Prepare the data to be inserted
                      final trackingData = {
                        'timestamp': timestamp,
                        'Vitals': widget.inputs['Vitals'],
                        'Symptom Assessment':
                            widget.inputs['Symptom Assessment'],
                      };

                      // Get reference to the patient's document in the 'tracking' collection
                      final trackingRef = FirebaseFirestore.instance
                          .collection('tracking')
                          .doc(widget.uid);

                      // Get the document snapshot to check if the 'tracking' data exists
                      final docSnapshot = await trackingRef.get();

                      if (docSnapshot.exists) {
                        // If the document exists, update the 'tracking' array
                        await trackingRef.update({
                          'tracking': FieldValue.arrayUnion([trackingData])
                        }).catchError((e) {
                          print("Error storing data: $e");
                          // Show error snack bar if update fails
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error storing data: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        });
                      } else {
                        // If the document doesn't exist, create the document with the tracking data
                        await trackingRef.set({
                          'tracking': [trackingData]
                        }).catchError((e) {
                          print("Error storing data: $e");
                          // Show error snack bar if set fails
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error storing data: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        });
                      }

                      // Navigate back after successful submission
                      Navigator.pop(context);

                      // Show success snack bar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data submitted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      // Handle any unexpected errors
                      print("Unexpected error: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('An unexpected error occurred: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    backgroundColor: AppColors.neon,
                  ),
                  child: const Text(
                    'Submit Final',
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
        ),
      ),
    );
  }
}
