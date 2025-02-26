// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/screens/patient/chart_generator.dart';
import 'package:solace/themes/colors.dart'; // Make sure to import your chart

enum LoadingState {
  loading, // Indicates data is being fetched
  error, // Indicates an error occurred
  success, // Indicates successful data fetch
}

class PatientHistory extends StatefulWidget {
  const PatientHistory({super.key, required this.currentUserId});
  final String currentUserId;

  @override
  PatientHistoryState createState() => PatientHistoryState();
}

class PatientHistoryState extends State<PatientHistory> {
  LoadingState _loadingState = LoadingState.loading;
  String _errorMessage = "";

  String _selectedTimeFrame = 'This Week';
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

  // Loading state widget
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 20.0),
          Text(
            "Loading... Please Wait",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Error state widget
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.black,
            size: 80,
          ),
          const SizedBox(height: 20.0),
          Text(
            _errorMessage,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: AppColors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20.0),
          TextButton(
            onPressed: _fetchVitalsData,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              backgroundColor: AppColors.neon,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget to build chart sections dynamically
  Widget _buildVitalChartSection(
      String title, List<double> vitalData, List<DateTime> timestamps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 20.0),
        ChartTesting(
          vitalArray: vitalData,
          timestampArray: timestamps,
        ),
        const SizedBox(height: 20.0),
      ],
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

  List<DateTime> filterTimestamps(List<DateTime> timestamps, String timeFrame) {
    DateTime now = DateTime.now();

    if (timeFrame == 'Every Hour') {
      // Filter data for today, per hour
      DateTime startOfDay =
          DateTime(now.year, now.month, now.day); // Midnight of today
      DateTime endOfDay = startOfDay
          .add(Duration(days: 1)); // Start of the next day (exclusive)

      // Filter timestamps that are within today and fall within the current hour
      return timestamps.where((timestamp) {
        return timestamp.isAfter(startOfDay) &&
            timestamp.isBefore(endOfDay) &&
            timestamp.hour ==
                now.hour; // Ensure the hour matches the current hour
      }).toList();
    } else if (timeFrame == 'This Day') {
      // Filter data for today (same date)
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = startOfDay.add(Duration(days: 1));
      return timestamps
          .where((timestamp) =>
              timestamp.isAfter(startOfDay) && timestamp.isBefore(endOfDay))
          .toList();
    } else if (timeFrame == 'This Week') {
      // Filter data for this week (from the start of the week to now)
      DateTime startOfWeek =
          getStartOfWeek(now); // Get the first Monday of the week
      DateTime endOfWeek =
          startOfWeek.add(Duration(days: 7)); // Sunday (end of week)

      return timestamps
          .where((timestamp) =>
              timestamp.isAfter(startOfWeek) && timestamp.isBefore(endOfWeek))
          .toList();
    } else {
      return timestamps; // Default case: return all timestamps
    }
  }

  Future<void> _fetchVitalsData() async {
    setState(() {
      _loadingState = LoadingState.loading;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User is not logged in.");
      }

      final patientId = user.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('tracking')
          .doc(patientId)
          .get();

      if (!snapshot.exists) {
        throw Exception("Patient document not found.");
      }

      final trackingData = snapshot.data()?['tracking'];
      if (trackingData == null) {
        throw Exception("No tracking data found.");
      }

      List<DateTime> timestamps = [];
      List<double> heartRate = [];
      List<double> bloodPressure = [];
      List<double> saturation = [];
      List<double> respiration = [];
      List<double> temperature = [];
      List<double> painLevel = [];

      for (var track in trackingData) {
        final vitals = track['Vitals'];
        final timestamp = track['timestamp'];

        if (timestamp != null) {
          timestamps.add((timestamp as Timestamp).toDate());
        }

        if (vitals != null) {
          final parsedHeartRate = _parseVital(vitals['Heart Rate']);
          if (parsedHeartRate != null) heartRate.add(parsedHeartRate);

          final parsedBP = _parseVital(vitals['Blood Pressure']);
          if (parsedBP != null) bloodPressure.add(parsedBP);

          final parsedSaturation = _parseVital(vitals['Oxygen Saturation']);
          if (parsedSaturation != null) saturation.add(parsedSaturation);

          final parsedRespiration = _parseVital(vitals['Respiration']);
          if (parsedRespiration != null) respiration.add(parsedRespiration);

          final parsedTemperature = _parseVital(vitals['Temperature']);
          if (parsedTemperature != null) temperature.add(parsedTemperature);

          final parsedPainLevel = _parseVital(vitals['Pain']);
          if (parsedPainLevel != null) painLevel.add(parsedPainLevel);
        }
      }

      setState(() {
        this.timestamps = timestamps;
        this.bloodPressure = bloodPressure;
        this.heartRate = heartRate;
        this.temperature = temperature;
        this.saturation = saturation;
        this.respiration = respiration;
        this.painLevel = painLevel;
        _loadingState = LoadingState.success; // Successfully fetched data
      });
    } on TimeoutException {
      setState(() {
        _errorMessage = "Connection timed out. Please check your internet.";
        _loadingState = LoadingState.error;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        _loadingState = LoadingState.error;
      });
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
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child: _loadingState == LoadingState.loading
            ? _buildLoadingState()
            : _loadingState == LoadingState.error
                ? _buildErrorState()
                : Column(
                    children: [
                      // Fixed radio buttons at the top
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

                      // Scrollable content
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            color: AppColors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildVitalChartSection('Blood Pressure',
                                    filteredBloodPressure, filteredTimestamps),
                                _buildVitalChartSection('Heart Rate',
                                    filteredHeartRate, filteredTimestamps),
                                _buildVitalChartSection('Temperature',
                                    filteredTemperature, filteredTimestamps),
                                _buildVitalChartSection('Oxygen Saturation',
                                    filteredSaturation, filteredTimestamps),
                                _buildVitalChartSection('Respiration',
                                    filteredRespiration, filteredTimestamps),
                                _buildVitalChartSection('Pain Level',
                                    filteredPainLevel, filteredTimestamps),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
