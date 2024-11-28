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
  List<double> heartRate = [];
  List<double> bloodPressure = [];
  List<double> saturation = [];
  List<double> respiration = [];
  List<double> temperature = [];
  List<double> painLevel = [];

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

    if (timeFrame == 'Every Hour') {
      // Filter data for today, per hour
      DateTime startOfDay = DateTime(now.year, now.month, now.day);  // Midnight of today
      DateTime endOfDay = startOfDay.add(Duration(days: 1)); // Start of the next day (exclusive)

      // Filter timestamps that are within today and fall within the current hour
      return timestamps.where((timestamp) {
        return timestamp.isAfter(startOfDay) && timestamp.isBefore(endOfDay) &&
            timestamp.hour == now.hour; // Ensure the hour matches the current hour
      }).toList();

    } else if (timeFrame == 'This Day') {
      // Filter data for today (same date)
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = startOfDay.add(Duration(days: 1));
      return timestamps
          .where((timestamp) => timestamp.isAfter(startOfDay) && timestamp.isBefore(endOfDay))
          .toList();

    } else if (timeFrame == 'This Week') {
      // Filter data for this week (from the start of the week to now)
      DateTime startOfWeek = getStartOfWeek(now); // Get the first Monday of the week
      DateTime endOfWeek = startOfWeek.add(Duration(days: 7)); // Sunday (end of week)

      return timestamps
          .where((timestamp) => timestamp.isAfter(startOfWeek) && timestamp.isBefore(endOfWeek))
          .toList();

    } else {
      return timestamps; // Default case: return all timestamps
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

      debugPrint(
          'Fetched document: ${snapshot.data()}'); // Print the document to see its structure

      final trackingData =
          snapshot.data()?['tracking']; // Access the 'tracking' array
      if (trackingData == null) {
        debugPrint('No tracking data found');
        return;
      }

      List<DateTime> timestamps = [];
      List<double> heartRate = [];
      List<double> bloodPressure = [];
      List<double> saturation = [];
      List<double> respiration = [];
      List<double> temperature = [];
      List<double> painLevel = [];

      // Iterate over the tracking data
      for (var track in trackingData) {
        final vitals = track['Vitals']; // Access the 'Vitals' field
        final timestamp = track['timestamp']; // Access the 'timestamp'

        if (timestamp != null) {
          // Parse the timestamp from Firestore Timestamp
          final parsedTimestamp = (timestamp as Timestamp).toDate();
          timestamps.add(parsedTimestamp);
        }

        if (vitals != null) {
          // Parse vitals values (Heart Rate, Blood Pressure, etc.)
          final heartRateValue = vitals['Heart Rate'];
          final parsedHeartRate = _parseVital(heartRateValue);
          if (parsedHeartRate != null) heartRate.add(parsedHeartRate);

          final bloodPressureValue = vitals['Blood Pressure'];
          final parsedBP = _parseVital(bloodPressureValue);
          if (parsedBP != null) bloodPressure.add(parsedBP);

          final saturationValue = vitals['Oxygen Saturation'];
          final parsedSaturation = _parseVital(saturationValue);
          if (parsedSaturation != null) saturation.add(parsedSaturation);

          final respirationValue = vitals['Respiration'];
          final parsedRespiration = _parseVital(respirationValue);
          if (parsedRespiration != null) respiration.add(parsedRespiration);

          final temperatureValue = vitals['Temperature'];
          final parsedTemperature = _parseVital(temperatureValue);
          if (parsedTemperature != null) temperature.add(parsedTemperature);

          final painLevelValue = vitals['Pain'];
          final parsedPainLevel = _parseVital(painLevelValue);
          if (parsedPainLevel != null) painLevel.add(parsedPainLevel);
        }
      }

      debugPrint('Fetched vitals:');
      debugPrint('Timestamps: $timestamps');
      debugPrint('Blood Pressure: $bloodPressure');
      debugPrint('Heart Rate: $heartRate');
      debugPrint('Temperature: $temperature');
      debugPrint('Heart Rate: $respiration');
      debugPrint('Oxygen Saturation: $saturation');
      debugPrint('Pain Level: $painLevel');

      setState(() {
        // Assign fetched vitals data to the state
        this.timestamps = timestamps;
        this.bloodPressure = bloodPressure;
        this.heartRate = heartRate;
        this.temperature = temperature;
        this.saturation = saturation;
        this.respiration = respiration;
        this.painLevel = painLevel;
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

  double? _parseVital(dynamic vitalValue) {
    if (vitalValue != null && vitalValue is String) {
      // Special case for Blood Pressure
      if (vitalValue.contains('/')) {
        // Split the string into systolic and diastolic
        List<String> parts = vitalValue.split('/');
        if (parts.length == 2) {
          // Try to parse both systolic and diastolic values
          double? systolic = double.tryParse(parts[0].trim());
          double? diastolic = double.tryParse(parts[1].trim());

          // If both are valid, return a suitable representation (e.g., a List or Object)
          if (systolic != null && diastolic != null) {
            // You can store both values or calculate the average
            // For now, we'll return the systolic value, but you could return both.
            return systolic;
          }
        }
      } else {
        // Handle other vitals as usual
        return double.tryParse(vitalValue);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Filter vitals data based on selected time frame
    List<DateTime> filteredTimestamps =
        filterTimestamps(timestamps, _selectedTimeFrame);
    List<double> filteredHeartRate =
        filterVitalsData(filteredTimestamps, heartRate);
    List<double> filteredBloodPressure =
        filterVitalsData(filteredTimestamps, bloodPressure);
    List<double> filteredSaturation =
        filterVitalsData(filteredTimestamps, saturation);
    List<double> filteredRespiration =
        filterVitalsData(filteredTimestamps, respiration);
    List<double> filteredTemperature =
        filterVitalsData(filteredTimestamps, temperature);
    List<double> filteredPainLevel =
        filterVitalsData(filteredTimestamps, painLevel);

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
                  _buildRadioButton('Every Hour'),
                  const SizedBox(width: 10.0),
                  _buildRadioButton('This Day'),
                  const SizedBox(width: 10.0),
                  _buildRadioButton('This Week'),
                ],
              ),

              const SizedBox(height: 20.0),

              // Show loading indicator if data is being fetched
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align content to the left
                      children: [
                        // Blood Pressure
                        const Text(
                          'Blood Pressure',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                          textAlign: TextAlign
                              .left, // Explicitly align text to the left
                        ),
                        const SizedBox(height: 20.0),
                        ChartTesting(
                          vitalArray: filteredBloodPressure,
                          timestampArray: filteredTimestamps,
                        ),
                        const SizedBox(height: 20.0),

                        // Heart Rate
                        const Text(
                          'Heart Rate',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                          textAlign: TextAlign
                              .left, // Explicitly align text to the left
                        ),
                        const SizedBox(height: 20.0),
                        ChartTesting(
                          vitalArray: filteredHeartRate,
                          timestampArray: filteredTimestamps,
                        ),
                        const SizedBox(height: 20.0),

                        // Temperature
                        const Text(
                          'Temperature',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                          textAlign: TextAlign
                              .left, // Explicitly align text to the left
                        ),
                        const SizedBox(height: 20.0),
                        ChartTesting(
                          vitalArray: filteredTemperature,
                          timestampArray: filteredTimestamps,
                        ),
                        const SizedBox(height: 20.0),

                        // Oxygen Saturation
                        const Text(
                          'Oxygen Saturation',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                          textAlign: TextAlign
                              .left, // Explicitly align text to the left
                        ),
                        const SizedBox(height: 20.0),
                        ChartTesting(
                          vitalArray: filteredSaturation, // Corrected variable
                          timestampArray: filteredTimestamps,
                        ),
                        const SizedBox(height: 20.0),

                        // Respiration
                        const Text(
                          'Respiration',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                          textAlign: TextAlign
                              .left, // Explicitly align text to the left
                        ),
                        const SizedBox(height: 20.0),
                        ChartTesting(
                          vitalArray: filteredRespiration, // Corrected variable
                          timestampArray: filteredTimestamps,
                        ),
                        const SizedBox(height: 20.0),

                        // Pain Level
                        const Text(
                          'Pain Level',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                          textAlign: TextAlign
                              .left, // Explicitly align text to the left
                        ),
                        const SizedBox(height: 20.0),
                        ChartTesting(
                          vitalArray: filteredPainLevel, // Corrected variable
                          timestampArray: filteredTimestamps,
                        ),
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
            color:
                _selectedTimeFrame == title ? AppColors.neon : AppColors.purple,
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
  List<double> filterVitalsData(
      List<DateTime> filteredTimestamps, List<double> vitalData) {
    return List.generate(filteredTimestamps.length, (index) {
      final timestamp = filteredTimestamps[index];
      final indexInAllData = timestamps.indexOf(timestamp);
      return vitalData[indexInAllData];
    });
  }
}
