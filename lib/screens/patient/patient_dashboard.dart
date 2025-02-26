// ignore_for_file: unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/controllers/cloud_messaging.dart';
import 'package:solace/controllers/getaccesstoken.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/patient/patient_history.dart';
import 'package:solace/screens/patient/patient_info.dart';
import 'package:solace/screens/patient/patient_intervention.dart';
import 'package:solace/screens/patient/patient_note.dart';
import 'package:solace/screens/patient/patient_tasks.dart';
import 'package:solace/screens/patient/patient_schedule.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/contacts.dart';
import 'package:solace/shared/widgets/medicine.dart';
import 'package:solace/themes/colors.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  PatientDashboardState createState() => PatientDashboardState();
}

class PatientDashboardState extends State<PatientDashboard> {
  final List<Map<String, dynamic>> gridItems = [
    {'label': 'Contacts', 'icon': Icons.contact_page_rounded},
    {'label': 'History', 'icon': Icons.history},
    {'label': 'Intervention', 'icon': Icons.healing},
    {'label': 'Medicine', 'icon': Icons.medical_services_rounded},
    {'label': 'Notes', 'icon': Icons.create_rounded},
    {'label': 'Schedule', 'icon': Icons.calendar_today},
    {'label': 'Tasks', 'icon': Icons.task},
    {'label': 'Patient', 'icon': Icons.person},
  ];

  final Map<String, Widget Function(String)> routes = {
    'Contacts': (userId) => Contacts(currentUserId: userId),
    'History': (userId) => PatientHistory(currentUserId: userId),
    'Intervention': (userId) => PatientIntervention(currentUserId: userId),
    'Medicine': (userId) => Medicine(currentUserId: userId),
    'Notes': (userId) => PatientNote(currentUserId: userId),
    'Schedule': (userId) => PatientSchedule(currentUserId: userId),
    'Tasks': (userId) => PatientTasks(currentUserId: userId),
    'Patient': (userId) => PatientInfo(currentUserId: userId),
  };

  Widget _buildIconContainer(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Icon(
        icon,
        size: 28,
        color: AppColors.black,
      ),
    );
  }

  List<Widget> _buildAlternatingItems(BuildContext context, String? userId) {
    final List<Widget> items = [];
    for (int i = 0; i < gridItems.length; i += 4) {
      final iconBatch = gridItems.skip(i).take(4).toList();

      items.add(GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: iconBatch.length,
        itemBuilder: (context, index) {
          final item = iconBatch[index];
          return GestureDetector(
            onTap: () {
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => routes[item['label']]!(userId),
                  ),
                );
              }
            },
            child: _buildIconContainer(item['icon']),
          );
        },
      ));

      items.add(const SizedBox(height: 5));

      items.add(GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          childAspectRatio: 4,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: iconBatch.length,
        itemBuilder: (context, index) {
          return Text(
            iconBatch[index]['label'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          );
        },
      ));

      if (i + 4 < gridItems.length / 2 * 4) {
        items.add(const SizedBox(height: 20));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        // Wrap the content to handle overflow and scrolling
        child: Container(
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Status Section
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(
                        'patient') // Assuming you have a 'patients' collection
                    .doc(
                        user?.uid) // Document ID for the current user (patient)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Error fetching data'));
                  }

                  final hasData = snapshot.hasData && snapshot.data!.exists;
                  final patientData = hasData
                      ? snapshot.data!.data() as Map<String, dynamic>
                      : null;
                  final status = hasData
                      ? patientData!['status'] ?? 'stable'
                      : 'unavailable';
                  final isUnstable = status == 'unstable';
                  final isUnavailable = !hasData;

                  final statusMessage = isUnavailable
                      ? 'No patient data available.'
                      : isUnstable
                          ? '⚠️ Symptoms detected. Please consult your doctor.'
                          : 'ⓘ No symptoms detected. Keep up the good work!';
                  final backgroundColor = isUnavailable
                      ? AppColors.blackTransparent
                      : isUnstable
                          ? AppColors.red
                          : AppColors.neon;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient Status',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 30.0, horizontal: 15.0),
                              child: Text(
                                isUnavailable
                                    ? 'Unavailable'
                                    : isUnstable
                                        ? 'Unstable'
                                        : 'Stable',
                                style: const TextStyle(
                                  fontSize: 50.0,
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12.0),
                              decoration: const BoxDecoration(
                                color: AppColors.blackTransparent,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(10.0),
                                  bottomRight: Radius.circular(10.0),
                                ),
                              ),
                              child: Text(
                                statusMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Spacer
              const SizedBox(height: 30.0),

              // Alternating Grid Items
              ..._buildAlternatingItems(context, user?.uid),

              // Spacer
              const SizedBox(height: 30.0),
            ],
          ),
        ),
      ),
    );
  }
}
