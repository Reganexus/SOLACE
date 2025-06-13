// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:solace/controllers/notification_service.dart';
import 'package:solace/screens/patient/patient_tracking.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';
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
  final DatabaseService databaseService = DatabaseService();
  final LogService _logService = LogService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  late Map<String, dynamic> thresholds = {};

  final vitalsUnits = {
    'Heart Rate': 'bpm',
    'Blood Pressure': 'mmHg',
    'Oxygen Saturation': '%',
    'Respiration': 'b/min',
    'Temperature': '°C',
    'Pain': '',
  };

  @override
  void initState() {
    super.initState();
    _fetchThresholds();
  }

  Future<void> _fetchThresholds() async {
    thresholds = await databaseService.fetchThresholds();
    setState(() {
      _isLoading = false;
    });
  }

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
                        child: Text('Go Back', style: Textstyle.smallButton),
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

  void _identifySymptoms() async {
    List<String> symptoms = [];

    // Clear symptoms in Firestore
    try {
      await _firestore.collection('patient').doc(widget.uid).update({
        'symptoms': [],
      });
      //       debugPrint('Symptoms list cleared successfully.');
    } catch (e) {
      //       debugPrint('Error clearing symptoms list: $e');
    }

    // Analyze vital inputs
    Map<String, String> vitals = Map<String, String>.from(
      widget.inputs['Vitals'],
    );
    final modifiedVitals = Map<String, dynamic>.from(vitals);
    // Remove Systolic and Diastolic keys
    final systolic = modifiedVitals.remove('Systolic');
    final diastolic = modifiedVitals.remove('Diastolic');

    // Add Blood Pressure key with combined value
    if (systolic != null && diastolic != null) {
      modifiedVitals['Blood Pressure'] = '$systolic/$diastolic';
    }
    modifiedVitals.forEach((key, value) {
      if (value.isEmpty) return;

      double vitalValue = 0;
      try {
        if (key != 'Blood Pressure') {
          vitalValue = double.parse(value);
        } else {}
      } catch (e) {
        return;
      }

      switch (key) {
        case 'Heart Rate':
          if (vitalValue < thresholds['minMildHeartRate']) {
            symptoms.add('Extremely Low Heart Rate');
          } else if (vitalValue > thresholds['maxMildHeartRate']) {
            symptoms.add('Extremely High Heart Rate');
          } else if (vitalValue < thresholds['minNormalHeartRate']) {
            symptoms.add('Low Heart Rate');
          } else if (vitalValue > thresholds['maxNormalHeartRate']) {
            symptoms.add('High Heart Rate');
          }
          break;
        case 'Oxygen Saturation':
          if (vitalValue < thresholds['minMildOxygenSaturation']) {
            symptoms.add('Extremely Low Oxygen Saturation');
          } else if (vitalValue < thresholds['minNormalOxygenSaturation']) {
            symptoms.add('Low Oxygen Saturation');
          }
          break;

        case 'Respiration':
          if (vitalValue < thresholds['minMildRespirationRate']) {
            symptoms.add('Extremely Low Respiration Rate');
          } else if (vitalValue > thresholds['maxMildRespirationRate']) {
            symptoms.add('Extremely High Respiration Rate');
          } else if (vitalValue < thresholds['minNormalRespirationRate']) {
            symptoms.add('Low Respiration Rate');
          } else if (vitalValue > thresholds['maxNormalRespirationRate']) {
            symptoms.add('High Respiration Rate');
          }
          break;

        case 'Temperature':
          if (vitalValue < thresholds['minMildTemperature']) {
            symptoms.add('Extremely Low Temperature');
          } else if (vitalValue > thresholds['maxMildTemperature']) {
            symptoms.add('Extremely High Temperature');
          } else if (vitalValue < thresholds['minNormalTemperature']) {
            symptoms.add('Low Temperature');
          } else if (vitalValue > thresholds['maxNormalTemperature']) {
            symptoms.add('High Temperature');
          }
          break;

        case 'Blood Pressure':
          final parts = value.split('/');
          final systolic = int.tryParse(parts[0]);
          final diastolic = int.tryParse(parts[1]);
          if (systolic! > thresholds['maxMildSystolic'] ||
              diastolic! > thresholds['maxMildDiastolic']) {
            symptoms.add('Extremely High Blood Pressure');
          } else if (systolic < thresholds['minMildSystolic'] &&
              diastolic < thresholds['minMildDiastolic']) {
            symptoms.add('Extremely Low Blood Pressure');
          } else if (systolic > thresholds['maxNormalSystolic'] ||
              diastolic > thresholds['maxNormalDiastolic']) {
            symptoms.add('High Blood Pressure');
          } else if (systolic < thresholds['minNormalSystolic'] &&
              diastolic < thresholds['minNormalDiastolic']) {
            symptoms.add('Low Blood Pressure');
          }
          break;

        case 'Pain':
          if (vitalValue > thresholds['maxMildScale']) {
            symptoms.add('Extremely High Pain');
          } else if (vitalValue > thresholds['maxNormalScale']) {
            symptoms.add('High Pain');
          }
          break;

        default:
        //           debugPrint('$key: Unable to determine status');
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
      String status = '';
      if (symptoms.isEmpty) {
        status = 'stable';
      } else {
        status = 'unstable';
      }
      await _firestore.collection('patient').doc(widget.uid).update({
        'status': status,
      });
    } catch (e) {
      showToast('Error updating Firestore: $e');
    }
  }

  void _submitAlgoInputs(String uid) async {
    final patientData = await DatabaseService(uid: uid).getPatientData(uid);
    if (patientData == null) {
      //       debugPrint('Submit Algo Input No User Data');
      if (mounted) {
        showToast('No User Data', backgroundColor: AppColors.red);
      }
    } else {
      try {
        // Convert mapped algo inputs to a list
        List<dynamic> algoInputs = widget.algoInputs.values.toList();

        // Send the inputs for prediction
        await getPrediction(algoInputs);

        // Show success message
        if (mounted) {
          showToast('Data submitted successfully!');
        }
      } catch (e) {
        // Handle any unexpected errors
        //         debugPrint("Unexpected error: $e");
        if (mounted) {
          showToast(
            'An unexpected error occurred: $e',
            backgroundColor: AppColors.red,
          );
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

      // Send HTTP request
      final response = await http
          .post(url, headers: headers, body: jsonEncode(requestBody))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData.containsKey('predictions')) {
          Map<String, dynamic> predictions = responseData['predictions'];

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

                // Save systolic and diastolic separately
                String systolicKey = "systolic_t+$timeSuffix";
                String diastolicKey = "diastolic_t+$timeSuffix";

                formattedPredictions[systolicKey] = value.round();

                // If diastolic exists, save it separately
                if (predictions.containsKey(
                  "systemicdiastolic_t+$timeSuffix",
                )) {
                  formattedPredictions[diastolicKey] =
                      predictions["systemicdiastolic_t+$timeSuffix"].round();
                }
              } else if (!key.startsWith("systemicdiastolic")) {
                // Convert other values to integer
                formattedPredictions[key] = value.round();
              }
            });

            // Add formattedPredictions to Firestore
            try {
              // Get the current timestamp
              final currentTimestamp = Timestamp.now();

              // Calculate future timestamps for t+1, t+2, and t+3
              final tPlus1Timestamp = currentTimestamp.toDate().add(
                Duration(hours: 1),
              );
              final tPlus2Timestamp = currentTimestamp.toDate().add(
                Duration(hours: 6),
              );
              final tPlus3Timestamp = currentTimestamp.toDate().add(
                Duration(hours: 12),
              );

              // Format the timestamps to include only up to minutes
              final tPlus1DocumentId =
                  "${DateFormat('yyyy-MM-dd_HH:mm').format(tPlus1Timestamp)}_t+1";
              final tPlus2DocumentId =
                  "${DateFormat('yyyy-MM-dd_HH:mm').format(tPlus2Timestamp)}_t+2";
              final tPlus3DocumentId =
                  "${DateFormat('yyyy-MM-dd_HH:mm').format(tPlus3Timestamp)}_t+3";

              // Split predictions into three maps: t+1, t+2, and t+3
              Map<String, dynamic> tPlus1 = {};
              Map<String, dynamic> tPlus2 = {};
              Map<String, dynamic> tPlus3 = {};

              formattedPredictions.forEach((key, value) {
                if (key.contains("_t+1")) {
                  tPlus1[key.replaceAll("_t+1", "")] = value;
                } else if (key.contains("_t+2")) {
                  tPlus2[key.replaceAll("_t+2", "")] = value;
                } else if (key.contains("_t+3")) {
                  tPlus3[key.replaceAll("_t+3", "")] = value;
                }
              });

              // Save each prediction group as a separate document in the subcollection
              await FirebaseFirestore.instance
                  .collection('patient')
                  .doc(widget.uid)
                  .collection('predictions')
                  .doc(tPlus1DocumentId)
                  .set({
                    'predictedAt': currentTimestamp,
                    ...tPlus1, // Add all fields for t+1
                  });

              await FirebaseFirestore.instance
                  .collection('patient')
                  .doc(widget.uid)
                  .collection('predictions')
                  .doc(tPlus2DocumentId)
                  .set({
                    'predictedAt': currentTimestamp,
                    ...tPlus2, // Add all fields for t+2
                  });

              await FirebaseFirestore.instance
                  .collection('patient')
                  .doc(widget.uid)
                  .collection('predictions')
                  .doc(tPlus3DocumentId)
                  .set({
                    'predictedAt': currentTimestamp,
                    ...tPlus3, // Add all fields for t+3
                  });

              // Update the latest predictions array in the patient document
              formattedPredictions['timestamp'] = currentTimestamp;
              await FirebaseFirestore.instance
                  .collection('patient')
                  .doc(widget.uid)
                  .update({
                    'predictions': [
                      formattedPredictions,
                    ], // Replace the entire array
                  });

              //               debugPrint('Predictions successfully added to Firestore.');
            } catch (e) {
              //               debugPrint('Error adding predictions to Firestore: $e');
            }
          } else {
            //             debugPrint("API returned empty predictions.");
          }
        } else {
          //           debugPrint("Unexpected response format: ${response.body}");
        }
      } else {
        //         debugPrint(
        //          "API Error: ${response.statusCode}, Response: ${response.body}",
        //        );
      }
    } on TimeoutException {
      //       debugPrint("API Timeout: $e");
      showToast("API Timeout", backgroundColor: AppColors.red);
      // Show a UI message to the user
    } on SocketException catch (e) {
      //       debugPrint("Network Error: $e");
      showToast("Network Error: $e", backgroundColor: AppColors.red);
      // Handle no internet or server unreachable case
    } on FormatException catch (e) {
      showToast("Format Exception Error: $e", backgroundColor: AppColors.red);
      //       debugPrint("Invalid Response Format: $e");
    } catch (e) {
      //       debugPrint("Unexpected Error: $e");
      showToast("Unexpected Error: $e", backgroundColor: AppColors.red);
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
              //               debugPrint("Error storing data: $e");
              if (mounted) {
                showToast(
                  'Error storing data: $e',
                  backgroundColor: AppColors.red,
                );
              }
            });
      } else {
        // If the document doesn't exist, create the document with the tracking data
        await trackingRef
            .set({
              'tracking': [trackingData],
            })
            .catchError((e) {
              //               debugPrint("Error creating tracking document: $e");
              if (mounted) {
                showToast(
                  'Error creating tracking data: $e',
                  backgroundColor: AppColors.red,
                );
              }
            });
      }

      // Save the vitals to the nearest prediction documents
      await saveVitalsToNearestPrediction(
        reformatVitals(widget.inputs['Vitals']),
      );

      // Add log entries
      await _logService.addLog(
        userId: _auth.currentUser!.uid,
        action: 'Submitted $patientName\'s tracking information',
        relatedUsers: widget.uid,
      );

      DocumentSnapshot patientDoc =
          await _firestore.collection('patient').doc(widget.uid).get();
      String status = patientDoc.get('status') ?? 'uncertain';

      final user = _auth.currentUser;
      if (user == null) {
        showToast("User is not Authenticated", backgroundColor: AppColors.red);
        return;
      }

      final String userId = user.uid;
      final String? caregiverRole = await databaseService.fetchAndCacheUserRole(
        userId,
      );
      final String role =
          '${caregiverRole?.substring(0, 1).toUpperCase()}${caregiverRole?.substring(1)}';
      final String? caregiverName = await databaseService.fetchUserName(userId);

      if (status == 'unstable') {
        // Send notification for unstable status
        await notificationService.sendNotificationToTaggedUsers(
          widget.uid,
          "Tracking Update",
          "Patient $patientName is tracked by $role $caregiverName and is unstable. Check it now.",
        );

        await notificationService.sendInAppNotificationToTaggedUsers(
          patientId: widget.uid,
          currentUserId: userId,
          notificationMessage:
              "Patient $patientName is tracked by $role $caregiverName and is unstable. Check it now.",
          type: "update",
        );
      } else if (status == 'stable') {
        // Send notification for stable status
        await notificationService.sendNotificationToTaggedUsers(
          widget.uid,
          "Tracking Update",
          "Patient $patientName is tracked by $role $caregiverName and is stable. Check it now.",
        );

        await notificationService.sendInAppNotificationToTaggedUsers(
          patientId: widget.uid,
          currentUserId: userId,
          notificationMessage:
              "Patient $patientName is tracked by $role $caregiverName and is stable. Check it now.",
          type: "update",
        );
      } else if (status == 'uncertain') {
        // Send notification for uncertain status
        await notificationService.sendNotificationToTaggedUsers(
          widget.uid,
          "Tracking Update",
          "Patient $patientName is tracked by $role $caregiverName and is 7uncertain. Check it now.",
        );
        await notificationService.sendInAppNotificationToTaggedUsers(
          patientId: widget.uid,
          currentUserId: userId,
          notificationMessage:
              "Patient $patientName is tracked by $role $caregiverName and is 7uncertain. Check it now.",
          type: "update",
        );
      } else {
        showToast("Status is not stable, unstable, or uncertain.");
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => PatientTracking(patientId: widget.uid),
        ),
        (Route<dynamic> route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        showToast(
          'An unexpected error occurred: $e',
          backgroundColor: AppColors.red,
        );
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

  Future<void> saveVitalsToNearestPrediction(
    Map<String, dynamic> submittedVitals,
  ) async {
    try {
      final currentTimestamp = DateTime.now();

      // Query the predictions subcollection
      final predictionsSnapshot =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(widget.uid)
              .collection('predictions')
              .get();

      //       debugPrint(
      //        'Predictions Snapshot: ${predictionsSnapshot.docs.length} documents found.',
      //      );

      // Group documents by their suffix (_t+1, _t+2, _t+3)
      Map<String, Map<String, dynamic>> nearestDocuments = {};
      for (var doc in predictionsSnapshot.docs) {
        final docId = doc.id;
        //         debugPrint('Processing Document ID: $docId');

        // Extract the suffix (e.g., _t+1, _t+2, _t+3)
        final suffix = docId.substring(docId.lastIndexOf('_'));
        if (!['_t+1', '_t+2', '_t+3'].contains(suffix)) {
          continue;
        }

        // Extract the timestamp from the document ID
        final timestampString = '${docId.split('_')[0]}_${docId.split('_')[1]}';

        // Parse the timestamp
        DateTime? docTimestamp;
        try {
          docTimestamp = DateFormat('yyyy-MM-dd_HH:mm').parse(timestampString);
        } catch (e) {
          continue;
        }

        // Calculate the time difference in seconds
        final timeDifference =
            docTimestamp.difference(currentTimestamp).inSeconds;

        // Only consider documents within 15 minutes (±900 seconds)
        if (timeDifference.abs() <= 900) {
          // Check if the document already has a timeDifference field
          final existingTimeDifference =
              doc.data().containsKey('timeDifference')
                  ? doc.get('timeDifference') as int
                  : null;

          if (existingTimeDifference != null) {
            // If the current timeDifference is farther from 0, skip this document
            if (timeDifference.abs() >= existingTimeDifference.abs()) {
              continue;
            }
          }

          // Update the nearest document if the current timeDifference is closer to 0
          nearestDocuments[suffix] = {
            'doc': doc,
            'timeDifference': timeDifference,
          };
        }
      }

      // Save the submitted vitals to the nearest documents
      for (var entry in nearestDocuments.entries) {
        final doc = entry.value['doc'] as QueryDocumentSnapshot;
        final timeDifference = entry.value['timeDifference'] as int;

        // Prepare the data to save
        final Map<String, dynamic> actualVitals = {};
        submittedVitals.forEach((key, value) {
          actualVitals['actual_$key'] = value;
        });

        // Add the time difference field
        actualVitals['timeDifference'] = timeDifference;

        // Update the document with the actual vitals
        await FirebaseFirestore.instance
            .collection('patient')
            .doc(widget.uid)
            .collection('predictions')
            .doc(doc.id)
            .update(actualVitals);
      }
    } catch (e) {
      //       debugPrint('Error saving vitals to nearest prediction: $e');
    }
  }

  Map<String, dynamic> reformatVitals(Map<String, dynamic> submittedVitals) {
    final Map<String, dynamic> reformattedVitals = {};

    submittedVitals.forEach((key, value) {
      // Ignore the "Pain" key
      if (key.toLowerCase() == 'pain') return;

      // Handle "Oxygen Saturation" as "sao2"
      if (key.toLowerCase() == 'oxygen saturation') {
        reformattedVitals['sao2'] = value;
        return;
      }

      // Reformat other keys: remove spaces and convert to lowercase
      final formattedKey = key.toLowerCase().replaceAll(' ', '');
      reformattedVitals[formattedKey] = value;
    });

    return reformattedVitals;
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
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                              (entry.value == null ||
                                      entry.value.toString().isEmpty)
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
                        ...widget.inputs['Symptom Assessment'].entries.map((
                          entry,
                        ) {
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
