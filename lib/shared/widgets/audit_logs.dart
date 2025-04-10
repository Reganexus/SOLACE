// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
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

class AuditLogs extends StatefulWidget {
  final String uid;

  const AuditLogs({super.key, required this.uid});

  @override
  AuditLogsState createState() => AuditLogsState();
}

class AuditLogsState extends State<AuditLogs> {
  final LogService _logService = LogService();
  DatabaseService databaseService = DatabaseService();
  SortOrder _userLogsSortValue = SortOrder.descending; // Default sort order

  String? name = '';
  LogFilter _selectedFilter = LogFilter.today; // Default filter

  @override
  void initState() {
    super.initState();
    fetchName();
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

  // Function to fetch and sort logs based on SortOrder
  List<Map<String, dynamic>> _sortLogs(List<Map<String, dynamic>> logs) {
    // Sort the logs by timestamp (descending by default)
    logs.sort((a, b) {
      DateTime timestampA = (a['timestamp'] as Timestamp).toDate();
      DateTime timestampB = (b['timestamp'] as Timestamp).toDate();
      return _userLogsSortValue == SortOrder.ascending
          ? timestampA.compareTo(timestampB)
          : timestampB.compareTo(timestampA);
    });
    return logs;
  }

  // StreamBuilder with Local Filtering and Sorting
  Widget _buildAuditLogs() {
    return StreamBuilder<List<Map<String, dynamic>>>(
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
        var filteredLogs = _filterLogs(logs);
        var sortedLogs = _sortLogs(filteredLogs);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              sortedLogs.map((log) {
                var timestamp = (log['timestamp'] as Timestamp).toDate();
                var formattedDate = DateFormat(
                  'MMMM d, yyyy h:mm a',
                ).format(timestamp);

                return SizedBox(
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
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Date: $formattedDate",
                          style: Textstyle.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  // Sort Order Dropdown Widget
  Widget _buildLogsSort() {
    return CustomDropdownField<SortOrder>(
      value: _userLogsSortValue,
      focusNode: FocusNode(),
      labelText: 'Sort by',
      items: SortOrder.values,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _userLogsSortValue = value;
          });
        }
      },
      displayItem:
          (order) => order == SortOrder.ascending ? 'Ascending' : 'Descending',
      enabled: true, // You can change this based on your use case
    );
  }

  // Filter Dropdown Widget
  Widget _buildFilterByDropdown() {
    return CustomDropdownField<LogFilter>(
      value: _selectedFilter,
      focusNode: FocusNode(),
      labelText: 'Filter by',
      items: LogFilter.values,
      onChanged: (value) {
        setState(() {
          _selectedFilter = value!;
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

  // Add this at the class level
  DateTime? _selectedDate; // Add this to store the selected date

  // Update _filterLogs function to include the selected date logic
  List<Map<String, dynamic>> _filterLogs(List<Map<String, dynamic>> logs) {
    DateTime now = DateTime.now();

    switch (_selectedFilter) {
      case LogFilter.thisHour:
        return logs.where((log) {
          DateTime timestamp = (log['timestamp'] as Timestamp).toDate();
          return timestamp.isAfter(now.subtract(Duration(hours: 1)));
        }).toList();

      case LogFilter.today:
        return logs.where((log) {
          DateTime timestamp = (log['timestamp'] as Timestamp).toDate();
          return timestamp.day == now.day &&
              timestamp.year == now.year &&
              timestamp.month == now.month;
        }).toList();

      case LogFilter.customDate:
        return logs.where((log) {
          DateTime timestamp = (log['timestamp'] as Timestamp).toDate();
          return _isSameDay(timestamp, _selectedDate);
        }).toList();

      // Add other filters here based on the selected filter
      default:
        return logs;
    }
  }

  // Function to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime? date2) {
    if (date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Add _buildSelectDate and _selectDate methods
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
        _selectedFilter =
            LogFilter
                .customDate; // Set filter to custom date when a date is selected
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$name Logs', style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        centerTitle: true,
      ),
      backgroundColor: AppColors.white,
      body: Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildFilterByDropdown()),
                const SizedBox(width: 10),
                Expanded(child: _buildLogsSort()),
              ],
            ),
            if (_selectedFilter == LogFilter.customDate) _buildSelectDate(),
            const SizedBox(height: 20),
            Expanded(child: SingleChildScrollView(child: _buildAuditLogs())),
          ],
        ),
      ),
    );
  }
}
