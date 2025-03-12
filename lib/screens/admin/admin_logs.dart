import 'package:flutter/material.dart';
import 'package:solace/shared/widgets/audit_logs.dart';
import 'package:solace/themes/colors.dart';

class AdminLogs extends StatefulWidget {
  const AdminLogs({super.key, required this.currentUserId, required this.userName});
  final String currentUserId;
  final String userName;

  @override
  AdminLogsState createState() => AdminLogsState();
}

class AdminLogsState extends State<AdminLogs> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text("${widget.userName} Logs"),
      ),
      body: AuditLogs(uid: widget.currentUserId), // Pass correct uid here
    );
  }
}