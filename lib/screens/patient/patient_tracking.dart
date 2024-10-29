// ignore_for_file: avoid_print, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart'; // Assuming AppColors is defined here

class PatientTracking extends StatefulWidget {
  const PatientTracking({super.key});

  @override
  PatientTrackingState createState() => PatientTrackingState();
}

class PatientTrackingState extends State<PatientTracking> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State variables to track the value of each slider
  double _painValue = 5.0;
  double _exhaustionValue = 5.0;
  double _nauseaValue = 5.0;
  double _depressionValue = 5.0;
  double _anxietyValue = 5.0;
  double _drowsinessValue = 5.0;
  double _appetiteValue = 5.0;
  double _wellBeingValue = 5.0;
  double _shortnessOfBreathValue = 5.0;

  // State variables for vital inputs
  final Map<String, String> _vitalInputs = {
    'Heart Rate': '',
    'Blood Pressure': '',
    'Blood Oxygen': '',
    'Temperature': '',
    'Weight': '',
  };

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title for Vitals Section
            const Text(
              'Vitals',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 20.0),

            // Wrap for Vitals Buttons
            Center(
              child: Wrap(
                spacing: 10.0, // Space between buttons
                runSpacing: 20.0, // Space between rows
                alignment: WrapAlignment.center, // Center align all buttons
                children: [
                  _buildVitalsButton(
                      'Heart Rate',
                      'lib/assets/images/shared/vitals/heart_rate.png',
                      AppColors.blue,
                      context,
                      user!.uid),
                  _buildVitalsButton(
                      'Blood Pressure',
                      'lib/assets/images/shared/vitals/blood_pressure.png',
                      AppColors.purple,
                      context,
                      user.uid),
                  _buildVitalsButton(
                      'Blood Oxygen',
                      'lib/assets/images/shared/vitals/blood_oxygen.png',
                      AppColors.neon,
                      context,
                      user.uid),
                  _buildVitalsButton(
                      'Temperature',
                      'lib/assets/images/shared/vitals/temperature.png',
                      AppColors.red,
                      context,
                      user.uid),
                  _buildVitalsButton(
                      'Weight',
                      'lib/assets/images/shared/vitals/weight.png',
                      AppColors.darkblue,
                      context,
                      user.uid),
                ],
              ),
            ),

            const SizedBox(height: 20.0),

            // Horizontal Line Separator
            const Divider(thickness: 1.0),

            const SizedBox(height: 20.0),

            // Title for Pain Assessment Section
            const Text(
              'Pain Assessment',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 10.0),

            // Scrollable Container for Sliders
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPainSlider('Pain', AppColors.neon, _painValue,
                            (value) => setState(() => _painValue = value)),
                    _buildPainSlider(
                        'Exhaustion',
                        AppColors.neon,
                        _exhaustionValue,
                            (value) => setState(() => _exhaustionValue = value)),
                    _buildPainSlider('Nausea', AppColors.neon, _nauseaValue,
                            (value) => setState(() => _nauseaValue = value)),
                    _buildPainSlider(
                        'Depression',
                        AppColors.blue,
                        _depressionValue,
                            (value) => setState(() => _depressionValue = value)),
                    _buildPainSlider('Anxiety', AppColors.blue, _anxietyValue,
                            (value) => setState(() => _anxietyValue = value)),
                    _buildPainSlider(
                        'Drowsiness',
                        AppColors.blue,
                        _drowsinessValue,
                            (value) => setState(() => _drowsinessValue = value)),
                    _buildPainSlider(
                        'Appetite',
                        AppColors.purple,
                        _appetiteValue,
                            (value) => setState(() => _appetiteValue = value)),
                    _buildPainSlider(
                        'Feeling of Well-being',
                        AppColors.purple,
                        _wellBeingValue,
                            (value) => setState(() => _wellBeingValue = value)),
                    _buildPainSlider(
                        'Shortness of Breath',
                        AppColors.purple,
                        _shortnessOfBreathValue,
                            (value) =>
                            setState(() => _shortnessOfBreathValue = value)),

                    // Submit button
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: _submit,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 10),
                        backgroundColor: AppColors.neon, // Set background color
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.white, // Set button text color
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to build each vitals button
  Widget _buildVitalsButton(
      String title, String iconPath, Color color, BuildContext context, String uid) {
    return GestureDetector(
      onTap: () {
        // Open modal for input related to the vitals measure
        _showInputModal(context, title, uid);
      },
      child: SizedBox(
        width: 90.0,
        height: 90.0,
        child: Column(
          children: [
            Container(
              width: 60.0,
              height: 60.0,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding:
                const EdgeInsets.all(16.0), // Padding inside the container
                child: Image.asset(iconPath),
              ),
            ),
            const SizedBox(height: 5.0), // Spacing between container and text
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12.0,
                fontWeight: FontWeight.normal,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPainSlider(String title, Color color, double currentValue, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                Slider(
                  value: currentValue,
                  min: 1.0,
                  max: 10.0,
                  divisions: 9,
                  activeColor: color,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0), // Space between slider and dropdown
          // Enhanced dropdown styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: AppColors.white, // Soft background for dropdown
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: AppColors.blackTransparent, width: 1.5),
            ),
            child: DropdownButton<int>(
              elevation: 0,
              value: currentValue.toInt(),
              items: List.generate(10, (index) => index + 1)
                  .map((value) => DropdownMenuItem(
                value: value,
                child: Text(
                  value.toString(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value.toDouble());
                }
              },
              dropdownColor: Colors.white,
              underline: SizedBox.shrink(), // Remove underline
            ),
          ),
        ],
      ),
    );
  }


  // Function to show modal for input related to vitals measure
  void _showInputModal(BuildContext context, String title, String uid) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title), // Keep this as it is
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Enter your $title'), // Remove const here
              validator: (val) {
                // Check if the field is empty
                if (val!.isEmpty) {
                  return "Field should not be empty";
                }
                // Check if the input contains only digits
                // if (!RegExp(r'^\d+$').hasMatch(val)) {
                //   return "Input must be a number";
                // }
                return null; // Valid input
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Validate the form
                if (_formKey.currentState!.validate()) {
                  _vitalInputs[title] = controller.text;
                  String vital = '';

                  // Update the corresponding variable based on the title
                  if (title == 'Heart Rate') {
                    vital = 'heart_rate';
                  } else if (title == 'Blood Pressure') {
                    vital = 'blood_pressure';
                  } else if (title == 'Temperature') {
                    vital = 'temperature';
                  }

                  double value = double.parse(controller.text);

                  print('To add vital: $uid');
                  await DatabaseService(uid: uid).addVitalRecord(vital, value);

                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: const Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Function to handle submit button
  void _submit() {
    // ignore: avoid_print
    print('Pain Assessment:');
    print('Pain: $_painValue');
    print('Exhaustion: $_exhaustionValue');
    print('Nausea: $_nauseaValue');
    print('Depression: $_depressionValue');
    print('Anxiety: $_anxietyValue');
    print('Drowsiness: $_drowsinessValue');
    print('Appetite: $_appetiteValue');
    print('Feeling of Well-being: $_wellBeingValue');
    print('Shortness of Breath: $_shortnessOfBreathValue');

    // Print all vital inputs
    print('Vital Inputs:');
    _vitalInputs.forEach((key, value) {
      print('$key: $value');
    });

    // Here, you can also add logic to send this data to your backend or other processing
  }
}
