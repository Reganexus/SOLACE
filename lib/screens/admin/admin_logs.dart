// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/audit_logs.dart';
import 'package:solace/themes/colors.dart';

class AdminLogs extends StatefulWidget {
  const AdminLogs({super.key, required this.currentUserId});
  final String currentUserId;

  @override
  AdminLogsState createState() => AdminLogsState();
}

class AdminLogsState extends State<AdminLogs> {
  DatabaseService databaseService = DatabaseService();
  String? name;

  @override
  void initState() {
    super.initState();
    fetchName();
  }

  Future<void> fetchName() async {
    try {
      final doc = await databaseService.fetchUserData(widget.currentUserId);
      if (doc == null) return;

      // Safely cast data() to Map<String, dynamic>
      final data = doc.toMap() as Map<String, dynamic>?;

      // Retrieve only firstName and lastName
      final firstName = data?['firstName'] ?? '';
      final lastName = data?['lastName'] ?? '';

      // Construct the full name
      final fetchedName =
          [
            firstName,
            lastName,
          ].where((name) => name.isNotEmpty).join(' ').trim();

      // Update state with the fetched name
      setState(() {
        name = fetchedName;
      });
    } catch (e) {
      print("Error fetching name: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Container(
        color: AppColors.white,
        child: AuditLogs(uid: widget.currentUserId),
      ),
    );
  }
}
