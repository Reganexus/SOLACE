// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/patient/input_summary.dart';
import 'package:solace/shared/globals.dart';
import 'package:solace/themes/colors.dart'; // Assuming AppColors is defined here

class PatientTracking extends StatefulWidget {
  const PatientTracking({super.key});

  @override
  PatientTrackingState createState() => PatientTrackingState();
}

class PatientTrackingState extends State<PatientTracking> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State variables for all inputs
  final Map<String, String> _vitalInputs = {
    'Heart Rate': '',
    'Blood Pressure': '',
    'Oxygen Saturation': '',
    'Respiration': '',
    'Temperature': '',
    'Pain': '',
  };

  int _diarrheaValue = 0;
  int _fatigueValue = 0;
  int _nauseaValue = 0;
  int _depressionValue = 0;
  int _anxietyValue = 0;
  int _drowsinessValue = 0;
  int _appetiteValue = 0;
  int _wellBeingValue = 0;
  int _shortnessOfBreathValue = 0;

  late Map<String, dynamic> _combinedInputs; // Holds data for submission

  final FocusNode _bloodPressureFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Vitals',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 20.0),
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: TextFormField(
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
                  final regex = RegExp(r'^\d{2,3}\/\d{2,3}$');
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
              fontSize: 20.0, fontWeight: FontWeight.bold, fontFamily: "Outfit"),
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
              fontSize: 20.0, fontWeight: FontWeight.bold, fontFamily: "Outfit"),
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

  void _submit(String uid) {
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

    // Only after successful validation, prepare data
    _combinedInputs = {
      'Vitals': _vitalInputs,
      'Symptom Assessment': {
        'Diarrhea': _diarrheaValue,
        'Fatigue': _fatigueValue,
        'Nausea': _nauseaValue,
        'Depression': _depressionValue,
        'Anxiety': _anxietyValue,
        'Drowsiness': _drowsinessValue,
        'Appetite': _appetiteValue,
        'Well-being': _wellBeingValue,
        'Shortness of Breath': _shortnessOfBreathValue,
      },
    };

    // Navigate to the summary screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptScreen(
          inputs: _combinedInputs,
          uid: uid,
        ),
      ),
    );
  }
}
