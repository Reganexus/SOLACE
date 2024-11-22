// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:solace/screens/wrapper.dart';
import 'package:solace/themes/colors.dart';

class GetStarted extends StatefulWidget {
  const GetStarted({super.key});

  @override
  State<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted> {
  void navigateWithSwipeLeftAnimation() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const Wrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Define the swipe left animation
          const begin = Offset(1.0, 0.0);  // Start from the right (1.0, 0.0)
          const end = Offset.zero;         // End at the center (0.0, 0.0)
          const curve = Curves.easeInOut;  // Use easeInOut curve for smooth transition

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with logo and title
              Row(
                children: [
                  Image.asset(
                    'lib/assets/images/auth/solace.png',
                    width: 60,
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
                    const Text(
                      'Welcome to SOLACE!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Where we bridge the gap in palliative and hospice care',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Inter',
                          fontSize: 22,
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
                  onPressed: navigateWithSwipeLeftAnimation, // Navigate with swipe left animation
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 15),
                    backgroundColor: AppColors.neon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
