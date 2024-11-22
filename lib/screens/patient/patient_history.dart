// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/screens/patient/chart_generator.dart';
import 'package:solace/themes/colors.dart'; // Make sure to import your chart

class PatientHistory extends StatefulWidget {
  const PatientHistory({super.key});

  @override
  PatientHistoryState createState() => PatientHistoryState();
}

class PatientHistoryState extends State<PatientHistory> {
  String _selectedTimeFrame = 'This Week'; // Declare selected timeframe
  bool _isLoading = false; // Track loading state
  List<DateTime> timestamps = [];
  List<double> bloodPressure = [];
  List<double> heartRate = [];
  List<double> temperature = [];
  List<double> weight = [];
  List<double> bloodOxygen = [];

  @override
  void initState() {
    super.initState();
    _fetchVitalsData(); // Fetch vitals when the screen is initialized
  }

  DateTime getStartOfWeek(DateTime date) {
    final dayOfWeek = date.weekday;
    final daysToSubtract = dayOfWeek - DateTime.monday;
    return date.subtract(Duration(days: daysToSubtract));
  }

  DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime getEndOfMonth(DateTime date) {
    final nextMonth = date.month == 12 ? 1 : date.month + 1;
    final nextMonthFirstDay = DateTime(date.year, nextMonth, 1);
    return nextMonthFirstDay.subtract(Duration(days: 1));
  }

  List<DateTime> filterTimestamps(List<DateTime> timestamps, String timeFrame) {
    DateTime now = DateTime.now();
    if (timeFrame == 'This Week') {
      DateTime startOfWeek = getStartOfWeek(now);
      return timestamps.where((timestamp) => timestamp.isAfter(startOfWeek)).toList();
    } else if (timeFrame == 'This Month') {
      DateTime startOfMonth = getStartOfMonth(now);
      DateTime endOfMonth = getEndOfMonth(now);
      return timestamps.where((timestamp) => timestamp.isAfter(startOfMonth) && timestamp.isBefore(endOfMonth)).toList();
    } else {
      return timestamps; // 'All Time' - no filtering
    }
  }

  Future<void> _fetchVitalsData() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('User is not logged in');
        return;
      }

      final patientId = user.uid; // Patient's UID

      final snapshot = await FirebaseFirestore.instance
          .collection('tracking')
          .doc(patientId)
          .get();

      if (!snapshot.exists) {
        debugPrint('Patient document not found');
        return;
      }

      debugPrint('Fetched document: ${snapshot.data()}'); // Print the document to see its structure

      final trackingData = snapshot.data()?['tracking']; // Access the 'tracking' array
      if (trackingData == null) {
        debugPrint('No tracking data found');
        return;
      }

      List<DateTime> timestamps = [];
      List<double> bloodPressure = [];
      List<double> heartRate = [];
      List<double> temperature = [];
      List<double> weight = [];
      List<double> bloodOxygen = [];

      // Iterate over the tracking data
      for (var track in trackingData) {
        final vitals = track['Vitals']; // Access the 'Vitals' field
        final timestamp = track['timestamp']; // Access the 'timestamp'

        // Debugging the extracted data
        debugPrint('Vitals: $vitals');
        debugPrint('Timestamp: $timestamp');

        if (timestamp != null) {
          // Parse the timestamp from Firestore Timestamp
          final parsedTimestamp = (timestamp as Timestamp).toDate();
          timestamps.add(parsedTimestamp);
        }

        // Extract individual vitals and add them to their respective lists
        if (vitals != null) {
          // Blood Pressure is in the format "120/80", so we'll split it
          final bloodPressureValue = vitals['Blood Pressure'];
          if (bloodPressureValue != null && bloodPressureValue is String) {
            final parts = bloodPressureValue.split('/');
            if (parts.length == 2) {
              final systolic = double.tryParse(parts[0]);
              final diastolic = double.tryParse(parts[1]);
              if (systolic != null && diastolic != null) {
                // Store the average of systolic and diastolic values
                bloodPressure.add((systolic + diastolic) / 2);
              }
            }
          }

          // For the rest of the vitals, just store the numerical values
          final heartRateValue = vitals['Heart Rate'];
          if (heartRateValue != null && heartRateValue is String) {
            final parsedHeartRate = double.tryParse(heartRateValue);
            if (parsedHeartRate != null) {
              heartRate.add(parsedHeartRate);
            } else {
              debugPrint('Invalid heart rate value: $heartRateValue');
            }
          }

          final temperatureValue = vitals['Temperature'];
          if (temperatureValue != null && temperatureValue is String) {
            final parsedTemperature = double.tryParse(temperatureValue);
            if (parsedTemperature != null) {
              temperature.add(parsedTemperature);
            } else {
              debugPrint('Invalid temperature value: $temperatureValue');
            }
          }

          final weightValue = vitals['Weight'];
          if (weightValue != null && weightValue is String) {
            final parsedWeight = double.tryParse(weightValue);
            if (parsedWeight != null) {
              weight.add(parsedWeight);
            } else {
              debugPrint('Invalid weight value: $weightValue');
            }
          }

          // Parsing for Blood Oxygen (with tryParse)
          final bloodOxygenValue = vitals['Blood Oxygen'];
          if (bloodOxygenValue != null && bloodOxygenValue is String) {
            final parsedBloodOxygen = double.tryParse(bloodOxygenValue);
            if (parsedBloodOxygen != null) {
              bloodOxygen.add(parsedBloodOxygen);
            } else {
              debugPrint('Invalid blood oxygen value: $bloodOxygenValue');
            }
          }
        }
      }

      debugPrint('Fetched vitals:');
      debugPrint('Timestamps: $timestamps');
      debugPrint('Blood Pressure: $bloodPressure');
      debugPrint('Heart Rate: $heartRate');
      debugPrint('Temperature: $temperature');
      debugPrint('Weight: $weight');
      debugPrint('Blood Oxygen: $bloodOxygen');

      // Trigger UI update
      setState(() {
        this.timestamps = timestamps; // Assign fetched timestamps
        this.bloodPressure = bloodPressure;
        this.heartRate = heartRate;
        this.temperature = temperature;
        this.weight = weight;
        this.bloodOxygen = bloodOxygen;
        _isLoading = false; // Stop loading
      });

      // Display a Snackbar indicating that the data is fetched
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data fetched successfully!")),
      );
    } catch (e) {
      debugPrint('Error fetching vitals data: $e');
      setState(() {
        _isLoading = false; // Stop loading on error
      });

      // Display an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch data!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter vitals data based on selected time frame
    List<DateTime> filteredTimestamps = filterTimestamps(timestamps, _selectedTimeFrame);
    List<double> filteredBloodPressure = filterVitalsData(filteredTimestamps, bloodPressure);
    List<double> filteredHeartRate = filterVitalsData(filteredTimestamps, heartRate);
    List<double> filteredTemperature = filterVitalsData(filteredTimestamps, temperature);
    List<double> filteredWeight = filterVitalsData(filteredTimestamps, weight);
    List<double> filteredBloodOxygen = filterVitalsData(filteredTimestamps, bloodOxygen);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Frame selection radio buttons
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

              const Text(
                'Blood Pressure',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 20.0),

              // Show loading indicator if data is being fetched
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  ChartTesting(
                    vitalArray: filteredBloodPressure,
                    timestampArray: filteredTimestamps,
                  ),
                  const SizedBox(height: 20.0),

                  const Text(
                    'Heart Rate',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  ChartTesting(
                    vitalArray: filteredHeartRate,
                    timestampArray: filteredTimestamps,
                  ),
                  const SizedBox(height: 20.0),

                  const Text(
                    'Temperature',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  ChartTesting(
                    vitalArray: filteredTemperature,
                    timestampArray: filteredTimestamps,
                  ),
                  const SizedBox(height: 20.0),

                  const Text(
                    'Weight',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  ChartTesting(
                    vitalArray: filteredWeight,
                    timestampArray: filteredTimestamps,
                  ),
                  const SizedBox(height: 20.0),

                  const Text(
                    'Blood Oxygen',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  ChartTesting(
                    vitalArray: filteredBloodOxygen,
                    timestampArray: filteredTimestamps,
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to create radio button
  Widget _buildRadioButton(String title) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Immediately update the selected button color
          setState(() {
            _selectedTimeFrame = title;
          });
          // Then fetch data asynchronously
          _fetchVitalsData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
          decoration: BoxDecoration(
            color: _selectedTimeFrame == title ? AppColors.neon : AppColors.purple,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.white,
                fontFamily: 'Inter',
                fontWeight: _selectedTimeFrame == title
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 16.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to filter vitals based on timestamps
  List<double> filterVitalsData(List<DateTime> filteredTimestamps, List<double> vitalData) {
    return List.generate(filteredTimestamps.length, (index) {
      final timestamp = filteredTimestamps[index];
      final indexInAllData = timestamps.indexOf(timestamp);
      return vitalData[indexInAllData];
    });
  }
}

