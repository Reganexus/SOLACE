// ignore_for_file: avoid_print, unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/models/my_patient.dart';
import 'package:solace/screens/caregiver/caregiver_add_patient.dart';
import 'package:solace/screens/patient/patient_dashboard.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';

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
      final role = await db.getTargetUserRole(caregiverId);
      setState(() {
        userRole = role;
      });
    } catch (e) {
      setState(() {
        userRole = null; // Handle error case
      });
    }
  }

  Stream<List<PatientData>> _fetchPatients() {
    return FirebaseFirestore.instance
        .collection('patient')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => PatientData.fromDocument(doc))
                  .toList(),
        );
  }

  void _navigateToPatientDashboard(PatientData patient) {
    if (userRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to determine user role.')),
      );
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

  Widget _buildPatientList(List<PatientData> patients) {
    return ListView.builder(
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
              vertical: 10.0,
              horizontal: 15.0,
            ),
            decoration: BoxDecoration(
              color: AppColors.gray,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24.0,
                  backgroundImage: patient.profileImageUrl.isNotEmpty
                      ? NetworkImage(patient.profileImageUrl)
                      : AssetImage('lib/assets/images/shared/placeholder.png') as ImageProvider,
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    '${patient.firstName} ${patient.lastName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18.0,
                    color: AppColors.black,
                  ),
                  onPressed: () => _navigateToPatientDashboard(patient),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoPatientState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.person_off_rounded,
            color: AppColors.black,
            size: 80,
          ),
          SizedBox(height: 20.0),
          Text(
            "No Patients Yet",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 10.0),
          Text(
            "Add by patients by clicking the '+' button",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: AppColors.black,
            ),
          ),
        ],
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Patient List',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 20.0),
              if (userRole == null)
                const Center(child: CircularProgressIndicator())
              else
                Expanded(
                  child: StreamBuilder<List<PatientData>>(
                    stream: _fetchPatients(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error loading patients: ${snapshot.error}",
                          ),
                        );
                      }

                      final patients = snapshot.data ?? [];

                      if (patients.isEmpty) {
                        return _buildNoPatientState();
                      }

                      return _buildPatientList(patients);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CaregiverAddPatient(),
            ),
          );
        },
        backgroundColor: AppColors.neon,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
