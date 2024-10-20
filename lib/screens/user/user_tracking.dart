// ignore_for_file: avoid_print, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart'; // Assuming AppColors is defined here

class UserTrackingScreen extends StatefulWidget {
  const UserTrackingScreen({super.key});

  @override
  UserTrackingScreenState createState() => UserTrackingScreenState();
}

class UserTrackingScreenState extends State<UserTrackingScreen> {
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
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
            const SizedBox(height: 10.0),

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
                      context),
                  _buildVitalsButton(
                      'Blood Pressure',
                      'lib/assets/images/shared/vitals/blood_pressure.png',
                      AppColors.purple,
                      context),
                  _buildVitalsButton(
                      'Blood Oxygen',
                      'lib/assets/images/shared/vitals/blood_oxygen.png',
                      AppColors.neon,
                      context),
                  _buildVitalsButton(
                      'Temperature',
                      'lib/assets/images/shared/vitals/temperature.png',
                      AppColors.red,
                      context),
                  _buildVitalsButton(
                      'Weight',
                      'lib/assets/images/shared/vitals/weight.png',
                      AppColors.darkblue,
                      context),
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
      String title, String iconPath, Color color, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Open modal for input related to the vitals measure
        _showInputModal(context, title);
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

  // Function to build each pain assessment slider
  Widget _buildPainSlider(String title, Color color, double currentValue,
      ValueChanged<double> onChanged) {
    TextEditingController controller =
        TextEditingController(text: currentValue.toStringAsFixed(0));

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
                  value:
                      currentValue, // The current value is now managed by state
                  min: 1.0,
                  max: 10.0,
                  divisions: 9,
                  activeColor: color,
                  onChanged: (value) {
                    onChanged(value);
                    controller.text =
                        value.toStringAsFixed(0); // Update input field value
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0), // Spacing between slider and text input
          SizedBox(
            width: 50.0, // Fixed width for input field
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 5.0),
              ),
              onChanged: (value) {
                if (double.tryParse(value) != null) {
                  double newValue = double.parse(value);
                  if (newValue >= 1.0 && newValue <= 10.0) {
                    onChanged(newValue);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Function to show modal for input related to vitals measure
  void _showInputModal(BuildContext context, String title) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title), // Keep this as it is
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: 'Enter your $title'), // Remove const here
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _vitalInputs[title] =
                      controller.text; // Store the input value
                });
                Navigator.of(context).pop();
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
