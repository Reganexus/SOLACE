// ignore_for_file: avoid_print, unused_import

import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/controllers/messaging_service.dart';
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
  bool _showAllPatients = true;
  bool _showTaggedPatients = false;

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
        userRole = null;
      });
    }
  }

  Stream<List<PatientData>> _allPatientsStream() {
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

  Stream<List<PatientData>> _taggedPatientsStream(String caregiverId) {
    return FirebaseFirestore.instance
        .collection(
          userRole!,
        ) // Collection for the specific user role (e.g., caregiver)
        .doc(caregiverId) // Document for the specific caregiver
        .collection(
          'tags',
        ) // Subcollection containing the tagged patients (by patient ID)
        .snapshots()
        .asyncMap((snapshot) async {
          var patientIds = snapshot.docs.map((doc) => doc.id).toList();

          if (patientIds.isEmpty) return []; // No tagged patients

          // Check if the patient documents exist in the 'patient' collection
          var patientSnapshots =
              await FirebaseFirestore.instance
                  .collection('patient')
                  .where(FieldPath.documentId, whereIn: patientIds)
                  .get();

          // List of valid patient IDs that still exist in the 'patient' collection
          var validPatientIds =
              patientSnapshots.docs.map((doc) => doc.id).toList();

          // Delete any invalid tagged patient records
          for (var doc in snapshot.docs) {
            if (!validPatientIds.contains(doc.id)) {
              await FirebaseFirestore.instance
                  .collection(userRole!)
                  .doc(caregiverId)
                  .collection('tags')
                  .doc(doc.id)
                  .delete();
            }
          }

          // Return the list of valid PatientData
          return patientSnapshots.docs
              .map((doc) => PatientData.fromDocument(doc))
              .toList();
        });
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

  Future<String?> fetchUserToken() async {
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        return token;
      } else {
        //         debugPrint("Failed to fetch FCM token.");
        return null;
      }
    } catch (e) {
      //       debugPrint("Error fetching FCM token: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (userRole == null)
                Center(child: Loader.loaderWhite)
              else
                Column(
                  children: [
                    if (userRole == 'doctor' || userRole == 'nurse')
                      _buildPatientContent(),
                    if (userRole == 'caregiver')
                      _buildCaregiverPatientContent(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientSelection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Filter List",
            style: Textstyle.body.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Select the list you want to view.",
            style: Textstyle.bodySmall.copyWith(color: AppColors.white),
          ),

          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ChoiceChip(
                checkmarkColor: AppColors.white,
                label: Text(
                  'All Patients',
                  style: Textstyle.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight:
                        _showAllPatients ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: _showAllPatients,
                onSelected: (bool selected) {
                  setState(() {
                    _showAllPatients = true;
                    _showTaggedPatients = false;
                  });
                },
                selectedColor: AppColors.neon,
                backgroundColor: AppColors.black.withValues(alpha: 0.6),
                side: BorderSide(color: Colors.transparent),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                checkmarkColor: AppColors.white,
                labelPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                label: Text(
                  'Assigned Patients',
                  style: Textstyle.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight:
                        _showTaggedPatients
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
                selected: _showTaggedPatients,
                onSelected: (bool selected) {
                  setState(() {
                    _showTaggedPatients = true;
                    _showAllPatients = false;
                  });
                },
                selectedColor: AppColors.neon,
                backgroundColor: AppColors.black.withValues(alpha: 0.6),
                side: BorderSide(color: Colors.transparent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientContent() {
    return Column(
      children: [
        if (_showAllPatients)
          StreamBuilder<List<PatientData>>(
            stream: _allPatientsStream(),
            builder: (context, allPatientsSnapshot) {
              return _buildPatientContentColumn(
                allPatientsSnapshot,
                'Patient Lists',
              );
            },
          ),
        if (_showTaggedPatients)
          StreamBuilder<List<PatientData>>(
            stream: _taggedPatientsStream(caregiverId),
            builder: (context, taggedPatientsSnapshot) {
              return _buildPatientContentColumn(
                taggedPatientsSnapshot,
                'Assigned Patients',
              );
            },
          ),
      ],
    );
  }

  Widget _buildPatientContentColumn(
    AsyncSnapshot<List<PatientData>> snapshot,
    String title,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: Loader.loaderWhite);
    }
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    List<PatientData> patients = snapshot.data ?? [];
    int total = patients.length;
    int stableCount = patients.where((p) => p.status == 'stable').length;
    int unstableCount = patients.where((p) => p.status == 'unstable').length;

    return Column(
      children: [
        StatisticsRow(
          total: total,
          stable: stableCount,
          unstable: unstableCount,
          role: userRole.toString(),
        ),
        if (userRole == 'doctor' || userRole == 'nurse')
          _buildPatientSelection(),

        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text('The', style: Textstyle.bodySmall),
              SizedBox(width: 4.0),
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.red,
                size: 20.0,
              ),
              SizedBox(width: 4.0),
              Text('indicates Unstable Patients', style: Textstyle.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (patients.isEmpty)
          SizedBox(height: 300, child: _buildNoPatientState()),
        if (patients.isNotEmpty) _buildPatientList(title, patients),
      ],
    );
  }

  Widget _buildCaregiverPatientContent() {
    return StreamBuilder<List<PatientData>>(
      stream: _taggedPatientsStream(caregiverId),
      builder: (context, snapshot) {
        return _buildPatientContentColumn(snapshot, 'Your Patients');
      },
    );
  }

  Widget _buildNoPatientState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_off_rounded,
            color: AppColors.black,
            size: 70,
          ),
          const SizedBox(height: 10.0),
          Text(
            "No Patients Yet",
            style: Textstyle.body.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10.0),
          Text(
            "Add patients by clicking the 'Add Patient' button",
            style: Textstyle.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList(String title, List<PatientData> patients) {
    // Sort the patients list: 'unstable' patients first and then alphabetical order
    patients.sort((a, b) {
      // Check for status first: unstable patients first
      if (a.status == 'unstable' && b.status != 'unstable') {
        return -1; // a comes before b
      } else if (a.status != 'unstable' && b.status == 'unstable') {
        return 1; // b comes before a
      } else {
        // If both are the same status, sort alphabetically by first and last name
        final nameA = '${a.firstName} ${a.lastName}'.toLowerCase();
        final nameB = '${b.firstName} ${b.lastName}'.toLowerCase();
        return nameA.compareTo(nameB); // Alphabetical order
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Textstyle.subheader),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${patient.firstName} ${patient.lastName}',
                              style: Textstyle.body,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (patient.status == 'unstable') ...[
                            const SizedBox(width: 8.0),
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.red,
                              size: 20.0,
                            ),
                          ],
                        ],
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

  void _navigateToPatientDashboard(PatientData patient) {
    if (userRole == null) {
      showToast(
        'Unable to determine user role.',
        backgroundColor: AppColors.red,
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
              role: userRole!,
            ),
      ),
    );
  }
}

class StatisticsRow extends StatelessWidget {
  final int total;
  final int stable;
  final int unstable;
  final String role;

  const StatisticsRow({
    super.key,
    required this.total,
    required this.stable,
    required this.unstable,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius:
              role == 'caregiver'
                  ? BorderRadius.circular(10)
                  : BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
          child: Container(
            width: double.infinity,
            height: 200,
            color: AppColors.darkblue,
            child: Stack(
              children: [
                Positioned(
                  right: 10,
                  bottom: 40,
                  child: SizedBox(
                    width: 130,
                    height: 130,
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
