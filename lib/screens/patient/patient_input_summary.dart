// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/globals.dart';
import 'package:solace/themes/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:solace/services/log_service.dart';

class ReceiptScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> algoInputs;

  const ReceiptScreen({
    super.key,
    required this.uid,
    required this.inputs,
    required this.algoInputs,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LogService _logService = LogService();

  void _identifySymptoms() async {
    List<String> symptoms = [];

    // Clear symptoms in Firestore
    try {
      await _firestore.collection('patient').doc(widget.uid).update({
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
        .removeWhere((key, value) => value == 0);
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
      await _firestore.collection('patient').doc(widget.uid).update({
        'symptoms': FieldValue.arrayUnion(symptoms),
      });
      debugPrint('Identified symptoms successfully updated in Firestore');

      String status = '';
      if (symptoms.isEmpty) {
        status = 'stable';
        debugPrint('Status set to stable');
      } else {
        status = 'unstable';
        debugPrint('Status set to unstable');
      }
      await _firestore.collection('patient').doc(widget.uid).update({
        'status': status,
      });
    } catch (e) {
      debugPrint('Error updating Firestore: $e');
    }
  }

  void _submitAlgoInputs(String uid) async {
    final userData = DatabaseService(uid: uid).userData;
    if (userData == null) {
      debugPrint('Submit Algo Input No User Data');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No User Data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      try {
        // Convert mapped algo inputs to a list
        List<dynamic> algoInputs = widget.algoInputs.values.toList();
        debugPrint('Tracking algo inputs: $algoInputs');

        // Send the inputs for prediction
        // await getPrediction(algoInputs);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Handle any unexpected errors
        debugPrint("Unexpected error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An unexpected error occurred: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

    // Format algoInputs to match the input size expected by the model (8 features)
    List<dynamic>? formattedInputs;
    try {
      formattedInputs = [
        algoInputs[0] == 'Male' ? 1 : (algoInputs[0] == 'Female' ? 0 : -1), // Gender
        (algoInputs[1] ?? 0) as int, // Age
        algoInputs[2] ?? 0.0, // Temperature
        (algoInputs[3] ?? 0) as int, // Oxygen Saturation
        (algoInputs[4] ?? 0) as int, // Heart Rate
        algoInputs[5] ?? 0.0, // Respiration
        (algoInputs[6] ?? 0) as int, // Systolic
        (algoInputs[7] ?? 0) as int, // Diastolic
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
        if (responseData['prediction'][0] == 0) {
          debugPrint(
              'Prediction: Negative (No complications detected based on algo)');
        } else {
          debugPrint(
              'Prediction: Positive (Complications detected based on algo but not specified what)');
        }
      } else {
        debugPrint("Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<bool> _onWillPop() async {
    // Show confirmation dialog
    bool shouldPop = await showDialog<bool>(
          context: context,
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: const Text(
                'Unsaved Changes',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              content: const Text(
                'If you go back, your inputs will not be saved. Do you want to continue?',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    // If "Continue" is pressed, allow navigation
                    Navigator.of(context).pop(true);
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    backgroundColor: AppColors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // If "Cancel" is pressed, stay on the page
                    Navigator.of(context).pop(false);
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
              ],
            );
          },
        ) ??
        false;

    return shouldPop;
  }

  final vitalsUnits = {
    'Heart Rate': 'bpm',
    'Blood Pressure': 'mmHg',
    'Oxygen Saturation': '%',
    'Respiration': 'b/min',
    'Temperature': '°C',
    'Cholesterol Level': 'mg/dL',
    'Paint': '',
  };

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Intercept the back navigation
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: const Text(
            'Summary',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
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
                Container(
                  padding: EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.neon,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 40,
                        color: AppColors.white,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Please check the input before submitting.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 18,
                            fontFamily: 'Inter',
                            color: AppColors.white),
                      ),
                      Text(
                        'Once submitted, it cannot be reverted',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: AppColors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
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
                if (widget.inputs['Vitals'] is Map)
                  ...widget.inputs['Vitals'].entries.map((entry) {
                    // Get the unit for the current vital
                    final unit = vitalsUnits[entry.key] ?? '';
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
                            '${entry.value}$unit', // Append the unit
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
                if (widget.inputs['Symptom Assessment'] is Map)
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
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      try {
                        // Show "Submitting" snackbar with a small CircularProgressIndicator
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text('Submitting data...'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(
                                  seconds: 3), // Keep it open for 10 seconds
                            ),
                          );
                        }

                        // Identify current symptoms based on inputs and save them in Firestore
                        _identifySymptoms();

                        // Get the current timestamp
                        final timestamp = Timestamp.now();

                        debugPrint("Timestamp now at tracking: $timestamp");

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
                            debugPrint("Error storing data: $e");
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error storing data: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          });
                        } else {
                          // If the document doesn't exist, create the document with the tracking data
                          await trackingRef.set({
                            'tracking': [trackingData]
                          }).catchError((e) {
                            debugPrint("Error creating tracking document: $e");
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Error creating tracking data: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          });
                        }

                        // Show success message after data submission
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Data submitted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }

                        // Add log entry
                        await _logService.addLog(
                          userId: widget.uid,
                          action: 'Submitted tracking information',
                        );

                        Navigator.pop(context);
                      } catch (e) {
                        // Handle any unexpected errors here
                        debugPrint("Unexpected error: $e");
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('An unexpected error occurred: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
