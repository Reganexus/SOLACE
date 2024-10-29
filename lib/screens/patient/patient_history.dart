import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart'; // Assuming AppColors is defined here

class PatientHistory extends StatefulWidget {
  const PatientHistory({super.key});

  @override
  PatientHistoryState createState() => PatientHistoryState();
}

class PatientHistoryState extends State<PatientHistory> {
  // Variable to store selected radio button value
  String _selectedTimeFrame = 'This Week';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio Buttons for Sorting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRadioButton('This Week'),
                const SizedBox(width: 10.0),
                _buildRadioButton('This Month'),
                const SizedBox(width: 10.0),
                _buildRadioButton('All Time'),
              ],
            ),
            const SizedBox(height: 20.0),

            // Scrollable Container for Graphs
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Placeholder for Graph 1
                    _buildGraphPlaceholder('Graph 1'),
                    const SizedBox(height: 20.0),

                    // Placeholder for Graph 2
                    _buildGraphPlaceholder('Graph 2'),
                    const SizedBox(height: 20.0),

                    _buildGraphPlaceholder('Graph 3'),
                    const SizedBox(height: 20.0),

                    _buildGraphPlaceholder('Graph 4'),
                    const SizedBox(height: 20.0),

                    _buildGraphPlaceholder('Graph 5'),
                    const SizedBox(height: 20.0),
                    // Additional placeholders can be added here
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to create radio button
  Widget _buildRadioButton(String title) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTimeFrame = title; // Update selected time frame
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
          decoration: BoxDecoration(
            color: _selectedTimeFrame == title
                ? AppColors.neon
                : AppColors.darkpurple,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: _selectedTimeFrame == title
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 14.0,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget to create graph placeholder
  Widget _buildGraphPlaceholder(String graphTitle) {
    return Container(
      height: 200.0, // Height for the graph placeholder
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10.0),
      ),
      alignment: Alignment.center,
      child: Text(
        graphTitle,
        style: const TextStyle(
          fontSize: 20.0,
          color: Colors.white,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
