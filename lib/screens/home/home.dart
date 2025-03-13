import 'package:flutter/material.dart';
import 'package:solace/controllers/messaging_service.dart';
import 'package:solace/screens/admin/admin_home.dart';
import 'package:solace/screens/caregiver/caregiver_home.dart';
import 'package:solace/screens/wrapper.dart';

class Home extends StatefulWidget {
  final String uid;
  final String role;

  const Home({required this.uid, required this.role, super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    // Fetch and save the FCM token on widget initialization
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    try {
      await MessagingService.fetchAndSaveToken();
      debugPrint('FCM token updated successfully.');
    } catch (e) {
      debugPrint('Error fetching and saving FCM token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Home role: ${widget.role}");
    switch (widget.role) {
      case 'admin':
        return const AdminHome();
      case 'doctor':
        return const CaregiverHome();
      case 'caregiver':
        return const CaregiverHome();
      case 'nurse':
        return const CaregiverHome();
      default:
        return const Wrapper();
    }
  }
}
