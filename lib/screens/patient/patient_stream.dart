import 'package:flutter/material.dart';
import 'package:solace/screens/patient/patient_medicine.dart';
import 'package:solace/screens/patient/patient_schedule.dart';
import 'package:solace/screens/patient/patient_tasks.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class CarouselWidget extends StatefulWidget {
  final PageController pageController;
  final String patientId;

  const CarouselWidget({
    super.key,
    required this.pageController,
    required this.patientId,
  });

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  int _currentPage = 0;

  void _navigateToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    widget.pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.black.withValues(alpha: 0.8),
          padding: const EdgeInsets.fromLTRB(16.0, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Patient Activities",
                style: Textstyle.subheader.copyWith(color: AppColors.white),
              ),
              SizedBox(height: 10),
              Text(
                'Navigate through the buttons to show patient activities.',
                style: Textstyle.bodyWhite,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavigationButton("Schedules", 0),
                  SizedBox(width: 10),
                  _buildNavigationButton("Tasks", 1),
                  SizedBox(width: 10),
                  _buildNavigationButton("Prescriptions", 2),
                ],
              ),
            ],
          ),
        ),

        // PageView
        SizedBox(
          height: 700,
          child: PageView(
            controller: widget.pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildSlide(PatientSchedule(patientId: widget.patientId)),
              _buildSlide(PatientTasks(patientId: widget.patientId)),
              _buildSlide(PatientMedicine(patientId: widget.patientId)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButton(String title, int pageIndex) {
    return Expanded(
      child: TextButton(
        onPressed: () => _navigateToPage(pageIndex),
        style:
            _currentPage == pageIndex
                ? Buttonstyle.buttonNeon
                : Buttonstyle.buttonGray,
        child: Text(
          title,
          style: Textstyle.bodySmall.copyWith(
            color: AppColors.white,
            fontWeight:
                _currentPage == pageIndex ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [content],
    );
  }
}
