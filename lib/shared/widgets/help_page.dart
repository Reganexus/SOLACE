import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  HelpPageState createState() => HelpPageState();
}

class HelpPageState extends State<HelpPage> {
  List<bool> expandedState = [];

  final List<String> items = [
    'A referral system for patients, by patients, their friends/relatives, or their physician/health care provider.',
    'A directory for those looking for Palliative Care Institutions or home care supply providers.',
    'An updated resource base for key information through scheduled teleconsults that can guide physicians in their palliative approach to patient care through palliative care consults with fellow physicians who have trained and have significant experience in the practice of palliative medicine, pain management, public health, and counseling.',
    'A source of inspiration, as we all work together towards creating more compassionate communities.',
  ];

  final List<Map<String, String>> faqData = [
    {
      'question': 'What is SOLACE?',
      'answer':
          'SOLACE is a pain management application designed for palliative and hospice care. It allows users to track vitals, monitor symptoms, and connect with caregivers and doctors for timely interventions.',
    },
    {
      'question': 'How can I track my vitals?',
      'answer':
          'You can log your vitals in the app under the "Vitals" section. The app will help you monitor trends over time.',
    },
    {
      'question': 'Can I schedule tasks or appointments?',
      'answer':
          'Yes! SOLACE allows users to schedule tasks and appointments directly within the app to keep you organized.',
    },
    {
      'question': 'How do I reset my password?',
      'answer':
          'To reset your password, go to the login screen and click on "Forgot Password." Follow the instructions sent to your registered email.',
    },
    {
      'question': 'Who can I contact for further support?',
      'answer':
          'You can always contact us at teamres.solace@gmail.com, and we’ll assist you as soon as possible.',
    },
  ];

  @override
  void initState() {
    super.initState();
    expandedState = List<bool>.filled(faqData.length, false);
  }

  void _launchPalCollabLink() async {
    final Uri url = Uri.parse('https://www.ruth.ph/palcollab');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'teamres.solace@gmail.com',
      query: 'subject=Support Request&body=Hello, I need assistance with...',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch $emailUri';
    }
  }

  Widget _solace() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Image.asset('lib/assets/images/auth/solace.png', width: 60),
          const SizedBox(width: 10.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SOLACE', style: Textstyle.subheader),
              Text('By Team RES', style: Textstyle.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goToPalCollab() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage(
                  'lib/assets/images/auth/ruth_backdrop.jpg',
                ),
                fit: BoxFit.cover, // Ensure the image fills the container
              ),
            ),
            // Use ImageFiltered instead of BackdropFilter
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 8,
                sigmaY: 8,
              ), // Blur effect
              child: Container(
                color: AppColors.black.withValues(alpha: 0.2), // Black overlay
              ),
            ),
          ),
        ),

        // Name and button overlay
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Connect with PalCollab',
                style: Textstyle.heading.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: 200,
                child: TextButton(
                  onPressed: _launchPalCollabLink, // Launch external link
                  style: Buttonstyle.buttonDarkGray,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Visit PalCollab',
                        style: Textstyle.smallButton.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.open_in_new, size: 16, color: AppColors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aboutPalCollab() {
    return Container(
      color: AppColors.black.withValues(alpha: 0.9),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About PalCollab',
            style: Textstyle.subheader.copyWith(color: AppColors.white),
          ),
          SizedBox(height: 10),
          Image.asset('lib/assets/images/auth/palcollab.png'),
          SizedBox(height: 20),
          Text(
            "The Ruth Foundation's PalCollab is an approach created for advocates of Palliative Care in the Philippines which works toward providing:",
            style: Textstyle.bodyWhite,
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 20),
          _goToPalCollab(),
        ],
      ),
    );
  }

  Widget _buildMainHelp() {
    return Column(
      children: [
        SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Text(
                'At SOLACE, we understand that you might need assistance from time to time, and we are committed to providing you with the utmost help. Whether you have questions, face challenges, or need support, we are here for you.',
                style: Textstyle.body,
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 10),
              Text(
                'Please don’t hesitate to reach out to us. Our dedicated support team is always ready to assist you with any queries or issues you may encounter during your experience with the app.',
                style: Textstyle.body,
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          color: const Color.fromARGB(255, 0, 90, 72),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'How to reach us?',
                    style: Textstyle.heading.copyWith(color: AppColors.white),
                  ),
                ],
              ),
              Text(
                'You can reach us via email at: ',
                style: Textstyle.bodySmall.copyWith(color: AppColors.white),
              ),
              SizedBox(
                width: 280,
                child: TextButton(
                  onPressed: _launchEmail,
                  style: Buttonstyle.buttonDarkGray,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.email_rounded,
                        size: 16,
                        color: AppColors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'teamres.solace@gmail.com',
                        style: Textstyle.bodyWhite.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _moreFAQs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 126, 126, 126),
              const Color.fromARGB(255, 95, 95, 95),
              const Color.fromARGB(255, 59, 59, 59),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 36, color: AppColors.white),
            SizedBox(width: 20),
            Flexible(
              child: Text(
                'If your question isn’t listed above, feel free to contact us. We’re here to assist you!',
                style: Textstyle.bodySmall.copyWith(color: AppColors.white),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(message, style: Textstyle.subheader),
    );
  }

  Widget _footer() {
    return Container(
      height: 100,
      color: AppColors.black.withValues(alpha: 0.93),
      child: Center(
        child: Text(
          "© 2025 Team RES - All Rights Reserved.",
          style: Textstyle.bodyWhite,
        ),
      ),
    );
  }

  List<Widget> _buildFaqList() {
    return List.generate(faqData.length, (index) {
      final faq = faqData[index];
      return ExpansionTile(
        onExpansionChanged: (bool expanded) {
          setState(() {
            expandedState[index] = expanded; // Update state for this tile
          });
        },
        collapsedBackgroundColor: AppColors.white,
        collapsedIconColor: AppColors.black,
        shape: Border(),
        iconColor: AppColors.black,
        title: Text(
          faq['question']!,
          style:
              expandedState[index]
                  ? Textstyle.body.copyWith(fontWeight: FontWeight.bold)
                  : Textstyle.body,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(faq['answer']!, style: Textstyle.body),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Help & Support', style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _solace(),
              SizedBox(height: 10),
              _buildTitle('We are here to help!'),
              _buildMainHelp(),
              SizedBox(height: 20),
              _buildTitle('Frequently Asked Questions (FAQs)'),
              SizedBox(height: 5),
              ..._buildFaqList(),
              SizedBox(height: 20),
              _moreFAQs(),
              SizedBox(height: 40),
              _aboutPalCollab(),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }
}
