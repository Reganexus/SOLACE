import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/log_service.dart';

class AuditLogs extends StatefulWidget {
  final String uid;

  const AuditLogs({super.key, required this.uid});

  @override
  AuditLogsState createState() => AuditLogsState();
}

class AuditLogsState extends State<AuditLogs> {
  final LogService _logService = LogService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
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

          // Extract log data
          var logs = snapshot.data!;

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              var log = logs[index];
              var timestamp = log['timestamp'] != null
                  ? (log['timestamp'] as Timestamp).toDate()
                  : DateTime.now();
              var formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.history, color: Colors.blue),
                  title: Text(log['action'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("On: $formattedDate"),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
