import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Help & Support'),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: AppColors.gray,
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  children: [
                    Image.asset(
                      'lib/assets/images/auth/solace.png',
                      width: 80,
                    ),
                    const SizedBox(width: 10.0),
                    const Text(
                      'SOLACE',
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'We are here to help!',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'At SOLACE, we understand that you might need assistance from time to time, and we are committed to providing you with the utmost help. Whether you have questions, face challenges, or need support, we are here for you.\n\n'
                    'Please don’t hesitate to reach out to us. Our dedicated support team is always ready to assist you with any queries or issues you may encounter during your experience with the app.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(thickness: 1.0),
              const SizedBox(height: 10),
              Text(
                'How to reach us',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'You can reach us via email at: ',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  fontSize: 18,
                ),
              ),
              SelectableText(
                'solace@gmail.com',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 1.0),
              const SizedBox(height: 10),
              Text(
                'Frequently Asked Questions (FAQs)',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              SizedBox(height: 20),
              ..._buildFaqList(),
              SizedBox(height: 20),
              Text(
                'If your question isn’t listed above, feel free to contact us. We’re here to assist you!',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFaqList() {
    final faqData = [
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
        'You can always contact us at solace@gmail.com, and we’ll assist you as soon as possible.',
      },
    ];

    return faqData.map((faq) {
      return ExpansionTile(
        collapsedBackgroundColor: AppColors.gray,
        collapsedIconColor: AppColors.black,
        iconColor: AppColors.black,
        backgroundColor: AppColors.gray,
        title: Text(
          faq['question']!,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              faq['answer']!,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
              ),
            ),
          ),
        ],
      );
    }).toList();
  }
}
