import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';

class PatientDashboard extends StatelessWidget {
  final VoidCallback navigateToHistory;

  PatientDashboard({super.key, required this.navigateToHistory});

  // Function to show modal
  void _showTaskModal(BuildContext context, String task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(task),
          content: Text('Details about $task.'),
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

  // Sample task data
  final List<Map<String, String>> tasks = [
    {
      'title': 'Take Medication',
      'icon': 'lib/assets/images/shared/vitals/heart_rate.png'
    },
    {
      'title': 'Check Blood Pressure',
      'icon': 'lib/assets/images/shared/vitals/blood_pressure.png'
    },
    {
      'title': 'Schedule Appointment',
      'icon': 'lib/assets/images/shared/vitals/temperature.png'
    },
    {
      'title': 'Get Weight',
      'icon': 'lib/assets/images/shared/vitals/weight.png'
    },
    {
      'title': 'Check Temperature',
      'icon': 'lib/assets/images/shared/vitals/temperature.png'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wrap this section in a SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Group Title
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 10.0),

                    // Status Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.neon,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 30.0, horizontal: 15.0),
                            color: Colors.transparent,
                            child: const Text(
                              'Good',
                              style: TextStyle(
                                fontSize: 50.0,
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: const BoxDecoration(
                              color: AppColors.blackTransparent,
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(10.0),
                                  bottomRight: Radius.circular(10.0)),
                            ),
                            child: const Text(
                              'ⓘ No symptoms detected. Keep up the good work!',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10.0),

                    // Clickable Link to History
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          // Call the method passed from UserHome to navigate to History
                          navigateToHistory();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: const Text(
                            'See more about your status',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.normal,
                              fontSize: 16.0,
                              color: AppColors.black,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),

                    // Schedule Section
                    const Text(
                      'Schedule',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 10.0),

                    // Schedule Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 15.0),
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
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black),
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                padding: const EdgeInsets.all(5.0),
                                child: const Center(
                                  child: Text(
                                    '15',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              const Text(
                                'October',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Appointment',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30.0),

                    // Tasks Section
                    const Text(
                      'Tasks',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 10.0),

                    // Vertical List of Tasks
                    ListView.builder(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      itemCount: tasks.length,
                      shrinkWrap: true, // Allows ListView to be inside a SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for the ListView
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _showTaskModal(context, tasks[index]['title']!);
                          },
                          child: Card(
                            margin: const EdgeInsets.only(
                                bottom: 15.0), // Add bottom margin for gaps
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20.0, horizontal: 15.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: AppColors.purple,
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    tasks[index]['icon']!,
                                    height:
                                    30, // Adjust icon height as needed
                                  ),
                                  const SizedBox(
                                      width:
                                      10.0), // Add gap between icon and text
                                  Text(
                                    tasks[index]['title']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Outfit',
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
