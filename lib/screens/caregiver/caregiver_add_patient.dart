// ignore_for_file: avoid_print
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:solace/services/error_handler.dart';
import 'package:solace/services/validator.dart';
import 'package:solace/shared/widgets/select_profile_image.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/dropdownfield.dart';
import 'package:solace/themes/textformfield.dart';
import 'package:solace/themes/textstyle.dart';

class CaregiverAddPatient extends StatefulWidget {
  const CaregiverAddPatient({super.key});

  @override
  State<CaregiverAddPatient> createState() => _CaregiverAddPatientState();
}

class _CaregiverAddPatientState extends State<CaregiverAddPatient> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> patientData = {};
  File? _profileImage;
  String? _profileImageUrl;
  DateTime? birthday;
  String gender = '';
  String religion = '';
  String organDonation = 'None';
  bool _isLoading = false;
  bool hasError = false;

  final List<FocusNode> _focusNodes = List.generate(13, (_) => FocusNode());
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController religionController = TextEditingController();
  final TextEditingController willController = TextEditingController();
  final TextEditingController fixedWishesController = TextEditingController();
  final TextEditingController organDonationController = TextEditingController();
  final TextEditingController caseTitleController = TextEditingController();
  final TextEditingController caseDescriptionController =
      TextEditingController();
  final TextEditingController profileImageUrlController =
      TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  late String newPatientId;

  static const List<String> religions = [
    'Roman Catholic',
    'Islam',
    'Iglesia ni Cristo',
    'Other',
  ];

  static const List<String> organs = [
    'Heart',
    'Liver',
    'Kidney',
    'Lung',
    'None',
  ];

  @override
  void initState() {
    super.initState();
    newPatientId = FirebaseFirestore.instance.collection('patient').doc().id;
  }

  @override
  void dispose() {
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
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

  Future<File> getFileFromAsset(String assetPath) async {
    final byteData = await rootBundle.load(assetPath); // Load the asset
    final tempDir = await getTemporaryDirectory(); // Get temp directory
    final tempFile = File(
      '${tempDir.path}/${assetPath.split('/').last}',
    ); // Create file
    return await tempFile.writeAsBytes(
      byteData.buffer.asUint8List(),
    ); // Write byte data to file
  }

  Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      // Reference to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('patient_profile_pictures')
          .child('$userId.jpg');

      // Upload file
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
        ), // Ensure correct content type
      );

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {});

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print("Image uploaded successfully: $downloadUrl");
      return downloadUrl; // Return the URL
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception("Error uploading profile image: $e");
    }
  }

  Future<void> _pickProfileImage(String role) async {
    try {
      final selectedImage = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SelectProfileImageScreen(
                role: role,
                currentImage: _profileImageUrl,
              ),
        ),
      );

      if (selectedImage != null) {
        if (selectedImage.startsWith('lib/')) {
          // Convert asset to file
          _profileImage = await getFileFromAsset(selectedImage);
        } else {
          // Regular file path
          _profileImage = File(selectedImage);
        }

        setState(() {
          _profileImageUrl = null; // Clear old URLs
        });

        debugPrint("Selected image file path: ${_profileImage!.path}");
      } else {
        debugPrint('No image selected.');
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick a profile image.')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime minDate = DateTime(today.year - 120);
    final DateTime maxDate = DateTime(today.year - 1);

    final DateTime initialDate = birthday ?? maxDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: maxDate, // Allow selecting up to the current date minus 1 year
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.neon,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        birthday = picked;
        birthdayController.text =
            birthday != null ? birthday!.getMonthName() : '';
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.isBefore(DateTime(now.year, birthDate.month, birthDate.day))) {
      age--;
    }
    return age;
  }

  bool _areAllFieldsFilled() {
    return firstNameController.text.trim().isNotEmpty &&
        lastNameController.text.trim().isNotEmpty &&
        caseTitleController.text.trim().isNotEmpty &&
        caseDescriptionController.text.trim().isNotEmpty &&
        addressController.text.trim().isNotEmpty &&
        willController.text.trim().isNotEmpty &&
        fixedWishesController.text.trim().isNotEmpty &&
        birthday != null &&
        gender.isNotEmpty &&
        religion.isNotEmpty &&
        organDonation.isNotEmpty;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final userId = newPatientId;
      if (userId == null) return;

      showToast("Submitting data. Please wait.");
      // Validate names
      if (Validator.name(firstNameController.text.trim()) != null) {
        throw Exception("Invalid first name.");
      }
      if (Validator.name(middleNameController.text.trim()) != null) {
        throw Exception("Invalid middle name.");
      }
      if (Validator.name(lastNameController.text.trim()) != null) {
        throw Exception("Invalid last name.");
      }

      // Validate birthday
      if (birthday == null) {
        throw Exception('Please select a birthday.');
      }

      // Upload profile image if needed
      String? profileImageUrl = _profileImageUrl;

      if (_profileImage != null) {
        showToast("Uploading profile image");
        try {
          profileImageUrl = await DatabaseService.uploadProfileImage(
            userId: userId,
            file: _profileImage!,
          );
        } catch (e) {
          throw Exception("Failed to upload profile image");
        }
      }

      final age = _calculateAge(birthday!);

      // Validate other fields
      if (gender.isEmpty) {
        throw Exception('Please select your gender.');
      }
      if (religion.isEmpty) {
        throw Exception('Please select your religion.');
      }
      if (addressController.text.trim().isEmpty) {
        throw Exception('Address cannot be empty.');
      }

      if (willController.text.trim().isEmpty) {
        throw Exception('Please select your gender.');
      }
      if (fixedWishesController.text.trim().isEmpty) {
        throw Exception('Please select your religion.');
      }
      if (caseTitleController.text.trim().isEmpty) {
        throw Exception('Address cannot be empty.');
      }
      if (caseDescriptionController.text.trim().isEmpty) {
        throw Exception('Address cannot be empty.');
      }

      // Submit to database
      await DatabaseService().addPatientData(
        uid: newPatientId,
        firstName: firstNameController.text.trim().capitalizeEachWord(),
        lastName: lastNameController.text.trim().capitalizeEachWord(),
        middleName: middleNameController.text.trim().capitalizeEachWord(),
        age: age,
        gender: gender,
        religion: religion,
        will: willController.text.trim().capitalizeEachWord(),
        fixedWishes: fixedWishesController.text.trim().capitalizeEachWord(),
        organDonation: organDonation,
        profileImageUrl: profileImageUrl,
        birthday: birthday,
        caseTitle: caseTitleController.text.trim().capitalizeEachWord(),
        caseDescription:
            caseDescriptionController.text.trim().capitalizeEachWord(),
        status: 'stable',
        address: addressController.text.trim().capitalizeEachWord(),
      );

      showToast('Patient data submitted successfully!');
      Navigator.of(context).pop();
    } catch (e) {
      _showError(['Error submitting patient data: $e']);
    }
  }

  void _showError(List<String> errorMessages) {
    if (errorMessages.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder:
          (context) => ErrorDialog(title: 'Error', messages: errorMessages),
    );
  }

  Widget divider() {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Divider(thickness: 1.0),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget deter() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 40,
                    color: AppColors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please check the input before submitting.',
                    textAlign: TextAlign.center,
                    style: Textstyle.bodyWhite,
                  ),
                  Text(
                    'All input must be true',
                    textAlign: TextAlign.center,
                    style: Textstyle.bodyWhite.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          scrolledUnderElevation: 0.0,
          title: Text('Patient Info', style: Textstyle.subheader),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Image Section
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            _profileImage != null
                                ? FileImage(_profileImage!) // Picked image
                                : (_profileImageUrl != null &&
                                            _profileImageUrl!.isNotEmpty
                                        ? AssetImage(_profileImageUrl!)
                                        : AssetImage(
                                          'lib/assets/images/shared/placeholder.png',
                                        ))
                                    as ImageProvider,
                        backgroundColor: Colors.transparent,
                      ),
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: AppColors.blackTransparent,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed:
                              _isLoading
                                  ? null // Disable during loading
                                  : () {
                                    _pickProfileImage('patient');
                                  },
                          icon: Icon(Icons.camera_alt, color: AppColors.white),
                          iconSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('Current Case', style: Textstyle.subheader)],
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: caseTitleController,
                  focusNode: _focusNodes[9],
                  labelText: 'Case Title',
                  enabled: !_isLoading,
                  validator:
                      (val) =>
                          val!.isEmpty ? 'Case Title cannot be empty' : null,
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: caseDescriptionController,
                  focusNode: _focusNodes[10],
                  labelText: 'Case Description',
                  enabled: !_isLoading,
                  validator:
                      (val) =>
                          val!.isEmpty
                              ? 'Case Description cannot be empty'
                              : null,
                ),
                divider(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Personal Information', style: Textstyle.subheader),
                  ],
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: firstNameController,
                  focusNode: _focusNodes[0],
                  labelText: 'First Name',
                  enabled: !_isLoading,
                  validator:
                      (val) =>
                          val!.isEmpty ? 'First Name cannot be empty' : null,
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: middleNameController,
                  focusNode: _focusNodes[1],
                  labelText: 'Middle Name',
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: lastNameController,
                  focusNode: _focusNodes[2],
                  labelText: 'Last Name',
                  enabled: !_isLoading,
                  validator:
                      (val) =>
                          val!.isEmpty ? 'Last Name cannot be empty' : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: birthdayController,
                  enabled: !_isLoading,
                  focusNode: _focusNodes[3],
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Birthday',
                    filled: true,
                    fillColor: AppColors.gray,
                    suffixIcon: Icon(
                      Icons.calendar_today,
                      color:
                          _focusNodes[3].hasFocus
                              ? AppColors.neon
                              : AppColors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.neon, width: 2),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.normal,
                      color:
                          _focusNodes[3].hasFocus
                              ? AppColors.neon
                              : AppColors.black,
                    ),
                  ),
                  validator:
                      (val) => val!.isEmpty ? 'Birthday cannot be empty' : null,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),

                const SizedBox(height: 20),

                CustomDropdownField<String>(
                  value: gender.isNotEmpty ? gender : null,
                  focusNode: _focusNodes[4],
                  labelText: 'Gender',
                  items: ['Male', 'Female', 'Other'],
                  onChanged: (val) => setState(() => gender = val ?? ''),
                  validator:
                      (val) =>
                          val == null || val.isEmpty ? 'Select Gender' : null,
                  displayItem: (value) => value,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),

                CustomDropdownField<String>(
                  value: religion.isNotEmpty ? religion : null,
                  focusNode: _focusNodes[5],
                  labelText: 'Religion',
                  items: religions,
                  onChanged: (val) => setState(() => religion = val ?? ''),
                  validator:
                      (val) =>
                          val == null || val.isEmpty ? 'Select Religion' : null,
                  displayItem: (value) => value,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: addressController,
                  focusNode: _focusNodes[6],
                  labelText: 'Address',
                  enabled: !_isLoading,
                  validator:
                      (val) => val!.isEmpty ? 'Address cannot be empty' : null,
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: willController,
                  focusNode: _focusNodes[7],
                  labelText: 'Will',
                  enabled: !_isLoading,
                  validator:
                      (val) => val!.isEmpty ? 'Will cannot be empty' : null,
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: fixedWishesController,
                  focusNode: _focusNodes[8],
                  labelText: 'Fixed Wishes',
                  enabled: !_isLoading,
                  validator:
                      (val) =>
                          val!.isEmpty ? 'Fixed Wishes cannot be empty' : null,
                ),
                const SizedBox(height: 20),

                CustomDropdownField<String>(
                  value: organDonation.isNotEmpty ? organDonation : null,
                  focusNode: _focusNodes[9],
                  labelText: 'Organ Donation',
                  items: organs,
                  onChanged:
                      (val) => setState(() => organDonation = val ?? 'None'),
                  validator:
                      (val) =>
                          val == null || val.isEmpty
                              ? 'Select Organ Donation'
                              : null,
                  displayItem: (value) => value,
                  enabled: !_isLoading,
                ),

                divider(),

                _areAllFieldsFilled() ? deter() : const SizedBox.shrink(),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _submitForm,
                    style: _isLoading ? Buttonstyle.gray : Buttonstyle.neon,
                    child: Text('Add Patient', style: Textstyle.largeButton),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtensions on String {
  String capitalizeEachWord() {
    return split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : '',
        )
        .join(' ');
  }

  String sentenceCase() {
    if (isEmpty) return this;
    return this[0].toUpperCase() +
        substring(1).toLowerCase().replaceAllMapped(
          RegExp(r'(?<=[.!?]\s)(\w)'),
          (match) => match.group(1)!.toUpperCase(),
        );
  }
}

extension DateTimeExtensions on DateTime {
  String getMonthName() {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
  }
}
