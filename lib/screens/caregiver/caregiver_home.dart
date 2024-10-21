// ignore_for_file: avoid_print

import 'package:accordion/controllers.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:solace/themes/colors.dart';
import 'package:accordion/accordion.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  CaregiverHomeScreenState createState() => CaregiverHomeScreenState();
}

class CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  final ValueNotifier<int?> _openSectionIndex = ValueNotifier<int?>(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _openSectionIndex.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleOpenSection(int index) {
    _openSectionIndex.value = index;

    // Calculate the position to scroll based on the index
    _scrollToSection(index);
  }

  void _handleCloseSection() {
    _openSectionIndex.value = null;
  }

  // Function to scroll to the center of the screen
  void _scrollToSection(int index) {
    // Approximate height of each section (modify as per actual heights)
    double sectionHeight =
        100.0; // Adjust this according to your section height
    double headerHeight = 80.0; // Approximate height of the header section

    // Calculate the offset
    double targetOffset = headerHeight + (index * sectionHeight);

    // Scroll the section into view (with some padding to center it)
    _scrollController.animateTo(
      targetOffset - (MediaQuery.of(context).size.height / 3),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  static const headerStyle = TextStyle(
    color: Colors.black,
    fontSize: 16,
    fontFamily: 'Inter',
    fontWeight: FontWeight.bold,
  );

  static const contentStyle = TextStyle(
    color: Colors.black,
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  // Sample patients data for accordion
  final List<Map<String, dynamic>> patients = [
    {
      'name': 'Patient 1',
      'profilePic': 'lib/assets/images/shared/placeholder.png',
      'conditions': ['High blood pressure', 'Diabetes', 'Arthritis']
    },
    {
      'name': 'Patient 2',
      'profilePic': 'lib/assets/images/shared/placeholder.png',
      'conditions': ['Asthma', 'Allergies', 'Back pain']
    },
    {
      'name': 'Patient 3',
      'profilePic': 'lib/assets/images/shared/placeholder.png',
      'conditions': ['Heart disease', 'Migraines', 'Vision loss']
    },
    {
      'name': 'Patient 4',
      'profilePic': 'lib/assets/images/shared/placeholder.png',
      'conditions': ['High blood pressure', 'Diabetes', 'Arthritis']
    },
    {
      'name': 'Patient 5',
      'profilePic': 'lib/assets/images/shared/placeholder.png',
      'conditions': ['Asthma', 'Allergies', 'Back pain']
    },
    {
      'name': 'Patient 6',
      'profilePic': 'lib/assets/images/shared/placeholder.png',
      'conditions': ['Heart disease', 'Migraines', 'Vision loss']
    },
    {
      'name': 'Patient 7',
      'profilePic': 'lib/assets/images/shared/placeholder.png',
      'conditions': ['High blood pressure', 'Diabetes', 'Arthritis']
    },
    {
      'name': 'Patient 8',
      'profilePic': 'lib/assets/images/shared/placeholder.png',
      'conditions': ['Asthma', 'Allergies', 'Back pain']
    },
    {
      'name': 'Patient 9',
      'profilePic': 'lib/assets/images/shared/placeholder.png',
      'conditions': ['Heart disease', 'Migraines', 'Vision loss']
    },
    {
      'name': 'Patient 10',
      'profilePic': 'lib/assets/images/shared/placeholder.png',
      'conditions': ['High blood pressure', 'Diabetes', 'Arthritis']
    },
    {
      'name': 'Patient 11',
      'profilePic': 'lib/assets/images/shared/placeholder.png',
      'conditions': ['Asthma', 'Allergies', 'Back pain']
    },
    {
      'name': 'Patient 12',
      'profilePic': 'lib/assets/images/shared/placeholder.png',
      'conditions': ['Heart disease', 'Migraines', 'Vision loss']
    },
  ];

  // Function to launch a phone call
  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  // Function to send a message
  Future<void> _sendMessage(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': 'Hello! How can I assist you?'},
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  // Function to schedule an appointment (placeholder)
  void _scheduleAppointment() {
    // Implement scheduling functionality
    print('Scheduling appointment...');
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notifications'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Notification 1: System update available.'),
                Text('Notification 2: New message received.'),
                Text('Notification 3: Your profile has been updated.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close modal
              },
            ),
          ],
        );
      },
    );
  }

  // Messages modal
  void _showMessages(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Messages'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Message 1: Welcome to Solace!'),
                Text('Message 2: Don’t forget to update your profile.'),
                Text('Message 3: Your password has been changed.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close modal
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 20.0,
                      backgroundImage: AssetImage(
                          'lib/assets/images/shared/placeholder.png'),
                    ),
                    SizedBox(width: 10.0),
                    Text(
                      'Hello, Caregiver',
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
                      'lib/assets/images/shared/header/message.png',
                      () => _showMessages(context), // Show messages modal
                    ),
                    const SizedBox(width: 10.0),
                    _buildIconButton(
                      'lib/assets/images/shared/header/notification.png',
                      () => _showNotifications(
                          context), // Show notifications modal
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30.0),

            // Priority Patients section
            const Text(
              'Priority Patients',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 20.0),

            // Accordion section
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController, // Attach scroll controller
                child: Accordion(
                  scrollIntoViewOfItems: ScrollIntoViewOfItems.fast,
                  scaleWhenAnimating: false,
                  paddingListHorizontal: 0.0,
                  paddingListTop: 0.0,
                  paddingListBottom: 0.0,
                  maxOpenSections: 1,
                  headerBackgroundColor: AppColors.gray,
                  headerBackgroundColorOpened: AppColors.neon,
                  contentBackgroundColor: AppColors.gray,
                  contentBorderColor: AppColors.gray,
                  contentHorizontalPadding: 20,
                  contentVerticalPadding: 10,
                  headerPadding:
                      const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
                  children: patients.asMap().entries.map((entry) {
                    int index = entry.key;
                    var patient = entry.value;
                    return AccordionSection(
                      onOpenSection: () =>
                          _handleOpenSection(index), // Handle opening section
                      onCloseSection:
                          _handleCloseSection, // Handle closing section
                      headerBackgroundColor: AppColors.gray,
                      headerBackgroundColorOpened: AppColors.neon,
                      contentBackgroundColor: AppColors.gray,
                      contentBorderColor: AppColors.gray,
                      contentHorizontalPadding: 20,
                      contentVerticalPadding: 10,
                      headerPadding: const EdgeInsets.symmetric(
                          vertical: 7, horizontal: 15),
                      leftIcon: CircleAvatar(
                        backgroundImage: AssetImage(patient['profilePic']),
                        radius: 16.0,
                      ),
                      rightIcon: ValueListenableBuilder<int?>(
                        valueListenable: _openSectionIndex,
                        builder: (context, value, child) {
                          return Icon(
                            Icons.keyboard_arrow_down,
                            color: value == index
                                ? AppColors.white
                                : AppColors
                                    .black, // Change color based on state
                            size: 20,
                          );
                        },
                      ),
                      isOpen: _openSectionIndex.value == index,
                      header: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: ValueListenableBuilder<int?>(
                          valueListenable: _openSectionIndex,
                          builder: (context, value, child) {
                            return Text(
                              patient['name'],
                              style: headerStyle.copyWith(
                                color: value == index
                                    ? AppColors.white
                                    : AppColors.black,
                                fontFamily: 'Inter',
                                fontSize: 14.0,
                              ),
                            );
                          },
                        ),
                      ),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Identified Conditions',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          ...patient['conditions'].map((condition) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(fontSize: 16)), // Bullet
                                Expanded(
                                    child:
                                        Text(condition, style: contentStyle)),
                              ],
                            );
                          }).toList(),
                          const SizedBox(height: 20.0), // Space before buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildActionButton(
                                'Schedule',
                                'lib/assets/images/shared/functions/schedule.png',
                                AppColors.darkblue,
                                () => _scheduleAppointment(),
                              ),
                              _buildActionButton(
                                'Message',
                                'lib/assets/images/shared/functions/message.png',
                                AppColors.blue,
                                () => _sendMessage(
                                    '1234567890'), // Placeholder number
                              ),
                              _buildActionButton(
                                'Call',
                                'lib/assets/images/shared/functions/call.png',
                                AppColors.red,
                                () => _makeCall(
                                    '1234567890'), // Placeholder number
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, String iconPath, Color bgColor, VoidCallback onPressed) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Row(
          children: [
            Image.asset(iconPath, height: 20, width: 20), // Icon
            const SizedBox(width: 5), // Space between icon and text
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(String imagePath, VoidCallback onPressed) {
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
        onPressed: onPressed,
      ),
    );
  }
}
