import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/interventions.dart';
import 'package:solace/shared/widgets/qr_scan.dart';
import 'package:solace/themes/colors.dart';

class CaregiverIntervention extends StatefulWidget {
  const CaregiverIntervention({super.key});

  @override
  CaregiverInterventionState createState() => CaregiverInterventionState();
}

class CaregiverInterventionState extends State<CaregiverIntervention> {
  final DatabaseService db = DatabaseService();
  String? currentUserId;
  String? patientUid;

  Future<void> _showSearchModal(BuildContext context) async {
    final TextEditingController uidController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            'Add Patient',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: uidController,
                  decoration: InputDecoration(
                    labelText: 'Enter Patient UID',
                    filled: true,
                    fillColor: AppColors.gray,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.neon),
                    ),
                  ),
                  style: TextStyle(fontSize: 18, fontFamily: 'Inter'),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    String targetUserId = uidController.text.trim();
                    if (targetUserId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a valid UID')),
                      );
                      return;
                    }

                    bool exists = await db.checkUserExists(targetUserId);
                    if (!exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User not found')),
                      );
                      return;
                    }

                    bool isContact = await db.isUserHealthcareContact(
                        currentUserId!, targetUserId);
                    if (isContact) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'This user is already your healthcare contact!')),
                      );
                      return;
                    }

                    bool hasPendingRequest =
                        await db.hasPendingHealthcareRequest(
                            currentUserId!, targetUserId);
                    if (hasPendingRequest) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Healthcare request already sent!')),
                      );
                      return;
                    }

                    await db.sendHealthcareRequest(
                        currentUserId!, targetUserId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Healthcare request sent!')),
                    );
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.neon,
                    foregroundColor: AppColors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.group_add),
                      SizedBox(width: 10),
                      Text(
                        'Send Request',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleQRScanResult(BuildContext context, String result) async {
    try {
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User is not logged in')),
        );
        return;
      }

      bool exists = await db.checkUserExists(result);
      if (!exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not found')),
        );
        return;
      }

      bool isContact = await db.isUserHealthcareContact(currentUserId!, result);
      if (isContact) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('This user is already your healthcare contact!')),
        );
        return;
      }

      bool hasPendingRequest =
          await db.hasPendingHealthcareRequest(currentUserId!, result);
      if (hasPendingRequest) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Healthcare request already sent!')),
        );
        return;
      }

      await db.sendHealthcareRequest(currentUserId!, result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Healthcare request sent to $result')),
      );
    } catch (e) {
      debugPrint('Error handling QR scan result: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process QR scan result')),
      );
    }
  }

  Future<void> _fetchPatientInfo() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          currentUserId = user.uid;
        });

        // Fetch caregiver document
        DocumentSnapshot caregiverDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        var healthcare = caregiverDoc['contacts']?['healthcare'];
        if (healthcare != null && healthcare.isNotEmpty) {
          setState(() {
            patientUid = healthcare.keys.first; // Get the first patient's UID
          });
        } else {
          setState(() {
            patientUid = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching patient info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch patient info')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPatientInfo(); // Fetch patient info on initialization
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: patientUid == null
          ? Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppColors.neon,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gray.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add your patient',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Select one of the methods below',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.normal,
                      fontSize: 18,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // TextButton with Icon for Enter UID
                      TextButton.icon(
                        onPressed: () => _showSearchModal(context),
                        icon: Icon(
                          Icons.person_add,
                          color: AppColors.white,
                        ),
                        label: Text(
                          'Enter UID',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16.0,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors
                              .blackTransparent, // Set background color
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.0),
                      // TextButton with Icon for Scan QR Code
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const QRScannerPage()),
                          );
                          if (result != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('QR Code detected')),
                            );
                            _handleQRScanResult(context, result);
                          }
                        },
                        icon: Icon(
                          Icons.qr_code_scanner,
                          color: AppColors.white,
                        ),
                        label: Text(
                          'Scan QR',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16.0,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors
                              .blackTransparent, // Set background color
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : InterventionsView(
              uid: patientUid!), // Pass the patientUid to the InterventionsView
    );
  }
}
