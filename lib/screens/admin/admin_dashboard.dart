// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  int stableCount = 0;
  int unstableCount = 0;

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

  // Function to fetch status counts (Stable, Unstable)
  Future<void> fetchStatusCounts() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Query for users with status 'stable'
      final stableSnapshot = await firestore
          .collection('users')
          .where('status', isEqualTo: 'stable')
          .get();

      // Query for users with status 'unstable'
      final unstableSnapshot = await firestore
          .collection('users')
          .where('status', isEqualTo: 'unstable')
          .get();

      // Update state with the counts
      setState(() {
        stableCount = stableSnapshot.size;
        unstableCount = unstableSnapshot.size;
      });
    } catch (e) {
      print('Error fetching status counts: $e');
      // Reset counts in case of error
      setState(() {
        stableCount = 0;
        unstableCount = 0;
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
                      '$stableCount', 'Stable', AppColors.neon),
                  _buildSquareContainer(
                      '$unstableCount', 'Unstable', AppColors.red),
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