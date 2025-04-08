// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/controllers/notification_service.dart';
import 'package:solace/screens/patient/patient_tracking.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/globals.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/textstyle.dart';
import 'dart:async';
import 'dart:io';

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
  final notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LogService _logService = LogService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final vitalsUnits = {
    'Heart Rate': 'bpm',
    'Blood Pressure': 'mmHg',
    'Oxygen Saturation': '%',
    'Respiration': 'b/min',
    'Temperature': '°C',
    'Pain': '',
  };

  Future<bool> _onWillPop() async {
    bool shouldPop =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text('Go Back?', style: Textstyle.subheader),
              content: Text(
                'Do you want to go back to change your tracking?',
                style: Textstyle.body,
              ),
              actions: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        style: Buttonstyle.buttonRed,
                        child: Text('Cancel', style: Textstyle.smallButton),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      PatientTracking(patientId: widget.uid),
                            ),
                            (Route<dynamic> route) => route.isFirst,
                          );
                        },
                        style: Buttonstyle.buttonNeon,
                        child: Text('Continue', style: Textstyle.smallButton),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;

    return shouldPop;
  }

  Widget _buildDeter() {
    return Container(
      padding: EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.neon,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(Icons.info_outline_rounded, size: 40, color: AppColors.white),
          SizedBox(height: 10),
          Text(
            'Please check the input before submitting.',
            textAlign: TextAlign.center,
            style: Textstyle.body.copyWith(color: AppColors.white),
          ),
          Text(
            'Once submitted, it cannot be reverted',
            textAlign: TextAlign.center,
            style: Textstyle.subheader.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(title, textAlign: TextAlign.left, style: Textstyle.subheader);
  }

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
          if (vitalValue < minExtremeHeartRate) {
            symptoms.add('Extremely Low Heart Rate');
          } else if (vitalValue > maxExtremeHeartRate) {
            symptoms.add('Extremely High Heart Rate');
          } else if (vitalValue < minNormalHeartRate) {
            symptoms.add('Low Heart Rate');
          } else if (vitalValue > maxNormalHeartRate) {
            symptoms.add('High Heart Rate');
          }
          break;
        case 'Oxygen Saturation':
          if (vitalValue < minExtremeOxygenSaturation) {
            symptoms.add('Extremely Low Oxygen Saturation');
          } else if (vitalValue < minNormalOxygenSaturation) {
            symptoms.add('Low Oxygen Saturation');
          }
          break;

        case 'Respiration':
          if (vitalValue < minExtremeRespirationRate) {
            symptoms.add('Extremely Low Respiration Rate');
          } else if (vitalValue > maxExtremeRespirationRate) {
            symptoms.add('Extremely High Respiration Rate');
          } else if (vitalValue < minNormalRespirationRate) {
            symptoms.add('Low Respiration Rate');
          } else if (vitalValue > maxNormalRespirationRate) {
            symptoms.add('High Respiration Rate');
          }
          break;

        case 'Temperature':
          if (vitalValue < minExtremeTemperature) {
            symptoms.add('Extremely Low Temperature');
          } else if (vitalValue > maxExtremeTemperature) {
            symptoms.add('Extremely High Temperature');
          } else if (vitalValue < minNormalTemperature) {
            symptoms.add('Low Temperature');
          } else if (vitalValue > maxNormalTemperature) {
            symptoms.add('High Temperature');
          }
          break;

        case 'Blood Pressure':
          final parts = value.split('/');
          final systolic = int.tryParse(parts[0]);
          final diastolic = int.tryParse(parts[1]);
          if (systolic! > maxExtremeBloodPressureSystolic ||
              diastolic! > maxExtremeBloodPressureDiastolic) {
            symptoms.add('Extremely High Blood Pressure');
          } else if (systolic < minExtremeBloodPressureSystolic &&
              diastolic < minExtremeBloodPressureDiastolic) {
            symptoms.add('Extremely Low Blood Pressure');
          } else if (systolic > maxNormalBloodPressureSystolic ||
              diastolic > maxNormalBloodPressureDiastolic) {
            symptoms.add('High Blood Pressure');
          } else if (systolic < minNormalBloodPressureSystolic &&
              diastolic < minNormalBloodPressureDiastolic) {
            symptoms.add('Low Blood Pressure');
          }
          break;

        case 'Pain':
          if (vitalValue > maxExtremeScale) {
            symptoms.add('Extreme Pain');
          } else if (vitalValue > maxNormalScale) {
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
    final url = Uri.parse(
      "https://solace-xgboost-api-805655165429.asia-southeast1.run.app/predict",
    );
    final String? token = await _authService.getToken();
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
    debugPrint("Token: $token");

    try {
      final Map<String, dynamic> requestBody = {
        "gender": algoInputs[0] == 'Female' ? 0 : 1,
        "age":
            (int.tryParse(algoInputs[1].toString()) ?? 0) > 89
                ? 90
                : int.tryParse(algoInputs[1].toString()) ?? 0, // Cap age at 90
        "temperature": double.tryParse(algoInputs[2].toString()) ?? 0.0,
        "sao2": int.tryParse(algoInputs[3].toString()) ?? 0,
        "heartrate": int.tryParse(algoInputs[4].toString()) ?? 0,
        "respiration": int.tryParse(algoInputs[5].toString()) ?? 0,
        "systemicsystolic": int.tryParse(algoInputs[6].toString()) ?? 0,
        "systemicdiastolic": int.tryParse(algoInputs[7].toString()) ?? 0,
      };

      debugPrint("Sending JSON: ${jsonEncode(requestBody)}");

      // Send HTTP request
      final response = await http
          .post(url, headers: headers, body: jsonEncode(requestBody))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData.containsKey('predictions')) {
          Map<String, dynamic> predictions = responseData['predictions'];
          debugPrint("Raw Response: ${response.body}");

          if (predictions.isNotEmpty) {
            // Store processed values
            Map<String, dynamic> formattedPredictions = {};

            // Process the predictions
            predictions.forEach((key, value) {
              if (key.startsWith("temperature") || key.startsWith("sao2")) {
                // Round temperature & sao2 to 2 decimal places
                formattedPredictions[key] = value.toStringAsFixed(2);
              } else if (key.startsWith("systemicsystolic")) {
                // Extract time part
                String timeSuffix = key.split("_t+")[1];
                String bpKey = "bloodpressure_t+$timeSuffix";

                // If diastolic exists, merge it
                if (predictions.containsKey(
                  "systemicdiastolic_t+$timeSuffix",
                )) {
                  formattedPredictions[bpKey] =
                      "${value.round()}/${predictions["systemicdiastolic_t+$timeSuffix"].round()}";
                }
              } else if (!key.startsWith("systemicdiastolic")) {
                // Convert other values to integer
                formattedPredictions[key] = value.round();
              }
            });

            // Add formattedPredictions to Firestore
            try {
              // Add a timestamp to the formattedPredictions map
              formattedPredictions['timestamp'] = Timestamp.now();

              await FirebaseFirestore.instance
                  .collection('patient')
                  .doc(widget.uid)
                  .update({
                    'predictions': [
                      formattedPredictions,
                    ], // Replace the entire array
                  });
              debugPrint('Predictions successfully added to Firestore.');
            } catch (e) {
              debugPrint('Error adding predictions to Firestore: $e');
            }

            // Now print the formatted predictions
            formattedPredictions.forEach((key, value) {
              // Skip timestamp key
              if (key == "timestamp") {
                return;
              }

              String label = "";
              if (key.startsWith("temperature")) {
                label = "Predicted temperature after ";
              } else if (key.startsWith("sao2")) {
                label = "Predicted oxygen saturation after ";
              } else if (key.startsWith("heartrate")) {
                label = "Predicted heart rate after ";
              } else if (key.startsWith("respiration")) {
                label = "Predicted respiration rate after ";
              } else if (key.startsWith("bloodpressure")) {
                label = "Predicted blood pressure after ";
              }

              // Extract time (e.g., "t+1" → "1 hour", "t+2" → "6 hours", "t+3" → "24 hours")
              String time =
                  key.split("_t+")[1] == "1"
                      ? "1 hour"
                      : key.split("_t+")[1] == "2"
                      ? "6 hours"
                      : "24 hours";

              debugPrint("$label$time: $value");
            });
          } else {
            debugPrint("API returned empty predictions.");
          }
        } else {
          debugPrint("Unexpected response format: ${response.body}");
        }
      } else {
        debugPrint(
          "API Error: ${response.statusCode}, Response: ${response.body}",
        );
      }
    } on TimeoutException catch (e) {
      debugPrint("API Timeout: $e");
      // Show a UI message to the user
    } on SocketException catch (e) {
      debugPrint("Network Error: $e");
      // Handle no internet or server unreachable case
    } on FormatException catch (e) {
      debugPrint("Invalid Response Format: $e");
      // Handle cases where API returns unexpected response
    } catch (e) {
      debugPrint("Unexpected Error: $e");
      // Handle any other unknown errors
    }
  }

  Future<void> _submitData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      DocumentSnapshot doc =
          await _firestore.collection('patient').doc(widget.uid).get();
      String fName = doc.get('firstName');
      String lName = doc.get('lastName');
      int age = doc.get('age');
      String gender = doc.get('gender');
      String patientName = '$fName $lName';

      if (mounted) {
        showToast('Submitting data...');
      }

      _identifySymptoms();

      final timestamp = Timestamp.now();

      debugPrint("Timestamp now at tracking: $timestamp");

      // Prepare the data to be inserted
      final trackingData = {
        'age': age,
        'gender': gender,
        'timestamp': timestamp,
        'Vitals': widget.inputs['Vitals'],
        'Symptom Assessment': widget.inputs['Symptom Assessment'],
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
              'tracking': FieldValue.arrayUnion([trackingData]),
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
              debugPrint("Error creating tracking document: $e");
              if (mounted) {
                showToast('Error creating tracking data: $e');
              }
            });
      }

      // Add log entry
      await _logService.addLog(
        userId: _auth.currentUser!.uid,
        action: 'Submitted $patientName\'s tracking information',
        relatedUsers: widget.uid,
      );

      DocumentSnapshot patientDoc =
          await _firestore.collection('patient').doc(widget.uid).get();
      String status = patientDoc.get('status') ?? 'uncertain';

      if (status == 'unstable') {
        // Send notification for unstable status
        await notificationService.sendNotificationToTaggedUsers(
          widget.uid,
          "Tracking Update",
          "Patient $patientName is unstable. Check it now.",
        );
      } else if (status == 'stable') {
        // Send notification for stable status
        await notificationService.sendNotificationToTaggedUsers(
          widget.uid,
          "Tracking Update",
          "Patient $patientName is stable. View it now.",
        );
      } else if (status == 'uncertain') {
        // Send notification for uncertain status
        await notificationService.sendNotificationToTaggedUsers(
          widget.uid,
          "Tracking Update",
          "Patient $patientName is uncertain. Check it now.",
        );
      } else {
        debugPrint("Status is not stable, unstable, or uncertain.");
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => PatientTracking(patientId: widget.uid),
        ),
        (Route<dynamic> route) => route.isFirst,
      );
    } catch (e) {
      // Handle any unexpected errors here
      debugPrint("Unexpected error: $e");
      if (mounted) {
        showToast('An unexpected error occurred: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showConfirmationDialog() async {
    bool shouldSubmit =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text('Confirm Submission', style: Textstyle.subheader),
              content: Text(
                'Are you sure you want to submit the data?',
                style: Textstyle.body,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: Buttonstyle.buttonRed,
                        child: Text('Cancel', style: Textstyle.smallButton),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: Buttonstyle.buttonNeon,
                        child: Text('Submit', style: Textstyle.smallButton),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldSubmit) {
      _submitData();
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: !_isLoading ? _showConfirmationDialog : null,
        style: !_isLoading ? Buttonstyle.neon : Buttonstyle.gray,
        child: Text('Submit Final', style: Textstyle.largeButton),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Tracking Summary', style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        centerTitle: true,
        leading:
            _isLoading
                ? null
                : IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _onWillPop,
                ),
        automaticallyImplyLeading: _isLoading ? false : true,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.white,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeter(),
              const SizedBox(height: 20),
              _buildHeader("Your Assessment"),
              const SizedBox(height: 20.0),
              _buildHeader("Vitals:"),
              if (widget.inputs['Vitals'] is Map)
                ...widget.inputs['Vitals'].entries.map((entry) {
                  // Get the unit for the current vital
                  final unit = vitalsUnits[entry.key] ?? '';
                  final value =
                      (entry.value == null || entry.value.toString().isEmpty)
                          ? '0'
                          : entry.value.toString();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${entry.key}:', style: Textstyle.body),
                        Text(
                          '$value$unit', // Append the unit
                          style: Textstyle.body,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              const SizedBox(height: 20.0),
              _buildHeader("Symptom Assessment:"),
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
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }
}
