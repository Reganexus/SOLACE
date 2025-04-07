// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/alert_handler.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class AuditLogs extends StatefulWidget {
  final String uid;

  const AuditLogs({super.key, required this.uid});

  @override
  AuditLogsState createState() => AuditLogsState();
}

class AuditLogsState extends State<AuditLogs> {
  final LogService _logService = LogService();
  DatabaseService databaseService = DatabaseService();

  String? name = '';

  @override
  void initState() {
    super.initState();
    fetchName();
  }

  void _showLogDetails(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertHandler(title: title, messages: [message]),
    );
  }

  Future<void> fetchName() async {
    try {
      final doc = await databaseService.fetchUserData(widget.uid);
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
      appBar: AppBar(
        title: Text('$name Logs', style: Textstyle.subheader),
        backgroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.white,
      body: Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _logService.getLogsForUser(widget.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No logs available."));
            }

            var logs = snapshot.data!;

            return ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                var log = logs[index];
                var timestamp =
                    log['timestamp'] != null
                        ? (log['timestamp'] as Timestamp).toDate()
                        : DateTime.now();
                var formattedDate = DateFormat(
                  'yyyy-MM-dd HH:mm:ss',
                ).format(timestamp);

                return GestureDetector(
                  onTap:
                      () => _showLogDetails(
                        'Log Details',
                        log['action'] ?? 'No details available',
                      ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.history,
                            color: AppColors.neon,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log['action'] ?? 'Unknown Action',
                                style: Textstyle.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxLines: 1,
                              ),
                              Text(
                                "On: $formattedDate",
                                style: Textstyle.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          },
        ),
      ),
    );
  }
}
