// ignore_for_file: avoid_print

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:solace/controllers/notification_service.dart';
import 'package:solace/screens/caregiver/caregiver_add_medicine.dart';
import 'package:solace/screens/caregiver/caregiver_add_task.dart';
import 'package:solace/screens/patient/patient_edit.dart';
import 'package:solace/screens/patient/patient_history.dart';
import 'package:solace/screens/patient/patient_intervention.dart';
import 'package:solace/screens/patient/patient_note.dart';
import 'package:solace/screens/patient/patient_stream.dart';
import 'package:solace/screens/patient/patient_tracking.dart';
import 'package:solace/services/database.dart';
import 'package:solace/screens/patient/patient_contacts.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:solace/utility/schedule_utility.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:lucide_icons/lucide_icons.dart';

class PatientsDashboard extends StatefulWidget {
  final String patientId;
  final String caregiverId;
  final String role;

  const PatientsDashboard({
    super.key,
    required this.patientId,
    required this.caregiverId,
    required this.role,
  });

  @override
  State<PatientsDashboard> createState() => _PatientsDashboardState();
}

class VitalStatus {
  final Color color;
  final IconData? icon;
  final String label;

  VitalStatus({required this.color, this.icon, required this.label});
}

class _PatientsDashboardState extends State<PatientsDashboard> {
  final LogService _logService = LogService();
  final DatabaseService databaseService = DatabaseService();
  final NotificationService notificationService = NotificationService();
  ScheduleUtility scheduleUtility = ScheduleUtility();
  Map<String, dynamic>? patientData;
  bool isLoading = true;
  bool _isTagging = false;
  late final PageController _pageController;
  late String patientName = '';
  late Map<String, dynamic> thresholds = {};
  bool _isLoading = true;

  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchPatientData();
    _fetchThresholds();
    _startTimer();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<String> _loadUserName(String userId) async {
    final name = await databaseService.fetchUserName(userId);
    return name ?? 'Unknown User';
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 60), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  Future<void> fetchPatientData() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(widget.patientId)
              .get();

      if (snapshot.exists) {
        if (mounted) {
          setState(() {
            patientData = snapshot.data();
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        showToast("Patient data not found.", backgroundColor: AppColors.red);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      showToast(
        "Error fetching patient data: $e",
        backgroundColor: AppColors.red,
      );
    }
  }

  Future<void> _fetchThresholds() async {
    thresholds = await databaseService.fetchThresholds();
    setState(() {
      _isLoading = false;
    });
  }

  VitalStatus getVitalStatus(String key, dynamic value) {
    if (key == 'Blood Pressure' && value is String) {
      final parts = value.split('/');
      if (parts.length == 2) {
        final systolic = int.tryParse(parts[0]) ?? 0;
        final diastolic = int.tryParse(parts[1]) ?? 0;

        final systolicStatus = getVitalStatus(
          'Blood Pressure (Systolic)',
          systolic,
        );
        final diastolicStatus = getVitalStatus(
          'Blood Pressure (Diastolic)',
          diastolic,
        );

        return systolicStatus.color == AppColors.red ||
                diastolicStatus.color == AppColors.red
            ? systolicStatus.color == AppColors.red
                ? systolicStatus
                : diastolicStatus
            : systolicStatus.color == AppColors.yellow ||
                diastolicStatus.color == AppColors.yellow
            ? systolicStatus.color == AppColors.yellow
                ? systolicStatus
                : diastolicStatus
            : VitalStatus(color: AppColors.white, label: "Normal");
      }
    }

    // Convert value to num safely
    final numValue =
        (value is num) ? value : num.tryParse(value.toString()) ?? 0;

    switch (key) {
      case 'Heart Rate':
        if (numValue < thresholds['minMildHeartRate']) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very Low",
          );
        }
        if (numValue < thresholds['minNormalHeartRate']) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "Low",
          );
        }
        if (numValue > thresholds['maxMildHeartRate']) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very High",
          );
        }
        if (numValue > thresholds['maxNormalHeartRate']) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "High",
          );
        }
        break;

      case 'Blood Pressure (Systolic)':
        if (numValue < thresholds['minMildSystolic']) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very Low",
          );
        }
        if (numValue < thresholds['minNormalSystolic']) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "Low",
          );
        }
        if (numValue > thresholds['maxMildSystolic']) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very High",
          );
        }
        if (numValue > thresholds['maxNormalSystolic']) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "High",
          );
        }
        break;

      case 'Blood Pressure (Diastolic)':
        if (numValue < thresholds['minMildDiastolic']) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very Low",
          );
        }
        if (numValue < thresholds['minNormalDiastolic']) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "Low",
          );
        }
        if (numValue > thresholds['maxMildDiastolic']) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very High",
          );
        }
        if (numValue > thresholds['maxNormalDiastolic']) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "High",
          );
        }
        break;

      case 'Oxygen Saturation':
        if (numValue < thresholds['minMildOxygenSaturation']) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very Low",
          );
        }
        if (numValue < thresholds['minNormalOxygenSaturation']) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "Low",
          );
        }
        break;

      case 'Respiration':
        if (numValue < thresholds['minMildRespirationRate']) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very Low",
          );
        }
        if (numValue < thresholds['minNormalRespirationRate']) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "Low",
          );
        }
        if (numValue > thresholds['maxMildRespirationRate']) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very High",
          );
        }
        if (numValue > thresholds['maxNormalRespirationRate']) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "High",
          );
        }
        break;

      case 'Temperature':
        if (numValue < thresholds['minMildTemperature']) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very Low",
          );
        }
        if (numValue < thresholds['minNormalTemperature']) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "Low",
          );
        }
        if (numValue > thresholds['maxMildTemperature']) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very High",
          );
        }
        if (numValue > thresholds['maxNormalTemperature']) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "High",
          );
        }
        break;

      case 'Pain':
        if (numValue > thresholds['maxMildScale']) {
          return VitalStatus(
            color: AppColors.red,
            icon: LucideIcons.alertTriangle,
            label: "Very High",
          );
        }
        if (numValue > thresholds['maxNormalScale']) {
          return VitalStatus(
            color: AppColors.yellow,
            icon: LucideIcons.alertCircle,
            label: "High",
          );
        }
        break;
    }

    return VitalStatus(color: AppColors.white, label: "Normal");
  }

  String _convertPredictionKeyToName(String key) {
    if (key.startsWith('bloodpressure_t')) return 'Blood Pressure';
    if (key.startsWith('heartrate_t')) return 'Heart Rate';
    if (key.startsWith('respiration_t')) return 'Respiration';
    if (key.startsWith('sao2_t')) return 'Oxygen Saturation';
    if (key.startsWith('temperature_t')) return 'Temperature';
    return key;
  }

  String _getVitalUnit(String key) {
    return {
          'Heart Rate': ' bpm',
          'Blood Pressure': ' mmHg',
          'Oxygen Saturation': '%',
          'Respiration': ' breaths/min',
          'Temperature': '°C',
          'Pain': '/10',
        }[key] ??
        '';
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.inHours > 1) {
      return '${duration.inHours} hours';
    } else if (duration.inHours == 1) {
      return '1 hour';
    } else if (duration.inMinutes > 1) {
      return '${duration.inMinutes} minutes';
    } else {
      return 'Less than a minute';
    }
  }

  Widget _buildContainer({
    required String title,
    required String description,
    required String imagePath,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(color: AppColors.black.withValues(alpha: 0.4)),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Textstyle.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Divider(),
                Text(
                  description,
                  style: Textstyle.bodySmall.copyWith(color: AppColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContainer() {
    return _buildContainer(
      title: 'Schedule Patient',
      description: 'Schedule a visit for the patient',
      imagePath: 'lib/assets/images/auth/calendar.jpg',
      onPressed: () {
        _scheduleAppointment(widget.caregiverId, widget.patientId);
      },
    );
  }

  Widget _buildTaskContainer() {
    return _buildContainer(
      title: 'Give Task',
      description: 'Give a task for the patient to complete',
      imagePath: 'lib/assets/images/auth/task.jpg',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewPatientTask(patientId: widget.patientId),
          ),
        );
      },
    );
  }

  Widget _buildMedicineContainer() {
    return _buildContainer(
      title: 'Prescribe Medicine',
      description: 'Prescribe medicine for the patient',
      imagePath: 'lib/assets/images/auth/medicine.jpg',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ViewPatientMedicine(patientId: widget.patientId),
          ),
        );
      },
    );
  }

  Widget _buildTracking() {
    return GestureDetector(
      child: _buildContainer(
        title: 'Track Patient',
        description: 'Record the patient\'s vitals and symptoms',
        imagePath: 'lib/assets/images/auth/tracking.jpg',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PatientTracking(patientId: widget.patientId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotes() {
    return _buildContainer(
      title: 'Take Notes',
      description: 'Add notes to document events related to the patient',
      imagePath: 'lib/assets/images/auth/notes.jpg',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientNote(patientId: widget.patientId),
          ),
        );
      },
    );
  }

  Widget _buildActions(String role) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Available Actions", style: Textstyle.subheader),
          const SizedBox(height: 10.0),
          Text(
            "Below are the tools available to help you monitor and manage the patient effectively.",
            style: Textstyle.body,
          ),
          const SizedBox(height: 20.0),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Two columns
              crossAxisSpacing: 10.0, // Space between columns
              mainAxisSpacing: 10.0, // Space between rows
              childAspectRatio: 2.5, // Adjust height-to-width ratio
              mainAxisExtent: 200,
            ),
            children: [
              _buildTracking(),
              _buildNotes(),
              if (role != 'caregiver') _buildScheduleContainer(),
              _buildTaskContainer(),
              if (role == 'doctor') _buildMedicineContainer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataView(String message) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Patient Records",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10.0),
          Text(
            "Graphs of the patient's vitals and symptoms over time.",
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.gray,
            ),
            child: Text(
              message,
              style: Textstyle.body,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraph(String patientId) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: fetchPatientTracking(patientId),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNoDataView("No data available");
        }

        final symptomData = snapshot.data!['symptoms']!;
        final vitalData = snapshot.data!['vitals']!;
        final timestampData = snapshot.data!['timestamps']!;

        debugPrint("timestampDataaaa: $timestampData");

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Patient Records", style: Textstyle.subheader),
                const SizedBox(height: 10.0),
                Text(
                  "Visualizations of the patient's vitals and symptoms over time.",
                  style: Textstyle.body,
                ),
                const SizedBox(height: 20.0),
                Text(
                  "Vitals",
                  style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10.0),
                _buildGraphsForCategory(
                  'Vitals',
                  vitalData,
                  timestampData,
                ), // Render Vitals Graphs
                const SizedBox(height: 20.0),
                Text(
                  "Symptoms",
                  style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10.0),
                _buildGraphsForCategory(
                  'Symptoms',
                  symptomData,
                  timestampData,
                ), // Render Symptoms Graphs
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGraphsForCategory(
    String title,
    List<Map<String, dynamic>> data,
    List<Map<String, dynamic>> timestampData,
  ) {
    final Map<String, List<double>> keyValues = {};
    final List<String> timestamps = [];

    // Collect all values for each key and preserve all timestamps
    for (var i = 0; i < data.length; i++) {
      if (i >= timestampData.length) {
        debugPrint("Index $i is out of range for timestampData");
        break; // Prevent accessing out-of-range elements
      }

      var record = data[i];
      var timestamp = timestampData[i]['timestamp'] as String;

      // Add the timestamp only once for each data point
      timestamps.add(timestamp);

      debugPrint("timestamp data for build graphs for categ: $timestamp");

      record.forEach((key, value) {
        if (value is String) {
          // Attempt to parse string to double
          final doubleValue = double.tryParse(value);
          if (doubleValue != null) {
            keyValues.putIfAbsent(key, () => []).add(doubleValue);
          }
        } else if (value is num) {
          keyValues.putIfAbsent(key, () => []).add(value.toDouble());
        }
      });
    }

    final pageController = PageController(viewportFraction: 0.85);

    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = constraints.maxWidth * 9;
        final pageHeight = 300.0;

        return SizedBox(
          height: pageHeight,
          child: PageView.builder(
            controller: pageController,
            itemCount: keyValues.length,
            itemBuilder: (context, index) {
              final key = keyValues.keys.elementAt(index);
              final values = keyValues[key]!;

              return AnimatedBuilder(
                animation: pageController,
                builder: (context, child) {
                  double value = 1;
                  if (pageController.position.haveDimensions) {
                    value = pageController.page! - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
                  }

                  return Center(
                    child: SizedBox(
                      height: Curves.easeInOut.transform(value) * pageHeight,
                      width: Curves.easeInOut.transform(value) * pageWidth,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.gray,
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: SfCartesianChart(
                            title: ChartTitle(
                              text: key,
                              textStyle: Textstyle.bodySuperSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            primaryXAxis: CategoryAxis(
                              labelPlacement: LabelPlacement.onTicks,
                              labelRotation: 45,
                              majorGridLines: MajorGridLines(width: 0),
                              edgeLabelPlacement: EdgeLabelPlacement.shift,
                            ),
                            series: <CartesianSeries>[
                              SplineAreaSeries<double, String>(
                                dataSource: values,
                                xValueMapper:
                                    (value, index) => timestamps[index],
                                yValueMapper: (value, _) => value,
                                markerSettings: MarkerSettings(
                                  isVisible: true,
                                  color:
                                      title == 'Vitals'
                                          ? AppColors.neon
                                          : AppColors.purple,
                                  shape: DataMarkerType.circle,
                                  borderColor:
                                      title == 'Vitals'
                                          ? AppColors.neon
                                          : AppColors.purple,
                                  borderWidth: 2,
                                ),
                                borderColor:
                                    title == 'Vitals'
                                        ? AppColors.neon
                                        : AppColors.purple,
                                borderWidth: 2,
                                color:
                                    title == 'Vitals'
                                        ? AppColors.neon.withValues(alpha: 0.5)
                                        : AppColors.purple.withValues(
                                          alpha: 0.5,
                                        ),
                                splineType: SplineType.natural,
                                enableTooltip: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchPatientTracking(
    String patientId,
  ) async {
    try {
      debugPrint("Running fetch");
      final trackingDoc = FirebaseFirestore.instance
          .collection('tracking')
          .doc(patientId);
      final docSnapshot = await trackingDoc.get();

      debugPrint("Doc snapshot: $docSnapshot");

      if (!docSnapshot.exists) throw Exception('Patient data not found.');

      final trackingData = docSnapshot.data();
      if (trackingData == null || trackingData['tracking'] == null) {
        throw Exception('Tracking data is unavailable.');
      }

      final List<dynamic> trackingArray = trackingData['tracking'];

      debugPrint("Tracking Data: $trackingArray");

      List<Map<String, dynamic>> symptoms = [];
      List<Map<String, dynamic>> vitals = [];
      List<Map<String, dynamic>> timestamps = [];

      final today = DateTime.now();

      // Create a DateFormat instance for "M/d H:mm" format (includes time)
      final dateFormat = DateFormat('M/d H:mm');

      // Loop through each entry in the tracking data
      for (final entry in trackingArray) {
        if (entry is Map<String, dynamic> && entry.containsKey('timestamp')) {
          final timestamp = entry['timestamp'];

          // Ensure timestamp is a valid type (Timestamp or DateTime)
          DateTime timestampDateOnly;
          if (timestamp is Timestamp) {
            timestampDateOnly = timestamp.toDate();
          } else if (timestamp is DateTime) {
            timestampDateOnly = timestamp;
          } else if (timestamp is String) {
            timestampDateOnly = DateTime.parse(timestamp);
          } else {
            continue;
          }

          // Reset the time to 00:00:00 for the timestamp and keep the time for comparison
          timestampDateOnly = DateTime(
            timestampDateOnly.year,
            timestampDateOnly.month,
            timestampDateOnly.day,
            timestampDateOnly.hour,
            timestampDateOnly.minute,
          );

          debugPrint("Timestamp date with time: $timestampDateOnly");

          // Compare if the timestamp is within 1 day of today's date
          final difference = today.difference(timestampDateOnly).inHours;

          if (difference <= 24) {
            // If timestamp is within 24 hours, add it to the list
            String formattedDate = dateFormat.format(timestampDateOnly);
            timestamps.add({'timestamp': formattedDate});

            // Process the other data as required
            if (entry.containsKey('Symptom Assessment')) {
              symptoms.add(entry['Symptom Assessment']);
            }
            if (entry.containsKey('Vitals')) {
              vitals.add(entry['Vitals']);
            }
          }
        }
      }

      // If there are no records for today, proceed with the original data
      if (timestamps.isEmpty || timestamps.length == 1) {
        debugPrint(
          "No recent data for today, collecting the earliest 10 records.",
        );
        for (final entry in trackingArray) {
          if (entry is Map<String, dynamic>) {
            if (entry.containsKey('timestamp')) {
              final timestamp = entry['timestamp'];

              // Ensure timestamp is a valid type (Timestamp or DateTime)
              DateTime timestampDateOnly;
              if (timestamp is Timestamp) {
                timestampDateOnly = timestamp.toDate();
              } else if (timestamp is DateTime) {
                timestampDateOnly = timestamp;
              } else if (timestamp is String) {
                timestampDateOnly = DateTime.parse(timestamp);
              } else {
                continue;
              }

              // Format timestamp to "M/d H:mm"
              String formattedDate = dateFormat.format(timestampDateOnly);
              timestamps.add({'timestamp': formattedDate});

              // Add data to symptoms and vitals
              if (entry.containsKey('Symptom Assessment')) {
                symptoms.add(entry['Symptom Assessment']);
              }
              if (entry.containsKey('Vitals')) {
                vitals.add(entry['Vitals']);
              }
            }
          }
        }
      }

      // Sort timestamps by date and time (ascending order)
      timestamps.sort((a, b) {
        final timestampA = DateFormat('M/d H:mm').parse(a['timestamp']);
        final timestampB = DateFormat('M/d H:mm').parse(b['timestamp']);
        return timestampA.compareTo(timestampB); // Ascending order
      });

      // If there are fewer than 10 records, return all available records
      if (timestamps.length < 10) {
        debugPrint("Less than 10 records available, returning all.");
      } else {
        // If there are more than 10, return the earliest 10 records
        timestamps = timestamps.sublist(0, 10);
      }

      debugPrint("Timestamps: $timestamps");
      debugPrint("Symptoms: $symptoms");
      debugPrint("Vitals: $vitals");

      // Return the data
      return {'symptoms': symptoms, 'vitals': vitals, 'timestamps': timestamps};
    } catch (e) {
      print('Error fetching patient tracking: $e');
      throw Exception('Error fetching patient tracking data.');
    }
  }

  Future<void> _scheduleAppointment(
    String caregiverId,
    String patientId,
  ) async {
    if (!mounted) return; // Ensure the widget is still mounted
    final DateTime now = DateTime.now();

    // Show the customized date picker
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year, now.month + 3),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.neon,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.neon),
            ),
            dialogTheme: DialogThemeData(backgroundColor: AppColors.white),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || selectedDate == null) {
      return; // Ensure widget is still mounted
    }

    // Show the customized time picker
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.neon,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || selectedTime == null) {
      return; // Ensure widget is still mounted
    }

    // Combine the selected date and time into a single DateTime object
    final DateTime scheduledDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Check if the selected time is in the past
    if (scheduledDateTime.isBefore(now)) {
      showToast(
        "The selected schedule time is in the past. Please choose a valid time.",
        backgroundColor: AppColors.red,
      );
      return; // Reject the schedule
    }

    // Check if the selected time is at least 15 minutes from now
    if (scheduledDateTime.isBefore(now.add(Duration(minutes: 15)))) {
      showToast(
        "The selected schedule time must be at least 15 minutes from now.",
        backgroundColor: AppColors.red,
      );
      return; // Reject the schedule
    }

    // Show confirmation dialog
    final String formattedDateTime = DateFormat(
      "MMMM d, yyyy h:mm a",
    ).format(scheduledDateTime);

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text('Confirm Appointment', style: Textstyle.subheader),
              content: Text(
                'You are scheduling an appointment for $formattedDateTime. Is this correct?',
                style: Textstyle.body,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: Buttonstyle.buttonRed,
                        child: Text('Cancel', style: Textstyle.smallButton),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: Buttonstyle.buttonNeon,
                        child: Text('Confirm', style: Textstyle.smallButton),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      final String scheduleId =
          FirebaseFirestore.instance.collection('_').doc().id;

      final caregiverRole = await databaseService.fetchAndCacheUserRole(
        caregiverId,
      );
      final patientRole = await databaseService.fetchAndCacheUserRole(
        patientId,
      );

      if (caregiverRole == null || patientRole == null) {
        //         debugPrint("Failed to fetch roles. Caregiver or patient role is null.");
        showToast(
          "Failed to schedule. Roles not found.",
          backgroundColor: AppColors.red,
        );
        return;
      }

      await scheduleUtility.saveSchedule(
        userId: caregiverId,
        scheduleId: scheduleId,
        subCollectionName: 'schedules',
        scheduledDateTime: scheduledDateTime,
        extraData: {'patientId': patientId},
        collectionName: caregiverRole,
      );

      await scheduleUtility.saveSchedule(
        userId: patientId,
        scheduleId: scheduleId,
        subCollectionName: 'schedules',
        scheduledDateTime: scheduledDateTime,
        extraData: {'caregiverId': caregiverId},
        collectionName: patientRole,
      );

      String patientName = await _loadUserName(patientId);
      String caregiverName = await _loadUserName(caregiverId);
      final String role =
          '${caregiverRole.substring(0, 1).toUpperCase()}${caregiverRole.substring(1)}';
      final String? name = await databaseService.fetchUserName(caregiverId);

      await notificationService.sendInAppNotificationToTaggedUsers(
        patientId: widget.patientId,
        currentUserId: caregiverId,
        notificationMessage:
            "$role $name scheduled an appointment to patient $patientName on $scheduledDateTime.",
        type: "schedule",
      );

      await notificationService.sendNotificationToTaggedUsers(
        widget.patientId,
        "Schedule Notice",
        "$role $name scheduled an appointment to patient $patientName on $scheduledDateTime.",
      );

      await _logService.addLog(
        userId: caregiverId,
        action:
            "Scheduled patient $patientName an appointment on $scheduledDateTime",
      );
      await _logService.addLog(
        userId: patientId,
        action:
            "Scheduled by $caregiverName an appointment on $scheduledDateTime",
      );

      showToast("Appointment scheduled for $patientName at $formattedDateTime");
    } catch (e) {
      showToast(
        "Failed to schedule appointment.",
        backgroundColor: AppColors.red,
      );
    }
  }

  Widget _buildAssignButton() {
    return FutureBuilder<bool>(
      future: _isUserTagged(widget.patientId, widget.caregiverId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final isTagged = snapshot.data ?? false;

          return Row(
            children: [
              SizedBox(width: 5),
              SizedBox(
                height: 30,
                child: TextButton(
                  onPressed:
                      () =>
                          isTagged
                              ? _untagPatient(
                                patientId: widget.patientId,
                                userId: widget.caregiverId,
                              )
                              : _tagPatient(
                                patientId: widget.patientId,
                                userId: widget.caregiverId,
                              ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                    backgroundColor: isTagged ? AppColors.red : AppColors.neon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isTagged ? 'Remove Assignment' : 'Assign Patient',
                    style: Textstyle.bodySuperSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Container();
      },
    );
  }

  Widget _buildPatientStatus() {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('patient')
              .doc(widget.patientId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching data'));
        }

        // Extract patient data and status directly
        final patientData = snapshot.data?.data() as Map<String, dynamic>?;
        final status = patientData?['status'] ?? 'stable';
        final isUnstable = status == 'unstable';
        final isUnavailable = patientData == null;
        final cases = patientData?['cases'];
        final age = patientData?['age'];
        final String name =
            '${patientData?['firstName']} ${patientData?['lastName']}';
        final backgroundColor =
            isUnavailable
                ? AppColors.blackTransparent
                : isUnstable
                ? AppColors.red
                : AppColors.neon;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: backgroundColor,
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 30),
                        Text(
                          '$name, $age',
                          style: Textstyle.bodyWhite.copyWith(fontSize: 20),
                          overflow: TextOverflow.ellipsis,
                        ),

                        Text(
                          isUnavailable
                              ? 'Unavailable'
                              : isUnstable
                              ? 'Unstable'
                              : 'Stable',
                          style: Textstyle.heading.copyWith(
                            fontSize: 40,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PatientHistory(
                                          patientId: widget.patientId,
                                        ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    'View Patient History',
                                    style: Textstyle.bodyWhite.copyWith(
                                      fontSize: 16,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.white,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: AppColors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    color: AppColors.black.withValues(alpha: 0.9),
                    padding: EdgeInsets.all(16),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.role != 'caregiver')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  "Manage Patient",
                                  style: Textstyle.bodySmall.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildAssignButton(),
                            ],
                          ),
                        SizedBox(height: 10),
                        Divider(),
                        SizedBox(height: 10),
                        Text(
                          "Active Cases",
                          style: Textstyle.bodySmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          (cases != null && cases.isNotEmpty)
                              ? cases.map((caseItem) => '$caseItem').join('\n')
                              : 'No active cases available',
                          style: Textstyle.bodySmall.copyWith(
                            color: AppColors.white,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    color: AppColors.black.withValues(alpha: 0.8),
                    child: _buildVitals(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVitals() {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('tracking')
              .doc(widget.patientId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching vitals data'));
        }

        final trackingData = snapshot.data?.data() as Map<String, dynamic>?;
        final trackingArray = trackingData?['tracking'] as List<dynamic>?;

        if (trackingArray == null || trackingArray.isEmpty) {
          return Center(
            child: Text(
              'No recent vitals available. Start tracking symptoms now',
              style: TextStyle(color: AppColors.white),
            ),
          );
        }

        final lastElement = trackingArray.last as Map<String, dynamic>;
        final vitals = lastElement['Vitals'] as Map<String, dynamic>?;
        final timestamp = lastElement['timestamp'] as Timestamp?;

        if (vitals == null || timestamp == null) {
          return const Center(child: Text('Incomplete vitals data'));
        }

        final modifiedVitals = Map<String, dynamic>.from(vitals);

        // Remove Systolic and Diastolic keys
        final systolic = modifiedVitals.remove('Systolic');
        final diastolic = modifiedVitals.remove('Diastolic');

        // Add Blood Pressure key with combined value
        if (systolic != null && diastolic != null) {
          modifiedVitals['Blood Pressure'] = '$systolic/$diastolic';
        }

        final formattedTimestamp = timeago.format(timestamp.toDate());

        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('patient') // Corrected collection name
                  .doc(widget.patientId)
                  .get(), // Fetch predictions once
          builder: (context, predictionSnapshot) {
            if (predictionSnapshot.hasError) {
              return const Center(child: Text('Error fetching predictions'));
            }

            final predictionsData =
                predictionSnapshot.data?.data() as Map<String, dynamic>?;
            final predictionsArray =
                predictionsData?['predictions'] as List<dynamic>?;

            Map<String, dynamic> criticalPredictions = {};
            Map<String, String> predictionTimes = {};

            if (predictionsArray != null && predictionsArray.isNotEmpty) {
              for (var prediction in predictionsArray) {
                final predMap = prediction as Map<String, dynamic>;
                final predictionTimestamp =
                    (predMap['timestamp'] as Timestamp?)?.toDate();

                if (predictionTimestamp == null) continue;

                // Define future time intervals
                final timeIntervals = {
                  't+1': predictionTimestamp.add(Duration(hours: 1)),
                  't+2': predictionTimestamp.add(Duration(hours: 6)),
                  't+3': predictionTimestamp.add(Duration(hours: 12)),
                };

                for (var key in predMap.keys) {
                  if (!key.startsWith('bloodpressure_t') &&
                      !key.startsWith('heartrate_t') &&
                      !key.startsWith('respiration_t') &&
                      !key.startsWith('sao2_t') &&
                      !key.startsWith('temperature_t')) {
                    continue;
                  }

                  final value = predMap[key];
                  final status = getVitalStatus(
                    _convertPredictionKeyToName(key),
                    value,
                  );

                  if (status.color == AppColors.red ||
                      status.color == AppColors.yellow) {
                    // Extract the time step (t+1, t+2, t+3)
                    final match = RegExp(r't\+(\d+)').firstMatch(key);
                    if (match != null) {
                      final timeKey = 't+${match.group(1)}';
                      final futureTime = timeIntervals[timeKey];

                      if (futureTime != null) {
                        final remainingTime = futureTime.difference(
                          _currentTime,
                        );

                        if (futureTime.isBefore(_currentTime)) {
                          continue;
                        }

                        if (!criticalPredictions.containsKey(
                          _convertPredictionKeyToName(key),
                        )) {
                          criticalPredictions[_convertPredictionKeyToName(
                                key,
                              )] =
                              value;
                          predictionTimes[_convertPredictionKeyToName(
                            key,
                          )] = _formatRemainingTime(remainingTime);
                        }
                      }
                    }
                  }
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last updated: $formattedTimestamp',
                  style: TextStyle(
                    color: AppColors.white,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 10),

                // Display current vitals
                ...modifiedVitals.entries.map((entry) {
                  final unit = _getVitalUnit(entry.key);
                  final dynamic rawValue = entry.value;
                  final status =
                      (rawValue != null)
                          ? getVitalStatus(entry.key, rawValue)
                          : VitalStatus(color: AppColors.white, label: "N/A");

                  return _buildVitalRow(
                    entry.key,
                    rawValue.toString(),
                    unit,
                    status,
                  );
                }),

                Divider(),

                // Display earliest predicted critical vitals
                if (criticalPredictions.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Text(
                    'Predicted Critical Vitals',
                    style: Textstyle.subheader.copyWith(color: AppColors.white),
                  ),
                  SizedBox(height: 10),
                  ...criticalPredictions.entries.map((entry) {
                    final unit = _getVitalUnit(entry.key);
                    final status = getVitalStatus(entry.key, entry.value);
                    final timeRemaining =
                        predictionTimes[entry.key] ?? "Unknown";

                    return _buildVitalColumn(
                      entry.key,
                      '(in $timeRemaining)',
                      '~${entry.value}',
                      unit,
                      status,
                    );
                  }),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildVitalRow(
    String key,
    String value,
    String unit,
    VitalStatus status,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                key,
                style: Textstyle.bodySmall.copyWith(color: AppColors.white),
              ),
            ),
            Row(
              children: [
                Text(
                  '$value$unit',
                  style: Textstyle.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                if (status.icon != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: status.color,
                    ),
                    child: Row(
                      children: [
                        Icon(status.icon, color: AppColors.white, size: 14),
                        SizedBox(width: 5),
                        Text(
                          status.label,
                          style: Textstyle.bodySuperSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildVitalColumn(
    String key,
    String time,
    String value,
    String unit,
    VitalStatus status,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.darkgray,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    key,
                    style: Textstyle.bodySmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 5),
                  Text(
                    time,
                    style: Textstyle.bodySmall.copyWith(color: AppColors.white),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  if (status.icon != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: status.color,
                      ),
                      child: Row(
                        children: [
                          Icon(status.icon, color: AppColors.white, size: 14),
                          SizedBox(width: 5),
                          Text(
                            status.label,
                            style: Textstyle.bodySuperSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(width: 8),
                  Text(
                    '$value$unit',
                    style: Textstyle.bodySmall.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCarousel() {
    return CarouselWidget(
      pageController: _pageController,
      patientId: widget.patientId,
    );
  }

  Widget _buildInterventions() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Interventions', style: Textstyle.subheader),
              const SizedBox(height: 10),
              Text(
                'Choose a section to view intervention checklists based on the patient\'s current status.',
                style: Textstyle.body,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
        PatientInterventions(patientId: widget.patientId),
      ],
    );
  }

  Future<bool> _isUserTagged(String patientId, String userId) async {
    try {
      // Get the patient document
      final patientDocRef = FirebaseFirestore.instance
          .collection('patient')
          .doc(patientId)
          .collection('tags') // tags subcollection
          .doc(userId); // Check if this specific user is tagged

      final docSnapshot =
          await patientDocRef.get(); // Fetch the tag for the specific user

      // Return true if the user is tagged, otherwise false
      return docSnapshot.exists;
    } catch (e) {
      //     debugPrint('Error checking tag: $e');
      return false;
    }
  }

  Future<void> _tagPatient({
    required String patientId,
    required String userId,
  }) async {
    if (_isTagging) return; // Prevent multiple taps

    String patientName = await _loadUserName(patientId);

    final shouldTag = await _showConfirmationDialog(
      title: 'Assign this patient to yourself',
      definition:
          'Assigning $patientName will add them to your list of assigned patients.',
      message: 'Are you sure you want to assign patient $patientName?',
    );

    if (shouldTag) {
      try {
        if (userId.isEmpty) {
          showToast(
            'User is not authenticated',
            backgroundColor: AppColors.red,
          );
          return;
        }

        final String? userRole = await databaseService.fetchAndCacheUserRole(
          userId,
        );

        if (userRole == null) {
          showToast('User has no role', backgroundColor: AppColors.red);
          return;
        }

        setState(() {
          _isTagging = true;
        });

        showToast('Assigning patient $patientName in progress...');

        final patientRef = FirebaseFirestore.instance
            .collection('patient')
            .doc(patientId);
        final userRef = FirebaseFirestore.instance
            .collection(userRole)
            .doc(userId);

        // Add caregiver/nurse/doctor ID to patient's tags subcollection
        await patientRef.collection('tags').doc(userId).set({});

        // Add patient ID to caregiver/nurse/doctor's tags subcollection
        await userRef.collection('tags').doc(patientId).set({});

        await _logService.addLog(
          userId: widget.caregiverId,
          action: "Assigned patient $patientName",
        );
        await databaseService.addNotification(
          widget.caregiverId,
          'You successfully assigned patient $patientName to yourself',
          'tag',
        );

        showToast('Successfully assigned patient $patientName.');
      } catch (e) {
        showToast(
          'Error assigning patient $patientName: $e',
          backgroundColor: AppColors.red,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isTagging = false;
          });
        }
      }
    }
  }

  Future<void> _untagPatient({
    required String patientId,
    required String userId,
  }) async {
    if (_isTagging) return;
    String patientName = await _loadUserName(patientId);

    final shouldUntag = await _showConfirmationDialog(
      title: 'Removed Assignment',
      definition:
          'Removing your assignment to $patientName will remove them from your list of assigned patients.',
      message:
          'Are you sure you want to remove your assignment to $patientName?',
    );

    if (shouldUntag) {
      try {
        if (userId.isEmpty) {
          showToast(
            'User is not authenticated',
            backgroundColor: AppColors.red,
          );
          return;
        }

        final String? userRole = await databaseService.fetchAndCacheUserRole(
          userId,
        );

        if (userRole == null) {
          showToast('User has no role', backgroundColor: AppColors.red);
          return;
        }

        setState(() {
          _isTagging = true;
        });

        showToast('Removing assignment in progress...');

        final patientRef = FirebaseFirestore.instance
            .collection('patient')
            .doc(patientId);
        final userRef = FirebaseFirestore.instance
            .collection(userRole)
            .doc(userId);

        // Remove caregiver/nurse/doctor ID from patient's tags subcollection
        await patientRef.collection('tags').doc(userId).delete();

        // Remove patient ID from caregiver/nurse/doctor's tags subcollection
        await userRef.collection('tags').doc(patientId).delete();

        await _logService.addLog(
          userId: widget.caregiverId,
          action: "Removed assignment to patient $patientName",
        );
        await databaseService.addNotification(
          widget.caregiverId,
          'You successfully removed assignment to patient $patientName',
          'tag',
        );

        showToast('Assignment to $patientName has been successfully removed');
      } catch (e) {
        showToast(
          'Error removing assignment to patient $patientName: $e',
          backgroundColor: AppColors.red,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isTagging = false;
          });
        }
      }
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String definition,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text(title, style: Textstyle.subheader),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(definition, style: Textstyle.body),
                  SizedBox(height: 30),
                  Text(
                    message,
                    style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        style: Buttonstyle.buttonRed,
                        child: Text('No', style: Textstyle.smallButton),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        style: Buttonstyle.buttonNeon,
                        child: Text('Yes', style: Textstyle.smallButton),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Patient Status', style: Textstyle.subheader),
        centerTitle: true,
        actions: [
          _isLoading
              ? Container()
              : Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      Contacts(patientId: widget.patientId),
                            ),
                          ),
                      child: Icon(
                        Icons.perm_contact_cal_rounded,
                        size: 24,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(width: 15),
                    GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => EditPatient(
                                    patientId: widget.patientId,
                                    role: widget.role,
                                  ),
                            ),
                          ),
                      child: Icon(Icons.edit, size: 24, color: AppColors.black),
                    ),
                  ],
                ),
              ),
        ],
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: _isLoading ? false : true,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPatientStatus(),
                    _buildGraph(widget.patientId),
                    Divider(),
                    _buildActions(widget.role),
                    Divider(),
                    _buildInterventions(),
                    const SizedBox(height: 20.0),
                    _buildCarousel(),
                  ],
                ),
              ),
    );
  }
}

class ChartData {
  final String x;
  final double y;

  ChartData({required this.x, required this.y});
}
