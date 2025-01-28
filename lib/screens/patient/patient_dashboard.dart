import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/patient/patient_history.dart';
import 'package:solace/screens/patient/patient_info.dart';
import 'package:solace/screens/patient/patient_intervention.dart';
import 'package:solace/screens/patient/patient_note.dart';
import 'package:solace/screens/patient/patient_tasks.dart';
import 'package:solace/screens/patient/patient_schedule.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/contacts.dart';
import 'package:solace/shared/widgets/medicine.dart';
import 'package:solace/themes/colors.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  PatientDashboardState createState() => PatientDashboardState();
}

class PatientDashboardState extends State<PatientDashboard> {
  final List<Map<String, dynamic>> gridItems = [
    {'label': 'Contacts', 'icon': Icons.contact_page_rounded},
    {'label': 'History', 'icon': Icons.history},
    {'label': 'Intervention', 'icon': Icons.healing},
    {'label': 'Medicine', 'icon': Icons.medical_services_rounded},
    {'label': 'Notes', 'icon': Icons.create_rounded},
    {'label': 'Schedule', 'icon': Icons.calendar_today},
    {'label': 'Tasks', 'icon': Icons.task},
    {'label': 'Patient', 'icon': Icons.person},
  ];

  // Define the routes map with the assumption all routes accept the currentUserId
  Map<String, Widget Function(String)> routes = {
    'Contacts': (userId) => Contacts(currentUserId: userId),
    'History': (userId) => PatientHistory(currentUserId: userId),
    'Intervention': (userId) => PatientIntervention(currentUserId: userId),
    'Medicine': (userId) => Medicine(currentUserId: userId),
    'Notes': (userId) => PatientNote(currentUserId: userId),
    'Schedule': (userId) => PatientSchedule(currentUserId: userId),
    'Tasks': (userId) => PatientTasks(currentUserId: userId),
    'Patient': (userId) => PatientInfo(currentUserId: userId),
  };
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
        child: StreamBuilder<UserData?>(
          stream: DatabaseService(uid: user?.uid).userData,
          builder: (context, snapshot) {
            // Default values for status card
            String status = 'stable';
            String statusMessage =
                'ⓘ No symptoms detected. Keep up the good work!';
            Color backgroundColor = AppColors.neon;

            if (snapshot.hasData) {
              final userData = snapshot.data!;
              status = userData.status;

              if (status == 'unstable') {
                statusMessage =
                '⚠️ Symptoms detected. Please consult your doctor.';
                backgroundColor = AppColors.red;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Section
                const Text(
                  'Patient Status',
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
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 30.0, horizontal: 15.0),
                        color: Colors.transparent,
                        child: Text(
                          status == 'stable' ? 'Stable' : 'Unstable',
                          style: const TextStyle(
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
                        child: Text(
                          statusMessage,
                          style: const TextStyle(
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
                const SizedBox(height: 30.0),

                // Grid Layout
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gridItems.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // Always 4 columns
                      mainAxisSpacing: 15, // Vertical spacing
                      crossAxisSpacing: 15, // Horizontal spacing
                      childAspectRatio: 0.7, // Adjusted ratio to make sure the height is taller than the width
                    ),
                    itemBuilder: (context, index) {
                      final item = gridItems[index];

                      return GestureDetector(
                        onTap: () {
                          final String userId =
                              user?.uid ?? ''; // Get user ID (fallback to an empty string if null)

                          // Pass the userId dynamically to all routes
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  routes[item['label']!]!(userId),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Makes sure the column takes minimal space
                          children: [
                            Container(
                              height: 70, // Adjusted height for the entire item (container + label)
                              width: 70, // Width remains the same
                              decoration: BoxDecoration(
                                color: AppColors.gray,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item['icon'], // Use Material Icon
                                size: 28,
                                color: AppColors.darkgray,
                              ),
                            ),
                            const SizedBox(height: 8), // Space between container and label
                            Text(
                              item['label']!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Inter',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

}
