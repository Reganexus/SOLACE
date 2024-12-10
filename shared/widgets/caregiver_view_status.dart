import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart'; // Assuming AppColors is defined here

class CaregiverViewStatus extends StatelessWidget {
  final String username;

  const CaregiverViewStatus({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    // Sample tasks list (10 tasks total)
    List<Map<String, String>> tasks = [
      {'task': 'Take Medications', 'status': 'Pending'},
      {'task': 'Schedule Check-up', 'status': 'Completed'},
      {'task': 'Do Today\'s Assessment', 'status': 'Pending'},
      {'task': 'Monitor Vital Signs', 'status': 'Pending'},
      {'task': 'Prepare Meal Plan', 'status': 'Completed'},
      {'task': 'Assist with Bathing', 'status': 'Pending'},
      {'task': 'Record Daily Activities', 'status': 'Pending'},
      {'task': 'Communicate with Family', 'status': 'Completed'},
      {'task': 'Check Blood Sugar Levels', 'status': 'Pending'},
      {'task': 'Plan Physical Activities', 'status': 'Pending'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        title: Text(username,
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            )),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(30),
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
                        bottomRight: Radius.circular(10.0),
                      ),
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
            const SizedBox(height: 20.0),

            // History Section
            const Text(
              'History',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 10.0),

            // Scrollable History Graphs (Placeholder)
            SizedBox(
              height: 100,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(5, (index) {
                    return Container(
                      width: 150, // Width of each graph container
                      margin: const EdgeInsets.only(
                          right: 10.0), // Gap between graphs
                      decoration: BoxDecoration(
                        color: AppColors.gray, // Placeholder color for graph
                        borderRadius:
                        BorderRadius.circular(10.0), // Added border radius
                      ),
                      child: Center(
                        child: Text('Graph ${index + 1}'), // Placeholder text
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20.0),

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

            // Scrollable Task List
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Container(
                    margin: const EdgeInsets.only(
                        bottom: 10.0), // Gap between tasks
                    decoration: BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      title: Text(task['task']!),
                      subtitle: Text(task['status']!),
                      trailing: Icon(
                        task['status'] == 'Completed'
                            ? Icons.check_circle
                            : Icons.pending,
                        color: task['status'] == 'Completed'
                            ? Colors.green
                            : Colors.orange,
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
