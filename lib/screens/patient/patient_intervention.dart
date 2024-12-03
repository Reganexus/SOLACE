import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/interventions.dart';
import 'package:solace/shared/widgets/qr_scan.dart';
import 'package:solace/themes/colors.dart';

class PatientIntervention extends StatefulWidget {
  const PatientIntervention({super.key});

  @override
  PatientInterventionState createState() => PatientInterventionState();
}

class PatientInterventionState extends State<PatientIntervention> {
  final String patientId =
      FirebaseAuth.instance.currentUser!.uid; // Fetch patientId

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: InterventionsView(uid: patientId),
    );
  }
}
