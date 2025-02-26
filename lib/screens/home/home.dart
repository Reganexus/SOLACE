import 'package:flutter/material.dart';
import 'package:solace/screens/admin/admin_home.dart';
import 'package:solace/screens/doctor/doctor_home.dart';
import 'package:solace/screens/patient/patient_home.dart';
import 'package:solace/screens/wrapper.dart';

class Home extends StatelessWidget {
  final String uid;
  final String role;

  const Home({required this.uid, required this.role, super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("Home role: $role");
    switch (role) {
      case 'admin':
        return const AdminHome();
      case 'doctor':
        return const DoctorHome();
      case 'caregiver':
        return const PatientHome();
      default:
        return const Wrapper();
    }
  }
}
