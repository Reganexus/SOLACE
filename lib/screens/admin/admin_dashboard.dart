// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this for Firestore
import 'package:solace/themes/colors.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Variables to hold the counts
  int patientCount = 0;
  int caregiverCount = 0;
  int doctorCount = 0;
  int adminCount = 0;
  int totalUsers = 0;
  int noRiskCount = 0;
  int lowRiskCount = 0;
  int highRiskCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUserCounts();
    fetchStatusCounts();
  }

  // Function to fetch user counts by userRole
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

      final doctorSnapshot = await firestore
          .collection('users')
          .where('userRole', isEqualTo: 'doctor')
          .get();

      final adminSnapshot = await firestore
          .collection('users')
          .where('userRole', isEqualTo: 'admin')
          .get();

      setState(() {
        patientCount = patientSnapshot.size;
        caregiverCount = caregiverSnapshot.size;
        doctorCount = doctorSnapshot.size;
        adminCount = adminSnapshot.size;
        totalUsers = patientCount + caregiverCount + doctorCount + adminCount;
      });
    } catch (e) {
      print('Error fetching user counts: $e');
    }
  }

  // Function to fetch status counts (No Risk, Low Risk, High Risk)
  Future<void> fetchStatusCounts() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Assuming status data is available in a collection like 'statusData'
      final statusSnapshot = await firestore.collection('statusData').get();

      if (statusSnapshot.docs.isEmpty) {
        setState(() {
          noRiskCount = 0;
          lowRiskCount = 0;
          highRiskCount = 0;
        });
        return;
      }

      // Initialize counts
      int tempNoRisk = 0;
      int tempLowRisk = 0;
      int tempHighRisk = 0;

      // Loop through each document and check the 'riskLevel' field
      for (var doc in statusSnapshot.docs) {
        var riskLevel = doc['riskLevel']; // Adjust field name according to your Firestore structure

        // Check risk level and increment appropriate counter
        if (riskLevel == 'noRisk') {
          tempNoRisk++;
        } else if (riskLevel == 'lowRisk') {
          tempLowRisk++;
        } else if (riskLevel == 'highRisk') {
          tempHighRisk++;
        }
      }

      // Update state with the final counts
      setState(() {
        noRiskCount = tempNoRisk;
        lowRiskCount = tempLowRisk;
        highRiskCount = tempHighRisk;
      });

    } catch (e) {
      print('Error fetching status counts: $e');
      setState(() {
        noRiskCount = 0;
        lowRiskCount = 0;
        highRiskCount = 0;
      });
    }
  }

  Widget _buildSquareContainer(String title, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
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
            fontSize: 14,
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
                      '$caregiverCount', 'Caregivers', AppColors.purple),
                  _buildSquareContainer(
                      '$doctorCount', 'Doctors', AppColors.neon),
                  _buildSquareContainer(
                      '$adminCount', 'Admins', AppColors.darkgray),
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
                  _buildSquareContainer(
                      '$noRiskCount', 'No Risk', AppColors.neon),
                  _buildSquareContainer(
                      '$lowRiskCount', 'Low Risk', AppColors.yellow),
                  _buildSquareContainer(
                      '$highRiskCount', 'High Risk', AppColors.red),
                  _buildSquareContainer(
                      '$totalUsers', 'Total Users', AppColors.darkblue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
