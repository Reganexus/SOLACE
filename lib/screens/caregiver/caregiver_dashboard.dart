// ignore_for_file: avoid_print, unused_import

import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/models/my_patient.dart';
import 'package:solace/screens/caregiver/caregiver_add_patient.dart';
import 'package:solace/screens/caregiver/caregiver_instructions.dart';
import 'package:solace/screens/patient/patient_dashboard.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  CaregiverDashboardState createState() => CaregiverDashboardState();
}

class CaregiverDashboardState extends State<CaregiverDashboard> {
  final DatabaseService db = DatabaseService();
  late final String caregiverId;
  String? userRole;

  @override
  void initState() {
    super.initState();
    caregiverId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      final role = await db.fetchAndCacheUserRole(caregiverId);
      setState(() {
        userRole = role;
      });
    } catch (e) {
      setState(() {
        userRole = null; // Handle error case
      });
    }
  }

  Stream<Map<String, dynamic>> _fetchPatients() {
    return FirebaseFirestore.instance.collection('patient').snapshots().map((
      snapshot,
    ) {
      // Initialize counters
      int stableCount = 0;
      int unstableCount = 0;

      // Map documents to PatientData and count status
      final patients =
          snapshot.docs.map((doc) {
            final data = PatientData.fromDocument(doc);
            if (data.status == 'stable') {
              stableCount++;
            } else if (data.status == 'unstable') {
              unstableCount++;
            }
            return data;
          }).toList();

      return {
        'patients': patients,
        'total': patients.length,
        'stable': stableCount,
        'unstable': unstableCount,
      };
    });
  }

  void _navigateToPatientDashboard(PatientData patient) {
    if (userRole == null) {
      showToast('Unable to determine user role.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PatientsDashboard(
              patientId: patient.uid,
              caregiverId: caregiverId,
              role: userRole!, // Safely pass the role
            ),
      ),
    );
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  Widget _buildPatientList(List<PatientData> patients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Patient List', style: Textstyle.subheader),
        const SizedBox(height: 10.0),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];

            return GestureDetector(
              onTap: () => _navigateToPatientDashboard(patient),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  vertical: 5.0,
                  horizontal: 8.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gray,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20.0,
                      backgroundImage:
                          patient.profileImageUrl.isNotEmpty
                              ? NetworkImage(patient.profileImageUrl)
                              : AssetImage(
                                    'lib/assets/images/shared/placeholder.png',
                                  )
                                  as ImageProvider,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Text(
                        '${patient.firstName} ${patient.lastName}',
                        style: Textstyle.body,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16.0,
                            color: AppColors.black,
                          ),
                          onPressed: () => _navigateToPatientDashboard(patient),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoPatientState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off_rounded,
              color: AppColors.black,
              size: 80,
            ),
            const SizedBox(height: 20.0),
            Text("No Patients Yet", style: Textstyle.subheader),
            const SizedBox(height: 10.0),
            Text(
              "Add by patients by clicking the 'Add Patient' button",
              style: Textstyle.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userRole == null)
              Center(child: Loader.loaderWhite)
            else
              Expanded(
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: _fetchPatients(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: Loader.loaderWhite);
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error loading patients: ${snapshot.error}",
                          style: Textstyle.body,
                        ),
                      );
                    }

                    final data =
                        snapshot.data ??
                        {
                          'patients': [],
                          'total': 0,
                          'stable': 0,
                          'unstable': 0,
                        };

                    final patients = data['patients'] as List<PatientData>;
                    final total = data['total'] as int;
                    final stable = data['stable'] as int;
                    final unstable = data['unstable'] as int;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                      child: Column(
                        children: [
                          StatisticsRow(
                            total: total,
                            stable: stable,
                            unstable: unstable,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 0, 153, 122),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (patients.isNotEmpty)
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: AppColors.white,
                                  ),
                                const SizedBox(width: 10),
                                Text(
                                  patients.isEmpty
                                      ? ''
                                      : 'Tap on the list of patients to monitor them.',
                                  style: Textstyle.bodySuperSmall.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Conditional rendering of patient data
                          Expanded(
                            child:
                                patients.isEmpty
                                    ? _buildNoPatientState()
                                    : _buildPatientList(patients),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StatisticsRow extends StatelessWidget {
  final int total;
  final int stable;
  final int unstable;

  const StatisticsRow({
    super.key,
    required this.total,
    required this.stable,
    required this.unstable,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          child: Container(
            width: double.infinity,
            height: 220,
            color: AppColors.darkblue,
            child: Stack(
              children: [
                Positioned(
                  right: 10,
                  bottom: 40,
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: Image.asset(
                      'lib/assets/images/auth/solace.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: 30,
                    sigmaY: 30,
                    tileMode: TileMode.clamp,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    color: AppColors.blackTransparent,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Name and button overlay
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                '$total',
                style: Textstyle.title.copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                total == 0 || total == 1 ? 'Patient Total' : 'Patients Total',
                style: Textstyle.bodySmall.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '$stable Stable',
                    style: Textstyle.body.copyWith(
                      color: AppColors.neon,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: Offset(1, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '$unstable Unstable',
                    style: Textstyle.body.copyWith(
                      color: AppColors.red,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: Offset(1, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CaregiverAddPatient(),
                          ),
                        );
                      }, // Launch external link
                      style: Buttonstyle.buttonDarkGray,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Add Patient',
                            style: Textstyle.smallButton.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.add, size: 16, color: AppColors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
