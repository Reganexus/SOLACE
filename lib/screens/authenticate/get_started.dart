// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:solace/screens/wrapper.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class GetStarted extends StatefulWidget {
  const GetStarted({super.key});

  @override
  State<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted> {
  void navigateToWrapper() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Wrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with logo and title
              Row(
                children: [
                  Image.asset('lib/assets/images/auth/solace.png', width: 60),
                  const SizedBox(width: 10.0),
                  Text(
                    'SOLACE',
                    style: Textstyle.heading.copyWith(fontFamily: 'Outfit'),
                  ),
                ],
              ),

              // Image and subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/images/auth/get_started.png',
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    Text('Welcome to SOLACE!', style: Textstyle.title),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Bridging the gap in palliative and hospice care',
                        textAlign: TextAlign.center,
                        style: Textstyle.subheader.copyWith(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Get Started button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: navigateToWrapper,
                  style: Buttonstyle.neon,
                  child: Text('Get Started', style: Textstyle.largeButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
