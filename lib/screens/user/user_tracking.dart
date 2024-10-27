import 'package:flutter/material.dart';

class UserTracking extends StatelessWidget {
  const UserTracking({super.key});

  // Function to show the input dialog
  void _showInputDialog(BuildContext context, String title) {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter $title'),
          content: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '$title Value',
              hintText: 'Enter $title',
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
              onPressed: () {
                // Process the input here, for example:
                print('$title: ${_controller.text}');
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _showInputDialog(context, 'Heart Rate'),
              child: Text('Heart Rate'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showInputDialog(context, 'Blood Pressure'),
              child: Text('Blood Pressure'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showInputDialog(context, 'Temperature'),
              child: Text('Temperature'),
            ),
          ],
        ),
      ),
    );
  }
}
