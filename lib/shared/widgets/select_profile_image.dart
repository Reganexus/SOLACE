// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';

class SelectProfileImageScreen extends StatefulWidget {
  final String role; // Role of the user
  final String? currentImage; // Current image selected

  const SelectProfileImageScreen({
    super.key,
    required this.role,
    this.currentImage,
  });

  @override
  _SelectProfileImageScreenState createState() =>
      _SelectProfileImageScreenState();
}

class _SelectProfileImageScreenState extends State<SelectProfileImageScreen> {
  String? selectedImage;
  late List<String> predefinedImages;

  // Define role-specific images
  final Map<String, List<String>> roleImages = {
    'patient': List.generate(
      9,
      (index) => 'lib/assets/images/predefined/patient/patient${index + 1}.png',
    ),
    'caregiver': List.generate(
      9,
      (index) =>
          'lib/assets/images/predefined/caregiver/caregiver${index + 1}.png',
    ),
    'doctor': List.generate(
      9,
      (index) => 'lib/assets/images/predefined/doctor/doctor${index + 1}.png',
    ),
    'nurse': List.generate(
      9,
      (index) => 'lib/assets/images/predefined/nurse/nurse${index + 1}.png',
    ),
  };

  @override
  void initState() {
    super.initState();
    selectedImage = widget.currentImage;
    predefinedImages = roleImages[widget.role] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Your Profile Image',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: Container(
        color: AppColors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30.0, 20.0, 30.0, 30.0),
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 5.0,
                    mainAxisSpacing: 5.0,
                  ),
                  itemCount: predefinedImages.length,
                  itemBuilder: (context, index) {
                    final image = predefinedImages[index];
                    final isSelected = image == selectedImage;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedImage = image;
                        });
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage(image),
                            backgroundColor: Colors.transparent,
                          ),
                          if (isSelected)
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.neon,
                                  width: 5.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        backgroundColor: AppColors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10.0,
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: selectedImage != null
                          ? () {
                              Navigator.of(context).pop(selectedImage);
                            }
                          : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        backgroundColor: AppColors.neon,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Select',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
