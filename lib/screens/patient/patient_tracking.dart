// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/input_summary.dart';
import 'package:solace/themes/colors.dart'; // Assuming AppColors is defined here
import 'dart:convert';
import 'package:http/http.dart' as http;

class PatientTracking extends StatefulWidget {
  const PatientTracking({super.key});

  @override
  PatientTrackingState createState() => PatientTrackingState();
}

class PatientTrackingState extends State<PatientTracking> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyAlgo = GlobalKey<FormState>();
  final DatabaseService databaseService = DatabaseService();
  String _predictionResult = "Press the button to get a prediction";

  // State variables for all inputs
  final Map<String, String> _vitalInputs = {
    'Heart Rate': '',
    'Blood Pressure': '',
    'Blood Oxygen': '',
    'Temperature': '',
    'Weight': '',
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

  double _painValue = 5.0;
  double _exhaustionValue = 5.0;
  double _nauseaValue = 5.0;
  double _depressionValue = 5.0;
  double _anxietyValue = 5.0;
  double _drowsinessValue = 5.0;
  double _appetiteValue = 5.0;
  double _wellBeingValue = 5.0;
  double _shortnessOfBreathValue = 5.0;

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
                  'Algo Inputs',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 20.0),
                _buildAlgoInputs(),
                const SizedBox(height: 20.0),
                Text(_predictionResult),
                const SizedBox(height: 20.0),
                Center(
                  child: TextButton(
                    onPressed: () => _submitAlgoInputs(user!.uid),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 10),
                      backgroundColor: AppColors.neon,
                    ),
                    child: const Text(
                      'Submit Algo Inputs',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                const Divider(thickness: 1.0),
                const SizedBox(height: 20.0),
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
                  'Pain Assessment',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 10.0),
                _buildPainSliders(),
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

  Widget _buildAlgoInputs() {
    return Form(
      key: _formKeyAlgo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boolean inputs
          const Text(
            'Symptoms:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ...["Fever", "Cough", "Fatigue", "Difficulty Breathing"].map((key) {
            return CheckboxListTile(
              title: Text(key),
              value: _algoInputs[key] as bool,
              onChanged: (value) {
                setState(() {
                  _algoInputs[key] = value ?? false;
                });
              },
            );
          }),
          const SizedBox(height: 20),

          // Dropdown inputs for Blood Pressure and Cholesterol Level
          ...["Blood Pressure", "Cholesterol Level"].map((key) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: key,
                  border: OutlineInputBorder(),
                ),
                value: _algoInputs[key], // Set the current value
                items: [
                  DropdownMenuItem(value: "Low", child: Text("Low")),
                  DropdownMenuItem(value: "Normal", child: Text("Normal")),
                  DropdownMenuItem(value: "High", child: Text("High")),
                ],
                onChanged: (value) {
                  setState(() {
                    _algoInputs[key] = value; // Update the state
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select $key';
                  }
                  return null;
                },
              ),
            );
          }),
        ],
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

  Widget _buildPainSliders() {
    final List<Map<String, dynamic>> sliders = [
      {'title': 'Pain', 'value': _painValue},
      {'title': 'Exhaustion', 'value': _exhaustionValue},
      {'title': 'Nausea', 'value': _nauseaValue},
      {'title': 'Depression', 'value': _depressionValue},
      {'title': 'Anxiety', 'value': _anxietyValue},
      {'title': 'Drowsiness', 'value': _drowsinessValue},
      {'title': 'Appetite', 'value': _appetiteValue},
      {'title': 'Well-being', 'value': _wellBeingValue},
      {'title': 'Shortness of Breath', 'value': _shortnessOfBreathValue},
    ];

    return Column(
      children: sliders.map((slider) {
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
                      value: slider['value'],
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: slider['value'].toString(),
                      activeColor: AppColors.neon,
                      onChanged: (value) {
                        setState(() {
                          // Update slider value
                          if (slider['title'] == 'Pain') _painValue = value;
                          if (slider['title'] == 'Exhaustion') {
                            _exhaustionValue = value;
                          }
                          if (slider['title'] == 'Nausea') _nauseaValue = value;
                          if (slider['title'] == 'Depression') {
                            _depressionValue = value;
                          }
                          if (slider['title'] == 'Anxiety') {
                            _anxietyValue = value;
                          }
                          if (slider['title'] == 'Drowsiness') {
                            _drowsinessValue = value;
                          }
                          if (slider['title'] == 'Appetite') {
                            _appetiteValue = value;
                          }
                          if (slider['title'] == 'Well-being') {
                            _wellBeingValue = value;
                          }
                          if (slider['title'] == 'Shortness of Breath') {
                            _shortnessOfBreathValue = value;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(
                      width: 20), // Space between Slider and Dropdown
                  // Dropdown beside the slider
                  DropdownButton<int>(
                    dropdownColor: AppColors.white,
                    value: slider['value']
                        .toInt(), // Show slider value in dropdown
                    items: List.generate(10, (index) => index + 1).map((value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        // Update slider value when dropdown value changes
                        if (slider['title'] == 'Pain') {
                          _painValue = value!.toDouble();
                        }
                        if (slider['title'] == 'Exhaustion') {
                          _exhaustionValue = value!.toDouble();
                        }
                        if (slider['title'] == 'Nausea') {
                          _nauseaValue = value!.toDouble();
                        }
                        if (slider['title'] == 'Depression') {
                          _depressionValue = value!.toDouble();
                        }
                        if (slider['title'] == 'Anxiety') {
                          _anxietyValue = value!.toDouble();
                        }
                        if (slider['title'] == 'Drowsiness') {
                          _drowsinessValue = value!.toDouble();
                        }
                        if (slider['title'] == 'Appetite') {
                          _appetiteValue = value!.toDouble();
                        }
                        if (slider['title'] == 'Well-being') {
                          _wellBeingValue = value!.toDouble();
                        }
                        if (slider['title'] == 'Shortness of Breath') {
                          _shortnessOfBreathValue = value!.toDouble();
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
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
    } else if (_formKeyAlgo.currentState!.validate()) {
      try {
        // Combine and format the algo inputs
        final timestamp = Timestamp.now();

        final combinedInputs = {
          'timestamp': timestamp,
          'Fever': _algoInputs['Fever'],
          'Cough': _algoInputs['Cough'],
          'Fatigue': _algoInputs['Fatigue'],
          'Difficulty Breathing': _algoInputs['Difficulty Breathing'],
          'Age': userData.age,
          'Gender': userData.gender,
          'Blood Pressure': _algoInputs['Blood Pressure'],
          'Cholesterol Level': _algoInputs['Cholesterol Level'],
        };

        // Reference to the user's document in the 'tracking' collection
        final trackingRef = FirebaseFirestore.instance.collection('tracking').doc(uid);

        // Get the document snapshot
        final docSnapshot = await trackingRef.get();

        List<dynamic> algoInputs = [];

        if (docSnapshot.exists) {
          // Ensure 'algo' exists and is a List
          if (docSnapshot['algo'] is List) {
            algoInputs = List.from(docSnapshot['algo']);
          } else {
            debugPrint("Algo field is not a list or is missing.");
            algoInputs = []; // Initialize as empty list
          }

          // Update 'algo' field
          await trackingRef.update({
            'algo': FieldValue.arrayUnion([combinedInputs]),
          });
        } else {
          // Initialize 'algo' field if document doesn't exist
          await trackingRef.set({
            'algo': [combinedInputs],
          });
          algoInputs = [combinedInputs];  // Add initial input
        }

        // If there are fewer than 10 inputs, repeat the last one
        if (algoInputs.length < 10) {
          final latestInput = algoInputs.isNotEmpty ? algoInputs.last : combinedInputs;
          while (algoInputs.length < 10) {
            algoInputs.add(latestInput);
          }
        }

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
  
  void _submit(String uid) {
    if (_formKey.currentState!.validate()) {
      // Only after successful validation, prepare data
      _combinedInputs = {
        'Vitals': _vitalInputs,
        'Pain Assessment': {
          'Pain': _painValue,
          'Exhaustion': _exhaustionValue,
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

  Future<void> getPrediction(List<dynamic> algoInputs) async {
    // choose from these depending on testing device
    final localHostAddress = '127.0.0.1'; // default
    final virtualAddress = '10.0.2.2';    // if using virtual device
    // if using physical device, use computer’s IP address instead of 127.0.0.1 or localhost.

    final url = Uri.parse('http://$virtualAddress:5000/predict');
    final headers = {"Content-Type": "application/json"};

    // Define mappings for Blood Pressure and Cholesterol Level
    const bloodPressureMapping = {
      "Low": -2.347682445195591,
      "Normal": -0.6882095111211662,
      "High": 0.9712634229532582,
    };

    const cholesterolMapping = {
      "Low": -2.0753216368811644,
      "Normal": -0.5544364176961935,
      "High": 0.9664488014887777,
    };

    // Format algoInputs to match the input size expected by the model (6 features)
    List<List<double>> formattedInputs = algoInputs.map((input) {
      return [
        input['Fever'] ? 1.0 : 0.0,
        input['Cough'] ? 1.0 : 0.0,
        input['Fatigue'] ? 1.0 : 0.0,
        input['Difficulty Breathing'] ? 1.0 : 0.0,
        // double.parse(input['Age'].toString()),
        // input['Gender'] == 'Male' ? 1.0 : 0.0,
        bloodPressureMapping[input['Blood Pressure']] ?? 0.0,
        cholesterolMapping[input['Cholesterol Level']] ?? 0.0,
      ];
    }).toList();

    debugPrint('Formatted Inputs: $formattedInputs');

    try {
      // Wrap formattedInputs in a JSON object with the 'data' key
      final body = json.encode({'data': [formattedInputs]});

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      debugPrint("Json body: $body");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final String status = responseData['prediction'][0] == 0 ? "Stable" : "Unstable";
        debugPrint("Status: ${responseData['prediction']}  Type: ${(responseData['prediction']).runtimeType}");
        setState(() {
          _predictionResult = "Status: $status";
        });
        // set status to either stable or unstable here
      } else {
        setState(() {
          _predictionResult = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _predictionResult = "Error: $e";
      });
    }
  }
}
