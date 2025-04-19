// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/screens/admin/admin_export_dataset.dart';
import 'package:solace/screens/admin/export_data.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int adminCount = 0;
  int caregiverCount = 0;
  int doctorCount = 0;
  int nurseCount = 0;
  int patientCount = 0;
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
            .collection('admin')
            .where('userRole', isEqualTo: 'admin')
            .get(),
        firestore
            .collection('caregiver')
            .where('userRole', isEqualTo: 'caregiver')
            .get(),
        firestore
            .collection('doctor')
            .where('userRole', isEqualTo: 'doctor')
            .get(),
        firestore
            .collection('nurse')
            .where('userRole', isEqualTo: 'nurse')
            .get(),
        firestore
            .collection('patient')
            .where('userRole', isEqualTo: 'patient')
            .get(),
      ]);

      final statusCounts = await Future.wait([
        firestore
            .collection('patient')
            .where('status', isEqualTo: 'stable')
            .get(),
        firestore
            .collection('patient')
            .where('status', isEqualTo: 'unstable')
            .get(),
      ]);

      setState(() {
        adminCount = userCounts[0].size;
        caregiverCount = userCounts[1].size;
        doctorCount = userCounts[2].size;
        nurseCount = userCounts[3].size;
        patientCount = userCounts[4].size;
        stableCount = statusCounts[0].size;
        unstableCount = statusCounts[1].size;
      });
    } catch (e) {
      //     debugPrint('Error fetching data: $e');
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
        style: Textstyle.bodyWhite.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        label,
        style: Textstyle.bodySmall.copyWith(color: AppColors.black),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCounter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildSquareContainer('$adminCount', AppColors.neon),
            _buildSquareContainer('$caregiverCount', AppColors.purple),
            _buildSquareContainer('$doctorCount', AppColors.darkpurple),
            _buildSquareContainer('$nurseCount', AppColors.darkblue),
          ],
        ),
        const SizedBox(height: 5),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            childAspectRatio: 4,
          ),
          itemCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final labels = ['Admins', 'Caregivers', 'Doctors', 'Nurses'];
            return _buildLabel(labels[index]);
          },
        ),
      ],
    );
  }

  Widget _buildExport() {
    final List<Map<String, String>> exportOptions = [
      {'filterValue': 'caregiver', 'title': 'Export Caregiver Data'},
      {'filterValue': 'doctor', 'title': 'Export Doctor Data'},
      {'filterValue': 'nurse', 'title': 'Export Nurse Data'},
      {'filterValue': 'patient', 'title': 'Export Patient Data'},
      {'filterValue': 'stable', 'title': 'Export Stable Patients'},
      {'filterValue': 'unstable', 'title': 'Export Unstable Patients'},
    ];

    Future<void> showConfirmationDialog(
      BuildContext context,
      String filterValue,
      String title,
    ) async {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.white,
            title: Text('Confirmation', style: Textstyle.subheader),
            content: Text(
              'Are you sure you want to proceed with $title?',
              style: Textstyle.body,
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: Buttonstyle.buttonRed,
                      child: Text('Cancel', style: Textstyle.smallButton),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: Buttonstyle.buttonNeon,
                      child: Text('Proceed', style: Textstyle.smallButton),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ExportDataScreen(filterValue: filterValue, title: title),
          ),
        );
      }
    }

    Widget buildExportOption(String filterValue, String title) {
      return GestureDetector(
        onTap: () => showConfirmationDialog(context, filterValue, title),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.gray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(child: Text(title, style: Textstyle.body)),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Export Data', style: Textstyle.subheader),
        Text(
          'Export Data by tapping the desired category to export.',
          style: Textstyle.body,
        ),
        const SizedBox(height: 20),
        for (var option in exportOptions) ...[
          buildExportOption(option['filterValue']!, option['title']!),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildExportDataset() {
    Future<void> showConfirmationDialog(BuildContext context) async {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.white,
            title: Text('Confirmation', style: Textstyle.subheader),
            content: Text(
              'Are you sure you want to export the dataset?',
              style: Textstyle.body,
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: Buttonstyle.buttonRed,
                      child: Text('Cancel', style: Textstyle.smallButton),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: Buttonstyle.buttonNeon,
                      child: Text('Proceed', style: Textstyle.smallButton),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        try {
          await ExportDataset.exportTrackingData();
        } catch (e) {
          showToast("Export failed: $e", backgroundColor: AppColors.red);
        }
      }
    }

    return Container(
      color: AppColors.darkblue,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Dataset',
            style: Textstyle.subheader.copyWith(color: AppColors.white),
          ),
          Text(
            'This function is to help future researchers and future developers. Export this dataset to help contribute improve the algorithm.',
            style: Textstyle.bodyWhite,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => showConfirmationDialog(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.blackTransparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Export Dataset', style: Textstyle.bodyWhite),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  StatisticsRow(
                    total: patientCount,
                    stable: stableCount,
                    unstable: unstableCount,
                  ),
                  const SizedBox(height: 10),
                  _buildCounter(),
                  const SizedBox(height: 10),
                  Divider(),
                  const SizedBox(height: 10),
                  _buildExport(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            _buildExportDataset(),
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
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: 200,
            color: AppColors.darkblue,
            child: Stack(
              children: [
                Positioned(
                  right: 10,
                  bottom: 35,
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
        Positioned(
          bottom: 50,
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
            ],
          ),
        ),
      ],
    );
  }
}
