import 'package:flutter/material.dart';
import 'package:solace/shared/widgets/interventions.dart';
import 'package:solace/themes/colors.dart';

class PatientIntervention extends StatefulWidget {
  const PatientIntervention({super.key, required this.patientId});
  final String patientId;

  @override
  PatientInterventionState createState() => PatientInterventionState();
}

class PatientInterventionState extends State<PatientIntervention> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: InterventionsView(patientId: widget.patientId),
    );
  }
}
