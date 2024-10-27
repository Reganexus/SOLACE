import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:flutter/material.dart';

class UserTracking extends StatefulWidget {
  UserTracking({super.key});

  @override
  State<UserTracking> createState() => _UserTrackingState();
}

class _UserTrackingState extends State<UserTracking> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int heartRate = 0;
  int bloodPressure = 0;
  int temperature = 0;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);
    return Scaffold(
      backgroundColor: Colors.purple[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _showInputDialog(context, 'Heart Rate', user!.uid),
              child: Text('Heart Rate'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showInputDialog(context, 'Blood Pressure', user!.uid),
              child: Text('Blood Pressure'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showInputDialog(context, 'Temperature', user!.uid),
              child: Text('Temperature'),
            ),
          ],
        ),
      ),
    );
  }

  // Function to show the input dialog
  void _showInputDialog(BuildContext context, String title, String uid) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter $title'),
          content: Form(
            key: _formKey, // Assign the form key
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '$title Value',
                hintText: 'Enter $title',
              ),
              validator: (val) {
                // Check if the field is empty
                if (val!.isEmpty) {
                  return "Required";
                }
                // Check if the input contains only digits
                if (!RegExp(r'^\d+$').hasMatch(val)) {
                  return "Must be a number";
                }
                return null; // Valid input
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate the form
                if (_formKey.currentState!.validate()) {
                  int value = int.parse(controller.text); // Convert the input to an int
                  String vital = '';

                  // Update the corresponding variable based on the title
                  if (title == 'Heart Rate') {
                    heartRate = value;
                    vital = 'heart_rate';
                  } else if (title == 'Blood Pressure') {
                    bloodPressure = value;
                    vital = 'blood_pressure';
                  } else if (title == 'Temperature') {
                    temperature = value;
                    vital = 'temperature';
                  }

                  await DatabaseService(uid: uid).addVitalRecord(vital, value);

                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
