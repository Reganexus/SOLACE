// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/controllers/messaging_service.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/admin/admin_export_dataset.dart';
import 'package:solace/screens/admin/export_data.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DatabaseService db = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LogService _logService = LogService();
  late User user;
  bool isLoading = false;

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
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      showToast("Error: No authenticated user found.");
      return;
    }

    user = currentUser;
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

  Stream<List<UserData>> _streamAllRequests() async* {
    try {
      final requestsStream =
          FirebaseFirestore.instance.collection('requests').snapshots();

      await for (final requestsSnapshot in requestsStream) {
        final userIds = requestsSnapshot.docs.map((doc) => doc.id).toList();
        final userDataList = <UserData>[];

        for (final userId in userIds) {
          final userData = await db.fetchUserData(userId);
          if (userData != null) {
            userDataList.add(userData);
          }
        }
        yield userDataList;
      }
    } catch (e) {
      showToast('Error fetching requests: $e');
      yield [];
    }
  }

  Widget _buildRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Requests', style: Textstyle.subheader),
        Text(
          'Authenticate and grant access to familiar accounts',
          style: Textstyle.body,
        ),
        const SizedBox(height: 20),
        StreamBuilder<List<UserData>>(
          stream: _streamAllRequests(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error fetching requests: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.gray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "There are no current requests yet.",
                  style: Textstyle.body,
                  textAlign: TextAlign.center,
                ),
              );
            }

            final requests = snapshot.data!;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...requests.map((userData) {
                    String uid = userData.uid;
                    String email = userData.email;
                    String name =
                        "${userData.firstName} ${userData.middleName?.isNotEmpty == true ? "${userData.middleName} " : ""}${userData.lastName}";
                    String role =
                        "${userData.userRole.name[0].toUpperCase()}${userData.userRole.name.substring(1)}";
                    return GestureDetector(
                      onTap:
                          () => _showRequestInfoDialog(uid, name, email, role),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.gray,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: Textstyle.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(email, style: Textstyle.body),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.more_vert_rounded,
                              color: AppColors.black,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showRequestInfoDialog(
    String uid,
    String name,
    String email,
    String role,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text("Grant Access?", style: Textstyle.subheader),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Do you confirm that $name is a legitimate user and partner of the Foundation?",
                style: Textstyle.body,
              ),
              SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: Textstyle.body,
                  children: [
                    TextSpan(text: "The user is currently applying for the "),
                    TextSpan(
                      text: role,
                      style: Textstyle.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: " role."),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed:
                        isLoading ? null : () => Navigator.of(context).pop(),
                    style:
                        isLoading
                            ? Buttonstyle.buttonGray
                            : Buttonstyle.buttonRed,
                    child: Text("Cancel", style: Textstyle.smallButton),
                  ),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: TextButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              await _revokeUser(uid, name);
                            },
                    style:
                        isLoading
                            ? Buttonstyle.buttonGray
                            : Buttonstyle.buttonPurple,
                    child: Text("Revoke", style: Textstyle.smallButton),
                  ),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: TextButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              await _grantAccessToUser(uid, name);
                              if (mounted) {
                                showToast(
                                  "Successfully granted access to $name",
                                  backgroundColor: AppColors.neon,
                                );
                                Navigator.of(context).pop();
                              }
                            },
                    style:
                        isLoading
                            ? Buttonstyle.buttonGray
                            : Buttonstyle.buttonNeon,
                    child: Text("Confirm", style: Textstyle.smallButton),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _revokeUser(String uid, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text('Confirm Revocation', style: Textstyle.subheader),
          content: Text(
            'Are you sure you want to revoke $name\'s request?',
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
    );

    if (confirmed != true) return;

    setState(() {
      isLoading = true;
    });

    try {
      final userRole = await db.fetchAndCacheUserRole(uid);
      if (userRole == null) {
        showToast("User is not authenticated");
        return;
      }

      await _logService.addLog(
        userId: user.uid,
        action:
            "Revoked $name with user id $uid the permission to access the app",
      );

      final userDoc = await db.fetchUserDocument(uid);
      if (userDoc != null && userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        final fcmToken = data?['fcmToken'] as String?;

        if (fcmToken != null && fcmToken.isNotEmpty) {
          await MessagingService.sendDataMessage(
            fcmToken,
            "Request not Granted",
            "Your pending approval in SOLACE is not approved",
          );
        }
      }

      await db.deleteUser(uid);

      showToast('Successfully revoked access');
    } catch (e) {
      showToast('Error revoking access: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _grantAccessToUser(String uid, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text('Confirm Access Grant', style: Textstyle.subheader),
          content: Text(
            'Are you sure you want to grant access to $name?',
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
    );

    if (confirmed != true) return;

    setState(() {
      isLoading = true;
    });

    try {
      final userRole = await db.fetchAndCacheUserRole(uid);
      if (userRole == null) {
        showToast("User is not authenticated");
        return;
      }

      await FirebaseFirestore.instance.collection(userRole).doc(uid).update({
        'hasAccess': true,
      });

      await FirebaseFirestore.instance.collection('requests').doc(uid).delete();

      await _logService.addLog(
        userId: user.uid,
        action:
            "Granted $name with user id $uid a permission to access the app",
      );

      final userDoc = await db.fetchUserDocument(uid);
      if (userDoc != null && userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        final fcmToken = data?['fcmToken'] as String?;

        if (fcmToken != null && fcmToken.isNotEmpty) {
          await MessagingService.sendDataMessage(
            fcmToken,
            "Request Granted",
            "Your pending approval in SOLACE is now approved",
          );
        }
      }

      showToast('Successfully granted access');
    } catch (e) {
      showToast('Error granting access: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
                  _buildRequests(),
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
