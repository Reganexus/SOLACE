// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

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
        title: Text('Select Your Profile Image', style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        centerTitle: true,
      ),
      body: Container(
        color: AppColors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                      style: Buttonstyle.buttonRed,
                      child: Text('Cancel', style: Textstyle.smallButton),
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Expanded(
                    child: TextButton(
                      onPressed:
                          selectedImage != null &&
                                  selectedImage != widget.currentImage
                              ? () {
                                Navigator.of(context).pop(selectedImage);
                              }
                              : null,
                      style:
                          selectedImage != null &&
                                  selectedImage != widget.currentImage
                              ? Buttonstyle.buttonNeon
                              : Buttonstyle.buttonGray,
                      child: Text('Select', style: Textstyle.smallButton),
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
