import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // Import the package
import 'package:solace/themes/colors.dart';

class CaregiverTrackingScreen extends StatefulWidget {
  const CaregiverTrackingScreen({super.key});

  @override
  CaregiverTrackingScreenState createState() => CaregiverTrackingScreenState();
}

class CaregiverTrackingScreenState extends State<CaregiverTrackingScreen> {
  // Sample upcoming schedules
  List<Map<String, String>> upcomingSchedules = [
    {
      'date': '15',
      'month': 'October',
      'type': 'Appointment',
      'client': 'Patient A'
    },
    {
      'date': '20',
      'month': 'October',
      'type': 'Assessment',
      'client': 'Patient B'
    },
    {
      'date': '25',
      'month': 'November',
      'type': 'Follow-up',
      'client': 'Patient C'
    },
    {
      'date': '5',
      'month': 'November',
      'type': 'Appointment',
      'client': 'Patient D'
    },
    {
      'date': '10',
      'month': 'November',
      'type': 'Check-up',
      'client': 'Patient E'
    },
    {
      'date': '26',
      'month': 'November',
      'type': 'Appointment',
      'client': 'Patient F'
    },
    {
      'date': '30',
      'month': 'November',
      'type': 'Check-up',
      'client': 'Patient G'
    },
    // Add more schedules as needed
  ];

  DateTime selectedDay = DateTime.now(); // Selected day for the calendar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tracking',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 10.0,),
            // Calendar Widget
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: selectedDay,
              selectedDayPredicate: (day) {
                return isSameDay(selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  this.selectedDay = selectedDay;
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppColors.neon,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.orange[300],
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible:
                    false, // Hide format button to prevent the error
                titleCentered: true,
                leftChevronIcon: Icon(Icons.arrow_back),
                rightChevronIcon: Icon(Icons.arrow_forward),
              ),
            ),
            const SizedBox(height: 20.0),

            // Upcoming Schedules
            const Text(
              'Upcoming Schedules',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 20.0),

            // Scrollable Upcoming Schedules List
            Expanded(
              child: ListView.builder(
                itemCount: upcomingSchedules.length,
                itemBuilder: (context, index) {
                  final schedule = upcomingSchedules[index];
                  return GestureDetector(
                    onTap: () {
                      _showAppointmentDetails(context, schedule);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 15.0),
                      margin: const EdgeInsets.only(bottom: 10.0),
                      decoration: BoxDecoration(
                        color: AppColors.gray,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black),
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                padding: const EdgeInsets.all(5.0),
                                child: Center(
                                  child: Text(
                                    schedule['date']!,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              Text(
                                schedule['month']!,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10.0),
                          Text(
                            schedule['type']!,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to show the appointment details modal
  void _showAppointmentDetails(
      BuildContext context, Map<String, String> schedule) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Appointment Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${schedule['date']} ${schedule['month']}'),
              Text('Type: ${schedule['type']}'),
              Text('Client: ${schedule['client']}'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the modal
              },
            ),
          ],
        );
      },
    );
  }
}
