// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/alert_handler.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class AdminLogs extends StatefulWidget {
  const AdminLogs({super.key, required this.currentUserId});
  final String currentUserId;

  @override
  AdminLogsState createState() => AdminLogsState();
}

class AdminLogsState extends State<AdminLogs> {
  final LogService _logService = LogService();
  DatabaseService databaseService = DatabaseService();
  String? name;
  late Future<List<Map<String, dynamic>>> _loginAttempts;
  bool _isShowingLoginAttempts = false; // To track which data to show

  @override
  void initState() {
    super.initState();
    fetchName();
    _loginAttempts = fetchLoginAttempts();
  }

  void _showLogDetails(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertHandler(title: title, messages: [message]),
    );
  }

  Future<List<Map<String, dynamic>>> fetchLoginAttempts() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('login_attempts')
              .orderBy('lastAttempt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        return {
          'documentId': doc.id,
          'lastAttempt': doc['lastAttempt'] ?? Timestamp.now(),
          'attempts': doc['attempts'] ?? 0,
          'lockedUntil': doc['lockedUntil'],
        };
      }).toList();
    } catch (e) {
      print("Error fetching login attempts: $e");
      return [];
    }
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ChoiceChip(
                  checkmarkColor: AppColors.white,
                  label: Text(
                    'Login Attempts',
                    style: Textstyle.bodySmall.copyWith(
                      color:
                          _isShowingLoginAttempts
                              ? AppColors.white
                              : AppColors.whiteTransparent,
                      fontWeight:
                          _isShowingLoginAttempts
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                  selected: _isShowingLoginAttempts,
                  onSelected: (selected) {
                    setState(() {
                      _isShowingLoginAttempts = selected;
                    });
                  },
                  side: BorderSide(color: Colors.transparent),
                  selectedColor: AppColors.neon,
                  backgroundColor: AppColors.darkgray,
                ),
                SizedBox(width: 16), // Space between chips
                ChoiceChip(
                  checkmarkColor: AppColors.white,
                  label: Text(
                    'Admin Logs',
                    style: Textstyle.bodySmall.copyWith(
                      color:
                          !_isShowingLoginAttempts
                              ? AppColors.white
                              : AppColors.whiteTransparent,
                      fontWeight:
                          !_isShowingLoginAttempts
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                  selected: !_isShowingLoginAttempts,
                  onSelected: (selected) {
                    setState(() {
                      _isShowingLoginAttempts = !selected;
                    });
                  },
                  side: BorderSide(color: Colors.transparent),
                  selectedColor: AppColors.neon,
                  backgroundColor: AppColors.darkgray,
                ),
              ],
            ),
            SizedBox(height: 10),
            Flexible(
              child:
                  _isShowingLoginAttempts
                      ? FutureBuilder<List<Map<String, dynamic>>>(
                        future: _loginAttempts,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text("Error: ${snapshot.error}"),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text("No login attempts available."),
                            );
                          }

                          var attempts = snapshot.data!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                attempts.map((attempt) {
                                  var lastAttempt =
                                      (attempt['lastAttempt'] as Timestamp)
                                          .toDate();
                                  var formattedDate = DateFormat(
                                    'MMMM d, yyyy',
                                  ).format(lastAttempt);

                                  return Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.gray,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          attempt['documentId'] ??
                                              'Unknown User',
                                          style: Textstyle.body.copyWith(
                                            fontWeight: FontWeight.bold,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Last attempt: $formattedDate",
                                          style: Textstyle.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "Attempts: ${attempt['attempts']}",
                                          style: Textstyle.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        if (attempt['lockedUntil'] != null)
                                          Text(
                                            "Locked until: ${DateFormat('MMMM d, yyyy').format((attempt['lockedUntil'] as Timestamp).toDate())}",
                                            style: Textstyle.bodySmall,
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          );
                        },
                      )
                      : StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _logService.getLogsForUser(
                          widget.currentUserId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text("Error: ${snapshot.error}"),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text("No logs available."),
                            );
                          }

                          var logs = snapshot.data!;

                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              var log = logs[index];
                              var timestamp =
                                  log['timestamp'] != null
                                      ? (log['timestamp'] as Timestamp).toDate()
                                      : DateTime.now();
                              var formattedDate = DateFormat(
                                'MMMM d, yyyy',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              "On $formattedDate",
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
          ],
        ),
      ),
    );
  }
}
