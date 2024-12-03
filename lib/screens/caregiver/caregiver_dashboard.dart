// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/screens/patient/chart_generator.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/qr_scan.dart';
import 'package:solace/themes/colors.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  _CaregiverDashboardState createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  String? patientUid;
  final DatabaseService db =
      DatabaseService(); // Initialize the DatabaseService
  String? currentUserId; // Variable to store current user ID
  Map<String, dynamic>? patientData; // Store patient data
  File? _profileImage;

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
    _fetchPatientInfo();
    _fetchVitalsData();
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

  Future<void> _fetchPatientInfo() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          currentUserId = user.uid;
        });
        DocumentSnapshot caregiverDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        var healthcare = caregiverDoc['contacts']?['healthcare'];
        if (healthcare != null && healthcare.isNotEmpty) {
          setState(() {
            patientUid = healthcare.keys.first;
          });
          await _fetchPatientDetails();
        } else {
          setState(() {
            patientUid = null;
          });
        }
      }
    } catch (e) {
      print('Error fetching patient info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch patient info')),
      );
    }
  }

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

  Future<void> _fetchPatientDetails() async {
    try {
      if (patientUid != null) {
        DocumentSnapshot patientDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(patientUid)
            .get();
        setState(() {
          patientData = patientDoc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print('Error fetching patient details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch patient details')),
      );
    }
  }

  Future<void> _showSearchModal(BuildContext context) async {
    final TextEditingController uidController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            'Add Patient',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: uidController,
                  decoration: InputDecoration(
                    labelText: 'Enter Patient UID',
                    filled: true,
                    fillColor: AppColors.gray,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.neon),
                    ),
                  ),
                  style: TextStyle(fontSize: 18, fontFamily: 'Inter'),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    String targetUserId = uidController.text.trim();
                    if (targetUserId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a valid UID')),
                      );
                      return;
                    }

                    bool exists = await db.checkUserExists(targetUserId);
                    if (!exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User not found')),
                      );
                      return;
                    }

                    bool isContact = await db.isUserHealthcareContact(
                        currentUserId!, targetUserId);
                    if (isContact) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'This user is already your healthcare contact!')),
                      );
                      return;
                    }

                    bool hasPendingRequest =
                        await db.hasPendingHealthcareRequest(
                            currentUserId!, targetUserId);
                    if (hasPendingRequest) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Healthcare request already sent!')),
                      );
                      return;
                    }

                    await db.sendHealthcareRequest(
                        currentUserId!, targetUserId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Healthcare request sent!')),
                    );
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.neon,
                    foregroundColor: AppColors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.group_add),
                      SizedBox(width: 10),
                      Text(
                        'Send Request',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleQRScanResult(BuildContext context, String result) async {
    try {
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User is not logged in')),
        );
        return;
      }

      bool exists = await db.checkUserExists(result);
      if (!exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not found')),
        );
        return;
      }

      bool isContact = await db.isUserHealthcareContact(currentUserId!, result);
      if (isContact) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('This user is already your healthcare contact!')),
        );
        return;
      }

      bool hasPendingRequest =
          await db.hasPendingHealthcareRequest(currentUserId!, result);
      if (hasPendingRequest) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Healthcare request already sent!')),
        );
        return;
      }

      await db.sendHealthcareRequest(currentUserId!, result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Healthcare request sent to $result')),
      );
    } catch (e) {
      print('Error handling QR scan result: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process QR scan result')),
      );
    }
  }

  Widget _buildProfileInfoSection(String header, String data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Colors.grey,
            ),
          ),
          Text(
            data,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.normal,
              fontFamily: 'Inter',
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          // Add this to make the body scrollable
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment
                  .center, // Keep this as center for main content
              children: [
                patientUid == null
                    ? Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: AppColors.neon,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gray.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Add your patient',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                                color: AppColors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Select one of the methods below',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.normal,
                                fontSize: 18,
                                color: AppColors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // TextButton with Icon for Enter UID
                                TextButton.icon(
                                  onPressed: () => _showSearchModal(context),
                                  icon: Icon(
                                    Icons.person_add,
                                    color: AppColors.white,
                                  ),
                                  label: Text(
                                    'Enter UID',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: AppColors
                                        .blackTransparent, // Set background color
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.0),
                                // TextButton with Icon for Scan QR Code
                                TextButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const QRScannerPage()),
                                    );
                                    if (result != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('QR Code detected')),
                                      );
                                      _handleQRScanResult(context, result);
                                    }
                                  },
                                  icon: Icon(
                                    Icons.qr_code_scanner,
                                    color: AppColors.white,
                                  ),
                                  label: Text(
                                    'Scan QR',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: AppColors
                                        .blackTransparent, // Set background color
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          const Text(
                            'Patient Profile',
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),
                SizedBox(
                  height: 20.0,
                ),
                Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align text to the left
                    children: [
                      // Patient's Picture (Centered)
                      Center(
                        child: CircleAvatar(
                          radius: 70,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (patientData?['profileImageUrl']?.isNotEmpty ??
                                          false
                                      ? NetworkImage(
                                          patientData?['profileImageUrl'] ?? '')
                                      : const AssetImage(
                                          'lib/assets/images/shared/placeholder.png'))
                                  as ImageProvider,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildProfileInfoSection(
                        'Name',
                        '${patientData?['firstName']} ${patientData?['middleName']} ${patientData?['lastName']}',
                      ),
                      _buildProfileInfoSection(
                        'Age',
                        '${patientData?['age']}',
                      ),
                      _buildProfileInfoSection(
                        'Gender',
                        '${patientData?['gender']}',
                      ),
                      _buildProfileInfoSection(
                        'Will',
                        '${patientData?['will'] ?? 'N/A'}',
                      ),
                      _buildProfileInfoSection(
                        'Fixed Wishes',
                        '${patientData?['fixedWishes'] ?? 'N/A'}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(thickness: 1.0),
                const SizedBox(height: 10),
                Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Patient History',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20.0,
                    ),

                    // Vitals Charts Section
                    _isLoading
                        ? Center(
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: AppColors.gray,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Text(
                                "Insufficient Data",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.normal,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildRadioButton('Every Hour'),
                                  const SizedBox(width: 10.0),
                                  _buildRadioButton('This Day'),
                                  const SizedBox(width: 10.0),
                                  _buildRadioButton('This Week'),
                                ],
                              ),

                              const SizedBox(height: 20.0),
                              // Blood Pressure
                              const Text(
                                'Blood Pressure',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                ),
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
                              ),
                              const SizedBox(height: 20.0),
                              ChartTesting(
                                vitalArray: filteredSaturation,
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
                              ),
                              const SizedBox(height: 20.0),
                              ChartTesting(
                                vitalArray: filteredRespiration,
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
                              ),
                              const SizedBox(height: 20.0),
                              ChartTesting(
                                vitalArray: filteredPainLevel,
                                timestampArray: filteredTimestamps,
                              ),
                            ],
                          ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
