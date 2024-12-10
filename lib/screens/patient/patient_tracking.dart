// ignore_for_file: use_build_context_synchronously, unused_import, avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/screens/patient/input_summary.dart';
import 'package:solace/shared/globals.dart';
import 'package:solace/themes/colors.dart';

class PatientTracking extends StatefulWidget {
  const PatientTracking({super.key});

  @override
  PatientTrackingState createState() => PatientTrackingState();
}

class PatientTrackingState extends State<PatientTracking> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DatabaseService databaseService = DatabaseService();

  bool isCooldownActive = false; // Added this variable
  int remainingCooldownTime = 0; // Added this variable
  Timer? _countdownTimer;

  final Map<String, String> _vitalInputs = {
    'Heart Rate': '',
    'Blood Pressure': '',
    'Oxygen Saturation': '',
    'Respiration': '',
    'Temperature': '',
    'Cholesterol Level': '',
    'Pain': '',
  };

  final Map<String, dynamic> _algoInputs = {
    "Fever": false,
    "Cough": false,
    "Fatigue": false,
    "Difficulty Breathing": false,
    "Age": null,
    "Gender": null,
    "Blood Pressure": null,
    "Cholesterol Level": null,
  };

  int _diarrheaValue = 0;
  int _fatigueValue = 0;
  int _shortnessOfBreathValue = 0;
  int _appetiteValue = 0;
  int _coughingValue = 0;
  int _wellBeingValue = 0;
  int _nauseaValue = 0;
  int _depressionValue = 0;
  int _anxietyValue = 0;
  int _drowsinessValue = 0;

  late Map<String, dynamic> _combinedInputs; // Holds data for submission

  final FocusNode _bloodPressureFocusNode = FocusNode();

  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _bloodPressureController =
      TextEditingController();
  final TextEditingController _oxygenSaturationController =
      TextEditingController();
  final TextEditingController _respirationController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _cholesterolController = TextEditingController();
  final TextEditingController _painController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkAndResetOptions();
    _checkCooldown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel(); // Null-safe cancellation
    super.dispose();
  }

  void checkAndResetOptions() {
    setState(() {
      // Clear form fields
      _heartRateController.clear();
      _bloodPressureController.clear();
      _oxygenSaturationController.clear();
      _respirationController.clear();
      _temperatureController.clear();
      _cholesterolController.clear();
      _painController.clear();

      // Reset symptom values
      _diarrheaValue = 0;
      _fatigueValue = 0;
      _shortnessOfBreathValue = 0;
      _appetiteValue = 0;
      _coughingValue = 0;
      _wellBeingValue = 0;
      _nauseaValue = 0;
      _depressionValue = 0;
      _anxietyValue = 0;
      _drowsinessValue = 0;
    });
  }

  void _checkCooldown() async {
    final user = Provider.of<MyUser?>(context, listen: false);

    // Fetch the last submitted time from the database
    final lastSubmitted = await getLastSubmittedTime(user!.uid);

    if (lastSubmitted == 0) {
      // If no data is found (initial state or error), you can either set a default or allow immediate submission
      setState(() {
        isCooldownActive = false;
      });
      return;
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeDifference = currentTime - lastSubmitted;

    // 15 minutes cooldown (900,000 milliseconds)
    if (timeDifference < 1 * 60 * 1000) {
      // Still within cooldown
      setState(() {
        isCooldownActive = true;
        remainingCooldownTime = (1 * 60) -
            (timeDifference / 1000).round(); // Remaining time in seconds
      });
      _startCountdown();
    } else {
      // No cooldown, allow input
      setState(() {
        isCooldownActive = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel(); // Cancel any previous timer
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingCooldownTime > 0) {
        setState(() {
          remainingCooldownTime--;
        });
      } else {
        _countdownTimer?.cancel();
        setState(() {
          isCooldownActive = false;
        });
      }
    });
  }

  Future<int> getLastSubmittedTime(String userId) async {
    try {
      // Get a reference to the user's document in the Firestore collection
      final userDoc = await FirebaseFirestore.instance
          .collection('tracking')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Retrieve the timestamp of the last submission
        final lastTracking = userDoc.data()?['tracking'] as List?;
        if (lastTracking != null && lastTracking.isNotEmpty) {
          // Get the last tracking entry (assuming it's sorted, or you get the most recent)
          final lastEntry = lastTracking.last;
          final lastSubmittedTimestamp =
              (lastEntry['timestamp'] as Timestamp).millisecondsSinceEpoch;

          return lastSubmittedTimestamp;
        }
      }
      return 0; // If no data exists, return 0 to indicate no submission
    } catch (e) {
      print("Error fetching last submission time: $e");
      return 0; // Return 0 on error
    }
  }

  String _formatCooldownTime(int timeInSeconds) {
    int hours = (timeInSeconds / 3600).floor();
    int minutes = ((timeInSeconds % 3600) / 60).floor();
    int seconds = timeInSeconds % 60;
    return 'Hours: $hours Minutes: $minutes Seconds: $seconds';
  }

  @override
  Widget build(BuildContext context) {
    _checkCooldown();
    final user = Provider.of<MyUser?>(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss the keyboard
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SingleChildScrollView(
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Only show the "Vitals" title if no cooldown is active
                if (!isCooldownActive)
                  const Text(
                    'Vitals',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                const SizedBox(height: 20.0),

                // Display cooldown if active
                if (isCooldownActive)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: AppColors.gray,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'You cannot input vitals and assessment at the moment.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _formatCooldownTime(remainingCooldownTime),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),

                // Show form if no cooldown
                if (!isCooldownActive)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVitalsInputs(),
                      const SizedBox(height: 20.0),
                      const Divider(thickness: 1.0),
                      const SizedBox(height: 20.0),
                      const Text(
                        'Symptom Assessment',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      _buildSliders(),
                      const SizedBox(height: 20.0),
                      Center(
                        child: TextButton(
                          onPressed: () => _submit(user!.uid),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 10),
                            backgroundColor: AppColors.neon,
                          ),
                          child: const Text(
                            'Submit',
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
      ),
    );
  }

  InputDecoration _inputDecoration(String label, FocusNode focusNode) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.gray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.neon,
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: AppColors.black,
      ),
    );
  }

  Widget _buildVitalsInputs() {
    return Form(
      key: _formKey,
      child: Column(
        children: _vitalInputs.keys.map((key) {
          TextEditingController controller;

          // Assign the correct controller based on the key
          switch (key) {
            case 'Heart Rate':
              controller = _heartRateController;
              break;
            case 'Blood Pressure':
              controller = _bloodPressureController;
              break;
            case 'Oxygen Saturation':
              controller = _oxygenSaturationController;
              break;
            case 'Respiration':
              controller = _respirationController;
              break;
            case 'Temperature':
              controller = _temperatureController;
              break;
            case 'Cholesterol Level':
              controller = _cholesterolController;
              break;
            case 'Pain':
              controller = _painController;
              break;
            default:
              controller = TextEditingController();
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: TextFormField(
              controller: controller,
              focusNode:
                  key == 'Blood Pressure' ? _bloodPressureFocusNode : null,
              decoration: _inputDecoration(key, _bloodPressureFocusNode),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $key';
                }
                if (key == 'Blood Pressure') {
                  // Validate blood pressure format (systolic/diastolic)
                  final regex = RegExp(r'^\d{2,3}/\d{2,3}$');
                  if (!regex.hasMatch(value)) {
                    return 'Enter valid blood pressure (e.g., 120/80)';
                  }
                  // Split the input into systolic and diastolic
                  final parts = value.split('/');
                  final systolic = int.tryParse(parts[0]);
                  final diastolic = int.tryParse(parts[1]);

                  if (systolic == null || diastolic == null) {
                    return 'Enter valid blood pressure numbers';
                  }

                  // Validate ranges for systolic and diastolic
                  if (systolic < 50 ||
                      systolic > 200 ||
                      diastolic < 30 ||
                      diastolic > 120) {
                    return 'Enter valid blood pressure (systolic 50-200, diastolic 30-120)';
                  }
                } else {
                  // General number validation for all other fields
                  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
                    return 'Enter a valid number';
                  }
                }
                return null;
              },
              onChanged: (value) => _vitalInputs[key] = value,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSliders() {
    final List<Map<String, dynamic>> physicalSliders = [
      {'title': 'Diarrhea', 'value': _diarrheaValue},
      {'title': 'Fatigue', 'value': _fatigueValue},
      {'title': 'Shortness of Breath', 'value': _shortnessOfBreathValue},
      {'title': 'Appetite', 'value': _appetiteValue},
      {'title': 'Coughing', 'value': _coughingValue},
      {'title': 'Well-being', 'value': _wellBeingValue},
    ];

    final List<Map<String, dynamic>> emotionalSliders = [
      {'title': 'Nausea', 'value': _nauseaValue},
      {'title': 'Depression', 'value': _depressionValue},
      {'title': 'Anxiety', 'value': _anxietyValue},
      {'title': 'Drowsiness', 'value': _drowsinessValue},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Physical Symptoms
        const Text(
          'Physical',
          style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              fontFamily: "Outfit"),
        ),
        const SizedBox(height: 10),
        ...physicalSliders.map((slider) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slider['title'],
                  style: const TextStyle(
                      fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // Slider widget
                    Expanded(
                      child: Slider(
                        value: slider['value'].toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: slider['value'].toString(),
                        activeColor: AppColors.neon,
                        onChanged: (value) {
                          setState(() {
                            // Update slider value
                            if (slider['title'] == 'Diarrhea') {
                              _diarrheaValue = value.toInt();
                            }
                            if (slider['title'] == 'Fatigue') {
                              _fatigueValue = value.toInt();
                            }
                            if (slider['title'] == 'Shortness of Breath') {
                              _shortnessOfBreathValue = value.toInt();
                            }
                            if (slider['title'] == 'Appetite') {
                              _appetiteValue = value.toInt();
                            }
                            if (slider['title'] == 'Coughing') {
                              _coughingValue = value.toInt();
                            }
                            if (slider['title'] == 'Well-being') {
                              _wellBeingValue = value.toInt();
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Dropdown beside the slider
                    DropdownButton<int>(
                      dropdownColor: AppColors.white,
                      value: slider['value'],
                      items: List.generate(11, (index) => index).map((value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          if (slider['title'] == 'Diarrhea') {
                            _diarrheaValue = value!;
                          }
                          if (slider['title'] == 'Fatigue') {
                            _fatigueValue = value!;
                          }
                          if (slider['title'] == 'Shortness of Breath') {
                            _shortnessOfBreathValue = value!;
                          }
                          if (slider['title'] == 'Appetite') {
                            _appetiteValue = value!;
                          }
                          if (slider['title'] == 'Coughing') {
                            _coughingValue = value!;
                          }
                          if (slider['title'] == 'Well-being') {
                            _wellBeingValue = value!;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 20.0),
        const Divider(thickness: 1.0),
        const SizedBox(height: 20.0),

        // Emotional Symptoms
        const Text(
          'Emotional',
          style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              fontFamily: "Outfit"),
        ),
        const SizedBox(height: 10),
        ...emotionalSliders.map((slider) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slider['title'],
                  style: const TextStyle(
                      fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // Slider widget
                    Expanded(
                      child: Slider(
                        value: slider['value'].toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: slider['value'].toString(),
                        activeColor: AppColors.purple,
                        onChanged: (value) {
                          setState(() {
                            // Update slider value
                            if (slider['title'] == 'Nausea') {
                              _nauseaValue = value.toInt();
                            }
                            if (slider['title'] == 'Depression') {
                              _depressionValue = value.toInt();
                            }
                            if (slider['title'] == 'Anxiety') {
                              _anxietyValue = value.toInt();
                            }
                            if (slider['title'] == 'Drowsiness') {
                              _drowsinessValue = value.toInt();
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Dropdown beside the slider
                    DropdownButton<int>(
                      dropdownColor: AppColors.white,
                      value: slider['value'].toInt(),
                      items: List.generate(11, (index) => index).map((value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          if (slider['title'] == 'Nausea') {
                            _nauseaValue = value!;
                          }
                          if (slider['title'] == 'Depression') {
                            _depressionValue = value!;
                          }
                          if (slider['title'] == 'Anxiety') {
                            _anxietyValue = value!;
                          }
                          if (slider['title'] == 'Drowsiness') {
                            _drowsinessValue = value!;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _submit(String uid) async {
    if (!_formKey.currentState!.validate()) {
      // Validation failed, show error SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please correct the highlighted errors in the vitals form.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userData = await DatabaseService(uid: uid).getUserData();
    if (userData == null) {
      debugPrint('Submit Algo Input No User Data');
      return;
    }

    // Set algo inputs
    _algoInputs['Fever'] =
        (double.parse(_vitalInputs['Temperature']!) > maxTemperature)
            ? true
            : false;
    _algoInputs['Cough'] = (_coughingValue > maxScale) ? true : false;
    _algoInputs['Fatigue'] = (_fatigueValue > maxScale) ? true : false;
    _algoInputs['Difficulty Breathing'] =
        (_shortnessOfBreathValue > maxScale) ? true : false;
    _algoInputs['Age'] = userData.age;
    _algoInputs['Gender'] = userData.gender;

    final parts = _vitalInputs['Blood Pressure']!.split('/');
    final systolic = int.tryParse(parts[0]);
    final diastolic = int.tryParse(parts[1]);
    if (systolic! < lowBloodPressureSystolic &&
        diastolic! < lowBloodPressureDiastolic) {
      _algoInputs['Blood Pressure'] = 'Low';
    } else if (systolic < normalBloodPressureSystolic &&
        diastolic! < normalBloodPressureDiastolic) {
      _algoInputs['Blood Pressure'] = 'Normal';
    } else {
      _algoInputs['Blood Pressure'] = 'High';
    }

    double cl = double.parse(_vitalInputs['Cholesterol Level']!);
    if (cl < lowCholesterol) {
      _algoInputs['Cholesterol Level'] = 'Low';
    } else if (cl < normalCholesterol) {
      _algoInputs['Cholesterol Level'] = 'Normal';
    } else {
      _algoInputs['Cholesterol Level'] = 'High';
    }

    // Only after successful validation, prepare data
    _combinedInputs = {
      'Vitals': _vitalInputs,
      'Symptom Assessment': {
        'Diarrhea': _diarrheaValue,
        'Fatigue': _fatigueValue,
        'Shortness of Breath': _shortnessOfBreathValue,
        'Appetite': _appetiteValue,
        'Coughing': _coughingValue,
        'Well-being': _wellBeingValue,
        'Nausea': _nauseaValue,
        'Depression': _depressionValue,
        'Anxiety': _anxietyValue,
        'Drowsiness': _drowsinessValue,
      },
    };

    // Navigate to the summary screen
    try {
      FocusScope.of(context).unfocus();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptScreen(
            uid: uid,
            inputs: _combinedInputs,
            algoInputs: _algoInputs,
          ),
        ),
      );
      checkAndResetOptions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    }
  }
}
