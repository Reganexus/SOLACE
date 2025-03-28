// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/screens/patient/patient_tracking.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/globals.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/textstyle.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

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
    Map<String, String> vitals = Map<String, String>.from(
      widget.inputs['Vitals'],
    );
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
    Map<String, int> symptomAssessment = Map<String, int>.from(
      widget.inputs['Symptom Assessment'],
    );

    // Remove symptoms with a value of 0
    symptomAssessment.removeWhere((key, value) => value == 0);
    // Sort symptoms in descending order by value
    List<MapEntry<String, int>> sortedSymptoms =
        symptomAssessment.entries.toList()
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
    final patientData = await DatabaseService(uid: uid).getPatientData(uid);
    if (patientData == null) {
      debugPrint('Submit Algo Input No User Data');
      if (mounted) {
        showToast('No User Data');
      }
    } else {
      try {
        // Convert mapped algo inputs to a list
        List<dynamic> algoInputs = widget.algoInputs.values.toList();
        debugPrint('Tracking algo inputs: $algoInputs');

        // Send the inputs for prediction
        await getPrediction(algoInputs);

        // Show success message
        if (mounted) {
          showToast('Data submitted successfully!');
        }
      } catch (e) {
        // Handle any unexpected errors
        debugPrint("Unexpected error: $e");
        if (mounted) {
          showToast('An unexpected error occurred: $e');
        }
      }
    }
  }

  Future<void> getPrediction(List<dynamic> algoInputs) async {
    // Choose appropriate IP address
    final virtualAddress =
        '10.0.2.2'; // Use for virtual devices (e.g., Android emulator)
    // final localHostAddress = '127.0.0.1'; // default

    // if using physical device, use computer’s IP address instead of 127.0.0.1 or localhost.
    final url = Uri.parse('http://$virtualAddress:5000/predict');
    final headers = {"Content-Type": "application/json"};

    // Ensure inputs are formatted correctly
    List<dynamic> formattedInputs;
    try {
      formattedInputs = [
        algoInputs[0] == 'Male'
            ? 1
            : (algoInputs[0] == 'Female' ? 0 : -1), // Gender (int)
        int.tryParse(algoInputs[1].toString()) ?? 0, // Age (int)
        double.tryParse(algoInputs[2].toString()) ??
            0.0, // Temperature (double)
        int.tryParse(algoInputs[3].toString()) ?? 0, // Oxygen Saturation (int)
        int.tryParse(algoInputs[4].toString()) ?? 0, // Heart Rate (int)
        int.tryParse(algoInputs[5].toString()) ?? 0, // Respiration Rate (int)
        int.tryParse(algoInputs[6].toString()) ?? 0, // Systolic BP (int)
        int.tryParse(algoInputs[7].toString()) ?? 0, // Diastolic BP (int)
      ];

      debugPrint('Formatted Inputs: $formattedInputs');
    } catch (e, stackTrace) {
      debugPrint('Error formatting inputs: $e');
      debugPrint('StackTrace: $stackTrace');
      return;
    }

    try {
      // Wrap formattedInputs inside 'data' key
      final body = json.encode({
        "data": [formattedInputs],
      });
      debugPrint("JSON Body: $body");

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Extract prediction result
        List<dynamic> predictions = responseData['predictions'];
        int predictionResult = predictions[0]; // Get first result

        debugPrint("Raw Response: ${response.body}");
        debugPrint("Prediction Result: $predictionResult");

        String status = '';
        String predictionString = '';
        // Handle Prediction Output
        if (predictionResult == 0) {
          status = 'stable';
          predictionString =
              'Prediction: Stable (No complications detected based on algorithm)';
        } else {
          status = 'unstable';
          predictionString =
              'Prediction: Unstable (Complications detected based on algorithm)';
        }
        await _firestore.collection('patient').doc(widget.uid).update({
          'status': status,
        });
        debugPrint(predictionString);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(predictionString),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint("API Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Network/Parsing Error: $e");
    }
  }

  Future<bool> _onWillPop() async {
    // Show confirmation dialog
    bool shouldPop =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text('Unsaved Changes', style: Textstyle.subheader),
              content: Text(
                'If you go back, your inputs will not be saved. Do you want to continue?',
                style: Textstyle.body,
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    // If "Continue" is pressed, allow navigation
                    Navigator.of(context).pop(true);
                  },
                  style: Buttonstyle.buttonRed,
                  child: Text('Continue', style: Textstyle.smallButton),
                ),
                TextButton(
                  onPressed: () {
                    // If "Cancel" is pressed, stay on the page
                    Navigator.of(context).pop(false);
                  },
                  style: Buttonstyle.buttonNeon,
                  child: Text('Cancel', style: Textstyle.smallButton),
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
    'Paint': '',
  };

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Intercept the back navigation
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: Text('Summary', style: Textstyle.subheader),
          backgroundColor: AppColors.white,
          scrolledUnderElevation: 0.0,
        ),
        body: SingleChildScrollView(
          child: Container(
            color: AppColors.white,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                        style: Textstyle.body.copyWith(color: AppColors.white),
                      ),
                      Text(
                        'Once submitted, it cannot be reverted',
                        textAlign: TextAlign.center,
                        style: Textstyle.subheader.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your Assessment',
                  textAlign: TextAlign.left,
                  style: Textstyle.subheader,
                ),
                const SizedBox(height: 20.0),
                Text('Vitals:', style: Textstyle.subheader),
                if (widget.inputs['Vitals'] is Map)
                  ...widget.inputs['Vitals'].entries.map((entry) {
                    // Get the unit for the current vital
                    final unit = vitalsUnits[entry.key] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${entry.key}:', style: Textstyle.body),
                          Text(
                            '${entry.value}$unit', // Append the unit
                            style: Textstyle.body,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 20.0),
                Text('Symptom Assessment:', style: Textstyle.subheader),
                const SizedBox(height: 10.0),
                if (widget.inputs['Symptom Assessment'] is Map)
                  ...widget.inputs['Symptom Assessment'].entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${entry.key}:', style: Textstyle.body),
                          Text('${entry.value}', style: Textstyle.body),
                        ],
                      ),
                    );
                  }).toList(),
                Divider(),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      try {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text('Submitting data...'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(
                                seconds: 3,
                              ), // Keep it open for 10 seconds
                            ),
                          );
                        }

                        _identifySymptoms();

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
                          await trackingRef
                              .update({
                                'tracking': FieldValue.arrayUnion([
                                  trackingData,
                                ]),
                              })
                              .catchError((e) {
                                debugPrint("Error storing data: $e");
                                if (mounted) {
                                  showToast('Error storing data: $e');
                                }
                              });
                        } else {
                          // If the document doesn't exist, create the document with the tracking data
                          await trackingRef
                              .set({
                                'tracking': [trackingData],
                              })
                              .catchError((e) {
                                debugPrint(
                                  "Error creating tracking document: $e",
                                );
                                if (mounted) {
                                  showToast('Error creating tracking data: $e');
                                }
                              });
                        }

                        DocumentSnapshot doc =
                            await _firestore
                                .collection('patient')
                                .doc(widget.uid)
                                .get();
                        String fName = doc.get('firstName');
                        String lName = doc.get('lastName');
                        String patientName = '$fName $lName';

                        // Add log entry
                        await _logService.addLog(
                          userId: _auth.currentUser!.uid,
                          action:
                              'Submitted $patientName\'s tracking information',
                          relatedUsers: widget.uid,
                        );

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    PatientTracking(patientId: widget.uid),
                          ),
                          (Route<dynamic> route) =>
                              route
                                  .isFirst, // Retain only the first route (Dashboard)
                        );
                      } catch (e) {
                        // Handle any unexpected errors here
                        debugPrint("Unexpected error: $e");
                        if (mounted) {
                          showToast('An unexpected error occurred: $e');
                        }
                      }
                    },
                    style: Buttonstyle.neon,
                    child: Text('Submit Final', style: Textstyle.largeButton),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
