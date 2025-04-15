// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/alert_handler.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/dropdownfield.dart';
import 'package:solace/themes/textstyle.dart';

enum LogFilter {
  thisHour,
  last3Hours,
  last6Hours,
  last12Hours,
  today,
  thisWeek,
  last2Weeks,
  thisMonth,
  last3Months,
  last6Months,
  thisYear,
  customDate,
}

enum SortOrder { ascending, descending }

class AdminLogs extends StatefulWidget {
  const AdminLogs({super.key, required this.currentUserId});
  final String currentUserId;

  @override
  AdminLogsState createState() => AdminLogsState();
}

class AdminLogsState extends State<AdminLogs> {
  DatabaseService databaseService = DatabaseService();
  String? name;
  late Future<List<Map<String, dynamic>>> _loginAttempts;
  late Future<List<Map<String, dynamic>>> _adminLogs;
  bool _isShowingLoginAttempts = false;
  LogFilter _selectedFilter = LogFilter.today;
  DateTime? _selectedDate;
  SortOrder _loginAttemptsSortOrder = SortOrder.descending;
  SortOrder _adminLogsSortOrder = SortOrder.descending;

  @override
  void initState() {
    super.initState();
    fetchName();
    _loginAttempts = fetchLoginAttempts();
    _adminLogs = fetchAdminLogs();
  }

  void _showLogDetails(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertHandler(title: title, messages: [message]),
    );
  }

  Future<List<Map<String, dynamic>>> fetchLoginAttempts() async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'login_attempts',
      );

      query = _applyFilterToQuery(query, 'lastAttempt');

      final snapshot =
          await query
              .orderBy(
                'lastAttempt',
                descending: _loginAttemptsSortOrder == SortOrder.descending,
              )
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
      //     debugPrint("Error fetching login attempts: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAdminLogs() async {
    try {
      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('logs')
          .doc(widget.currentUserId); // Fetching the specific user document

      DocumentSnapshot userDocSnapshot = await userDocRef.get();

      if (userDocSnapshot.exists && userDocSnapshot.data() != null) {
        final userData = userDocSnapshot.data() as Map<String, dynamic>;
        final logsArray = userData['logs'] as List<dynamic>?;

        if (logsArray != null) {
          // Convert each dynamic element in the array to a Map<String, dynamic>
          List<Map<String, dynamic>> logs =
              logsArray.whereType<Map<String, dynamic>>().toList();

          // Apply the filter to the logs array
          logs = _filterLogsArray(logs, 'timestamp');

          // Sort the logs array
          logs.sort((a, b) {
            final timestampA = a['timestamp'] as Timestamp?;
            final timestampB = b['timestamp'] as Timestamp?;
            if (timestampA == null && timestampB == null) return 0;
            if (timestampA == null) {
              return _adminLogsSortOrder == SortOrder.ascending ? -1 : 1;
            }
            if (timestampB == null) {
              return _adminLogsSortOrder == SortOrder.ascending ? 1 : -1;
            }
            final dateA = timestampA.toDate();
            final dateB = timestampB.toDate();
            return _adminLogsSortOrder == SortOrder.ascending
                ? dateA.compareTo(dateB)
                : dateB.compareTo(dateA);
          });

          return logs;
        } else {
          //     debugPrint("No 'logs' array found in the user document.");
          return [];
        }
      } else {
        //     debugPrint("User document does not exist.");
        return [];
      }
    } catch (e) {
      //     debugPrint("Error fetching admin logs: $e");
      return [];
    }
  }

  List<Map<String, dynamic>> _filterLogsArray(
    List<Map<String, dynamic>> logs,
    String timestampField,
  ) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime? endDate; // Add an end date

    switch (_selectedFilter) {
      case LogFilter.thisHour:
        startDate = now.subtract(const Duration(hours: 1));
        break;
      case LogFilter.last3Hours:
        startDate = now.subtract(const Duration(hours: 3));
        break;
      case LogFilter.last6Hours:
        startDate = now.subtract(const Duration(hours: 6));
        break;
      case LogFilter.last12Hours:
        startDate = now.subtract(const Duration(hours: 12));
        break;
      case LogFilter.today:
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        endDate = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
          999,
        ); // End of today
        break;
      case LogFilter.thisWeek:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          0,
          0,
          0,
          0,
        );
        endDate = startDate
            .add(const Duration(days: 7))
            .subtract(const Duration(milliseconds: 1)); // End of week
        break;
      case LogFilter.last2Weeks:
        startDate = now.subtract(Duration(days: now.weekday + 13));
        startDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          0,
          0,
          0,
          0,
        );
        endDate = startDate
            .add(const Duration(days: 14))
            .subtract(const Duration(milliseconds: 1)); // End of two weeks
        break;
      case LogFilter.thisMonth:
        startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
        endDate = DateTime(
          now.year,
          now.month + 1,
          0,
          23,
          59,
          59,
          999,
        ); // End of month
        break;
      case LogFilter.last3Months:
        startDate = DateTime(now.year, now.month - 3, 1, 0, 0, 0);
        endDate = DateTime(
          now.year,
          now.month,
          0,
          23,
          59,
          59,
          999,
        ); // End of the starting month
        break;
      case LogFilter.last6Months:
        startDate = DateTime(now.year, now.month - 6, 1, 0, 0, 0);
        endDate = DateTime(
          now.year,
          now.month,
          0,
          23,
          59,
          59,
          999,
        ); // End of the starting month
        break;
      case LogFilter.thisYear:
        startDate = DateTime(now.year, 1, 1, 0, 0, 0);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59, 999); // End of year
        break;
      case LogFilter.customDate:
        if (_selectedDate != null) {
          startDate = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            0,
            0,
            0,
          );
          endDate = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            23,
            59,
            59,
            999,
          ); // End of the selected date
        } else {
          return logs; // No date selected, return unfiltered
        }
        break;
    }

    return logs.where((log) {
      final timestamp = log[timestampField] as Timestamp?;
      if (timestamp != null) {
        final logDate = timestamp.toDate();
        return logDate.isAfter(startDate) &&
            (endDate == null ||
                logDate.isBefore(endDate.add(const Duration(milliseconds: 1))));
      }
      return false; // If timestamp is null, exclude the log
    }).toList();
  }

  Query<Map<String, dynamic>> _applyFilterToQuery(
    Query<Map<String, dynamic>> query,
    String timestampField,
  ) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedFilter) {
      case LogFilter.thisHour:
        startDate = now.subtract(const Duration(hours: 1));
        break;
      case LogFilter.last3Hours:
        startDate = now.subtract(const Duration(hours: 3));
        break;
      case LogFilter.last6Hours:
        startDate = now.subtract(const Duration(hours: 6));
        break;
      case LogFilter.last12Hours:
        startDate = now.subtract(const Duration(hours: 12));
        break;
      case LogFilter.today:
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        break;
      case LogFilter.thisWeek:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          0,
          0,
          0,
        );
        break;
      case LogFilter.last2Weeks:
        startDate = now.subtract(Duration(days: now.weekday + 13));
        startDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          0,
          0,
          0,
        );
        break;
      case LogFilter.thisMonth:
        startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
        break;
      case LogFilter.last3Months:
        startDate = DateTime(now.year, now.month - 3, 1, 0, 0, 0);
        break;
      case LogFilter.last6Months:
        startDate = DateTime(now.year, now.month - 6, 1, 0, 0, 0);
        break;
      case LogFilter.thisYear:
        startDate = DateTime(now.year, 1, 1, 0, 0, 0);
        break;
      case LogFilter.customDate:
        startDate = _selectedDate ?? now;
        break;
    }

    return query.where(timestampField, isGreaterThan: startDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.neon,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.neon),
            ),
            dialogTheme: DialogThemeData(backgroundColor: AppColors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedFilter = LogFilter.customDate;
        _loginAttempts = fetchLoginAttempts();
        _adminLogs = fetchAdminLogs();
      });
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
      //     debugPrint("Error fetching name: $e");
    }
  }

  Widget _buildChoices() {
    return Row(
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
                  _isShowingLoginAttempts ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: _isShowingLoginAttempts,
          onSelected: (selected) {
            setState(() {
              _isShowingLoginAttempts = selected;
              _selectedFilter = LogFilter.today; // Reset filter when switching
              _selectedDate = null;
              _loginAttempts = fetchLoginAttempts();
            });
          },
          side: const BorderSide(color: Colors.transparent),
          selectedColor: AppColors.neon,
          backgroundColor: AppColors.darkgray,
        ),
        const SizedBox(width: 10), // Space between chips
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
              _selectedFilter = LogFilter.today; // Reset filter when switching
              _selectedDate = null;
              _adminLogs = fetchAdminLogs();
            });
          },
          side: const BorderSide(color: Colors.transparent),
          selectedColor: AppColors.neon,
          backgroundColor: AppColors.darkgray,
        ),
      ],
    );
  }

  Widget _buildSelectDate() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedDate == null
                  ? 'No date selected'
                  : 'Results from ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}',
              style: Textstyle.body.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => _selectDate(context),
            style: Buttonstyle.buttonPurple,
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: AppColors.white),
                SizedBox(width: 5),
                Text('Select Date', style: Textstyle.smallButton),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginAttemptsSort() {
    return CustomDropdownField<SortOrder>(
      value: _loginAttemptsSortOrder,
      focusNode: FocusNode(),
      labelText: 'Sort by',
      items: SortOrder.values,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _loginAttemptsSortOrder = value;
            _loginAttempts =
                fetchLoginAttempts(); // Re-fetch data after sort change
          });
        }
      },
      displayItem:
          (order) => order == SortOrder.ascending ? 'Ascending' : 'Descending',
      enabled: true, // You can change this based on your use case
    );
  }

  Widget _buildLoginAttemptsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loginAttempts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("No login attempts available for this filter."),
          );
        }

        var attempts = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              attempts.map((attempt) {
                var lastAttempt =
                    (attempt['lastAttempt'] as Timestamp).toDate();
                var formattedDate = DateFormat(
                  'MMMM d, yyyy h:mm a',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attempt['documentId'] ?? 'Unknown User',
                        style: Textstyle.body.copyWith(
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Last attempt: $formattedDate",
                        style: Textstyle.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Attempts: ${attempt['attempts']}",
                        style: Textstyle.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (attempt['lockedUntil'] != null)
                        Text(
                          "Locked until: ${DateFormat('MMMM d,<ctrl3348> h:mm a').format((attempt['lockedUntil'] as Timestamp).toDate())}",
                          style: Textstyle.bodySmall,
                        ),
                    ],
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildFilterByDropdown() {
    return CustomDropdownField<LogFilter>(
      value: _selectedFilter,
      focusNode: FocusNode(),
      labelText: 'Filter by',
      items: LogFilter.values,
      onChanged: (value) {
        setState(() {
          _selectedFilter = value!;
          _selectedDate = null;
          if (_isShowingLoginAttempts) {
            _loginAttempts = fetchLoginAttempts();
          } else {
            _adminLogs = fetchAdminLogs();
          }
        });
      },
      displayItem: (filter) {
        switch (filter) {
          case LogFilter.thisHour:
            return 'This Hour';
          case LogFilter.last3Hours:
            return 'Last 3 Hours';
          case LogFilter.last6Hours:
            return 'Last 6 Hours';
          case LogFilter.last12Hours:
            return 'Last 12 Hours';
          case LogFilter.today:
            return 'Today';
          case LogFilter.thisWeek:
            return 'This Week';
          case LogFilter.last2Weeks:
            return 'Last 2 Weeks';
          case LogFilter.thisMonth:
            return 'This Month';
          case LogFilter.last3Months:
            return 'Last 3 Months';
          case LogFilter.last6Months:
            return 'Last 6 Months';
          case LogFilter.thisYear:
            return 'This Year';
          case LogFilter.customDate:
            return 'Custom Date';
        }
      },
      enabled: true,
    );
  }

  Widget _buildAdminLogsSort() {
    return CustomDropdownField<SortOrder>(
      value: _adminLogsSortOrder,
      focusNode: FocusNode(),
      labelText: 'Sort by',
      items: SortOrder.values,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _adminLogsSortOrder = value;
            _adminLogs = fetchAdminLogs(); // Re-fetch data after sort change
          });
        }
      },
      displayItem:
          (order) => order == SortOrder.ascending ? 'Ascending' : 'Descending',
      enabled: true, // You can change this based on your use case
    );
  }

  Widget _buildAdminLogsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _adminLogs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("No logs available for this filter."),
          );
        }

        var logs = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              logs.map((log) {
                var timestamp =
                    log['timestamp'] != null
                        ? (log['timestamp'] as Timestamp).toDate()
                        : DateTime.now();
                var formattedDate = DateFormat(
                  'MMMM d, yyyy h:mm a',
                ).format(timestamp);

                return GestureDetector(
                  onTap:
                      () => _showLogDetails(
                        'Log Details',
                        log['action'] ?? 'No details available',
                      ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
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
                          "On $formattedDate",
                          style: Textstyle.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // You can add more details from the log here if needed
                      ],
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Column(
      children: [SizedBox(height: 10), Divider(), SizedBox(height: 10)],
    );
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
            _buildChoices(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildFilterByDropdown()),
                const SizedBox(width: 10),
                if (_isShowingLoginAttempts)
                  Expanded(child: _buildLoginAttemptsSort()),
                if (!_isShowingLoginAttempts)
                  Expanded(child: _buildAdminLogsSort()),
              ],
            ),
            if (_selectedFilter == LogFilter.customDate) _buildSelectDate(),
            _buildDivider(),
            Expanded(
              child: SingleChildScrollView(
                child:
                    _isShowingLoginAttempts
                        ? _buildLoginAttemptsList()
                        : _buildAdminLogsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
