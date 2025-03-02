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

  int caregiverCount = 0;
  int doctorCount = 0;
  int adminCount = 0;
  int totalUsers = 0;
  int stableCount = 0;
  int unstableCount = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final userCounts = await Future.wait([
        firestore
            .collection('caregiver')
            .where('userRole', isEqualTo: 'caregiver')
            .get(),
        firestore
            .collection('doctor')
            .where('userRole', isEqualTo: 'doctor')
            .get(),
        firestore
            .collection('admin')
            .where('userRole', isEqualTo: 'admin')
            .get(),
      ]);

      final statusCounts = await Future.wait([
        firestore
            .collection('caregiver')
            .where('userRole', isEqualTo: 'patient')
            .where('status', isEqualTo: 'stable')
            .get(),
        firestore
            .collection('caregiver')
            .where('userRole', isEqualTo: 'patient')
            .where('status', isEqualTo: 'unstable')
            .get(),
      ]);

      setState(() {
        caregiverCount = userCounts[0].size;
        doctorCount = userCounts[1].size;
        adminCount = userCounts[2].size;
        totalUsers = caregiverCount + doctorCount + adminCount;

        stableCount = statusCounts[0].size;
        unstableCount = statusCounts[1].size;
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Widget _buildSquareContainer(String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
          color: AppColors.black,
        ),
      ),
    );
  }

  Widget _buildStatusItem(String count, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Inter',
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, double fontSize) {
    return Container(
      alignment: Alignment.center,
      height: fontSize + 10, // Add padding for better visual spacing
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Inter',
          color: AppColors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Container(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount:
                  2, // Two items in a row for "Stable" and "Unstable"
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatusItem('$stableCount', 'Stable', AppColors.neon),
                _buildStatusItem('$unstableCount', 'Unstable', AppColors.red),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Users Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSquareContainer('$caregiverCount', AppColors.gray),
                _buildSquareContainer('$doctorCount', AppColors.gray),
                _buildSquareContainer('$adminCount', AppColors.gray),
                _buildSquareContainer('$totalUsers', AppColors.gray),
              ],
            ),
            SizedBox(
              height: 5,
            ),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                childAspectRatio:
                    4, // Make the grid cells rectangular, suitable for text
              ),
              itemCount: 4, // Number of labels
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final labels = ['Caregivers', 'Doctors', 'Admins', 'Users'];
                return _buildLabel(
                    labels[index], 12); // Use dynamic font size if needed
              },
            ),
          ],
        ),
      ),
    );
  }
}
