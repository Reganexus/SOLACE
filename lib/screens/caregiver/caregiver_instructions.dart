// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/screens/wrapper.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/loader.dart';
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
  bool _isProcessing = false;
  bool _isLoading = true; // Track whether everything is loading

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
    _loadContent();
    debugPrint("user id: ${widget.userId}");
    debugPrint("user role: ${widget.userRole}");
  }

  Future<void> _loadContent() async {
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _isLoading = false;
    });
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
        _isProcessing = true;
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
      height: MediaQuery.of(context).size.height * 0.7,
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          // Slide 1 - GIF for Page 1
          _buildGifPage('lib/assets/images/auth/page1.gif'),
          // Slide 2 - GIF for Page 2
          _buildGifPage('lib/assets/images/auth/page2.gif'),
          // Slide 3 - GIF for Page 3
          _buildGifPage('lib/assets/images/auth/page3.gif'),
          // Slide 4 - GIF for Page 4
          _buildGifPage('lib/assets/images/auth/page4.gif'),
        ],
      ),
    );
  }

  // Helper function to build a page with a GIF
  Widget _buildGifPage(String gifPath) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.7,
      color: AppColors.gray,
      child: Center(
        child:
            _isLoading
                ? Loader.loaderPurple
                : Image.asset(gifPath, fit: BoxFit.cover),
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
            _isProcessing ||
                    _isLoading // Disable button when processing or content is loading
                ? null
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
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
      body: Stack(
        children: [
          // Main content of the screen
          Padding(
            padding: EdgeInsets.symmetric(vertical: 60.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(),
                Expanded(child: _buildCarousel()),
                const SizedBox(height: 20),
                _buildNavigationCircles(),
                const SizedBox(height: 20),
                _buildNextButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: AppColors.white,
              child: Center(child: Loader.loaderPurple),
            ),
        ],
      ),
    );
  }
}
