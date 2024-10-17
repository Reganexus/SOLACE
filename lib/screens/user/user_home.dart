import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart'; // Assuming AppColors is defined here

class UserHomeScreen extends StatelessWidget {
  final VoidCallback navigateToHistory;

  UserHomeScreen({Key? key, required this.navigateToHistory}) : super(key: key);

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
  ];

  Widget _buildIconButton(String imagePath) {
    return Container(
      padding: const EdgeInsets.all(2.0),
      decoration: const BoxDecoration(
        color: AppColors.gray,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Image.asset(
          imagePath,
          height: 20,
        ),
        onPressed: () {
          // Handle button press
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(30, 60, 30, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 20.0,
                      backgroundImage: AssetImage(
                        'lib/assets/images/shared/placeholder.png',
                      ),
                    ),
                    SizedBox(width: 10.0),
                    Text(
                      'Hello, User!',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildIconButton(
                        'lib/assets/images/shared/header/message.png'),
                    const SizedBox(width: 10.0),
                    _buildIconButton(
                        'lib/assets/images/shared/header/notification.png'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30.0),

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
                  navigateToHistory();
                },
                child: const Text(
                  'See more about your status',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    fontSize: 12.0,
                    color: AppColors.black,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30.0),

            // Placeholder for Schedule group and Tasks group content
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
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
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
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        child: const Text(
                          '15',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      const Text(
                        'October',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Appointment',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30.0),

            // Tasks
            const Text(
              'Tasks',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 10.0),

            // Horizontal List of Tasks
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _showTaskModal(context, tasks[index]['title']!);
                    },
                    child: Card(
                      margin: const EdgeInsets.only(right: 15.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20.0, horizontal: 15.0),
                        width: screenWidth * 0.7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: AppColors.purple,
                        ),
                        child: Stack(
                          // Using Stack to position the icon
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  // Background for title
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    tasks[index]['title']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Outfit',
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              right: 3, // Positioning from the right
                              top: 3, // Positioning from the top
                              child: Container(
                                padding: const EdgeInsets.all(5.0),
                                decoration: BoxDecoration(
                                  color: AppColors
                                      .blackTransparent, // Icon background color
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  tasks[index]['icon']!,
                                  height: 25, // Icon height
                                ),
                              ),
                            ),
                          ],
                        ),
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
}
