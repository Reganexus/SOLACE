// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  DoctorDashboardState createState() => DoctorDashboardState();
}

class DoctorDashboardState extends State<DoctorDashboard> {
// Variables to hold the counts
  int patientCount = 0;
  int caregiverCount = 0;
  int adminCount = 0;
  int totalUsers = 0;

  @override
  void initState() {
    super.initState();
    fetchUserCounts();
  }

  // Function to fetch user counts
  Future<void> fetchUserCounts() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Query for each user role
      final patientSnapshot = await firestore
          .collection('users')
          .where('userRole', isEqualTo: 'patient')
          .get();

      final caregiverSnapshot = await firestore
          .collection('users')
          .where('userRole', isEqualTo: 'caregiver')
          .get();

      final adminSnapshot = await firestore
          .collection('users')
          .where('userRole', isEqualTo: 'admin')
          .get();

      setState(() {
        patientCount = patientSnapshot.size;
        caregiverCount = caregiverSnapshot.size;
        adminCount = adminSnapshot.size;
        totalUsers = patientCount + caregiverCount + adminCount;
      });
    } catch (e) {
      print('Error fetching user counts: $e');
    }
  }

  Widget _buildSquareContainer(String title, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: 8), // Spacing between the container and label
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            fontFamily: 'Inter',
            color: AppColors.black,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Users Data Section
              const Text(
                'Users Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16, // Horizontal spacing between boxes
                runSpacing: 16, // Vertical spacing between rows
                alignment: WrapAlignment.start,
                children: [
                  _buildSquareContainer(
                      '$patientCount', 'Patients', AppColors.blue),
                  _buildSquareContainer(
                      '$caregiverCount', 'Caregiver', AppColors.purple),
                  _buildSquareContainer('$adminCount', 'Admin', AppColors.neon),
                  _buildSquareContainer(
                      '$totalUsers', 'Total Users', AppColors.darkblue),
                ],
              ),
              const SizedBox(height: 30),
              // Status Data Section
              const Text(
                'Status Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16, // Horizontal spacing between boxes
                runSpacing: 16, // Vertical spacing between rows
                alignment: WrapAlignment.start,
                children: [
                  _buildSquareContainer('80', 'No Risk', AppColors.neon),
                  _buildSquareContainer('15', 'Low Risk', AppColors.yellow),
                  _buildSquareContainer('5', 'High Risk', AppColors.red),
                  _buildSquareContainer('5', 'Unknown', AppColors.darkgray),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
