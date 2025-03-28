// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/screens/wrapper.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class CaregiverInstructions extends StatefulWidget {
  final String userId;
  final String userRole;

  const CaregiverInstructions({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  CaregiverInstructionsState createState() => CaregiverInstructionsState();
}

class CaregiverInstructionsState extends State<CaregiverInstructions> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isProcessing = false; // Tracks if the "Let's Go!" button is clicked

  static const List<String> headings = [
    'Tracking',
    'Intervention',
    'Communication',
    'PalCollab',
  ];

  static const List<String> subheadings = [
    'SOLACE is used to track patient symptoms to monitor and provide timely interventions.',
    'Powered by our AI, timely interventions can be given in real-time based on tracking inputs.',
    'Schedules, Tasks, and Medicines can be communicated within the app.',
    'Through PalCollab, palliative and hospice care advocates can connect with Ruth Foundation for referrals.',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _completeInstructions() async {
    try {
      showToast('Navigating to Home');
      setState(() {
        _isProcessing = true; // Disable the button
      });

      final userDocRef = FirebaseFirestore.instance
          .collection(widget.userRole)
          .doc(widget.userId);

      final docSnapshot = await userDocRef.get();
      if (!docSnapshot.exists) {
        throw Exception("Document not found for userId: ${widget.userId}");
      }

      await userDocRef.update({'newUser': false});

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Wrapper()),
        (route) => false,
      );
    } catch (e) {
      print('Error updating newUser field: $e');
      showToast('Error updating newUser field: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 400,
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          // Slide 1
          Container(
            color: AppColors.gray,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Step 1", style: Textstyle.subheader),
                  const SizedBox(height: 10),
                  Text(
                    "Select Patient by tapping their containers to manage them",
                    style: Textstyle.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Slide 2
          Container(
            color: AppColors.gray,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Step 2", style: Textstyle.subheader),
                  const SizedBox(height: 10),
                  Text(
                    "Select the features you want to assist the patient.",
                    style: Textstyle.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Slide 3
          Container(
            color: AppColors.gray,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Step 3", style: Textstyle.subheader),
                  const SizedBox(height: 10),
                  Text(
                    "You can add more patients by clicking the 'Add Patient' button.",
                    style: Textstyle.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: AppColors.gray,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Step 4", style: Textstyle.subheader),
                  const SizedBox(height: 10),
                  Text(
                    "You can add more patients by clicking the 'Add Patient' button.",
                    style: Textstyle.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCircles() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        headings.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _currentPage == index
                    ? AppColors.neon
                    : AppColors.blackTransparent,
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: 140,
      height: 40,
      child: TextButton(
        onPressed:
            _isProcessing
                ? null // Disable button when processing
                : () {
                  if (_currentPage < headings.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _completeInstructions();
                  }
                },
        style:
            _currentPage < headings.length - 1
                ? Buttonstyle.buttonNeon
                : _isProcessing
                ? Buttonstyle.buttonDarkGray
                : Buttonstyle.buttonNeon,
        child: Text(
          _currentPage < headings.length - 1 ? 'Next' : "Let's go!",
          style: Textstyle.smallButton,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headings[_currentPage],
            style: Textstyle.heading.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 10),
          Text(subheadings[_currentPage], style: Textstyle.body),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildCarousel(),
            const SizedBox(height: 20),
            _buildNavigationCircles(),
            const SizedBox(height: 20),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }
}
