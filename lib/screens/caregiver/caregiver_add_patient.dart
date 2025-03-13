// ignore_for_file: avoid_print
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:solace/shared/widgets/select_profile_image.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/database.dart';

class CaregiverAddPatient extends StatefulWidget {
  const CaregiverAddPatient({super.key});

  @override
  State<CaregiverAddPatient> createState() => _CaregiverAddPatientState();
}

class _CaregiverAddPatientState extends State<CaregiverAddPatient> {
  File? _profileImage;
  String? _profileImageUrl;
  DateTime? birthday;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> patientData = {}; // Initialize as an empty map

  bool isLoading = true;
  bool hasError = false;

  // Focus nodes for form fields
  final List<FocusNode> _focusNodes = List.generate(13, (_) => FocusNode());

  late String newPatientId;

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

  Future<File> getFileFromAsset(String assetPath) async {
    final byteData = await rootBundle.load(assetPath); // Load the asset
    final tempDir = await getTemporaryDirectory(); // Get temp directory
    final tempFile =
        File('${tempDir.path}/${assetPath.split('/').last}'); // Create file
    return await tempFile
        .writeAsBytes(byteData.buffer.asUint8List()); // Write byte data to file
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
            contentType: 'image/jpeg'), // Ensure correct content type
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
    final selectedImage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectProfileImageScreen(
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

      print("Selected image file path: ${_profileImage!.path}");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // Define the minimum and maximum date limits
    final DateTime today = DateTime.now();
    final DateTime minDate =
        DateTime(today.year - 120); // Set 120 years ago as the minimum
    final DateTime maxDate =
        DateTime(today.year - 1); // Ensure user is at least 1 year old

    final DateTime initialDate =
        birthday ?? maxDate; // Default to maxDate if birthday is null

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
        birthday = picked; // Store the DateTime object
        birthdayController.text =
            '${_getMonthName(picked.month)} ${picked.day}, ${picked.year}'; // Display formatted string
      });
    }
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;

    final currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;

    // Check if the birthday has not yet occurred this year
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String capitalizeEachWord(String text) {
    return text
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  String _getMonthName(int month) {
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
      'December'
    ];
    return monthNames[month - 1];
  }

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

  // Form field controllers
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

  String gender = '';
  String religion = '';
  String organDonation = 'None';

  // Method to build input decorations
  InputDecoration _buildInputDecoration(String label, FocusNode focusNode) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.gray,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.neon, width: 2)),
      labelStyle: TextStyle(
        fontSize: 16,
        fontFamily: 'Inter',
        fontWeight: FontWeight.normal,
        color: focusNode.hasFocus ? AppColors.neon : AppColors.black,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final nameRegExp =
      RegExp(r"^[\p{L}\s]+(?:\.\s?[\p{L}]+)*$", unicode: true);

      String capitalize(String text) =>
          text.trim().split(' ').map((str) {
            if (str.isEmpty) return '';
            return str[0].toUpperCase() + str.substring(1).toLowerCase();
          }).join(' ');

      String sentenceCase(String text) {
        if (text.isEmpty) return text;
        return text[0].toUpperCase() + text.substring(1).toLowerCase();
      }

      // Validate name fields
      final String firstName = capitalize(firstNameController.text);
      final String middleName =
      middleNameController.text.trim().isNotEmpty
          ? capitalize(middleNameController.text)
          : '';
      final String lastName = capitalize(lastNameController.text);

      if (firstName.isEmpty || !nameRegExp.hasMatch(firstName)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid first name.')));
        return;
      }
      if (middleName.isNotEmpty && !nameRegExp.hasMatch(middleName)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid middle name.')));
        return;
      }
      if (lastName.isEmpty || !nameRegExp.hasMatch(lastName)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid last name.')));
        return;
      }

      // Validate Birthday
      if (birthday == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a birthday.')),
        );
        return;
      }

      // Get the profile image URL
      String profileImageUrl = _profileImageUrl ?? '';
      print("Add Patient Profile Image URL: $_profileImageUrl");

      if (_profileImage != null) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Uploading profile image...')),
          );

          profileImageUrl = await uploadProfileImage(
            userId: newPatientId,
            file: _profileImage!,
          );

          print("Image uploaded and URL received: $profileImageUrl");
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload profile image.')),
          );
          return;
        }
      }

      // Validate additional fields
      if (gender.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select your gender.')));
        return;
      }
      if (religion.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select your religion.')));
        return;
      }

      final String will = capitalize(willController.text);
      final String fixedWishes = capitalize(fixedWishesController.text);
      final String caseTitle = capitalize(caseTitleController.text);
      final String caseDescription = sentenceCase(caseDescriptionController.text);

      if (will.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Will cannot be empty.')));
        return;
      }
      if (fixedWishes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fixed Wishes cannot be empty.')));
        return;
      }
      if (organDonation.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Please select organ donation preference.')));
        return;
      }
      if (caseTitle.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Case Title cannot be empty.')));
        return;
      }
      if (caseDescription.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Case Description cannot be empty.')));
        return;
      }

      try {
        String status = 'stable';

        await DatabaseService().addPatientData(
          uid: newPatientId,
          firstName: firstName,
          lastName: lastName,
          middleName: middleName,
          age: _calculateAge(birthday),
          gender: gender,
          religion: religion,
          will: will,
          fixedWishes: fixedWishes,
          organDonation: organDonation,
          profileImageUrl: profileImageUrl,
          birthday: birthday,
          caseTitle: caseTitle,
          caseDescription: caseDescription,
          status: status,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient data submitted successfully!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting patient data: $e')),
        );
      }
    }
  }


// Method to build the patient info card
  Widget _buildForm() {
    return SingleChildScrollView(
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
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
                      radius: 75,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!) // Picked image
                          : (_profileImageUrl != null &&
                                  _profileImageUrl!.isNotEmpty
                              ? AssetImage(_profileImageUrl!) // Asset image
                              : AssetImage(
                                  'lib/assets/images/shared/placeholder.png')),
                      backgroundColor: Colors.transparent,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.blackTransparent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          _pickProfileImage(
                              'patient'); // Wrap in an anonymous function
                        },
                        icon: Icon(Icons.camera_alt, color: AppColors.white),
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 1.0),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Case',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: caseTitleController,
                focusNode: _focusNodes[9],
                decoration: _buildInputDecoration('Case Title', _focusNodes[9]),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                validator: (val) =>
                    val!.isEmpty ? 'Case Title cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: caseDescriptionController,
                focusNode: _focusNodes[10],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration:
                    _buildInputDecoration('Case Description', _focusNodes[10]),
                maxLines: 1,
                validator: (val) =>
                    val!.isEmpty ? 'Case Description cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 1.0),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: firstNameController,
                focusNode: _focusNodes[0],
                decoration: _buildInputDecoration('First Name', _focusNodes[0]),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                validator: (val) =>
                    val!.isEmpty ? 'First Name cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: middleNameController,
                focusNode: _focusNodes[1],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration:
                    _buildInputDecoration('Middle Name', _focusNodes[1]),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: lastNameController,
                focusNode: _focusNodes[2],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration('Last Name', _focusNodes[2]),
                validator: (val) =>
                    val!.isEmpty ? 'Last Name cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              // Birthday Field
              TextFormField(
                controller: birthdayController,
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
                    color: _focusNodes[3].hasFocus
                        ? AppColors.neon
                        : AppColors.black,
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.neon, width: 2)),
                  labelStyle: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: _focusNodes[3].hasFocus
                        ? AppColors.neon
                        : AppColors.black,
                  ),
                ),
                validator: (val) =>
                    val!.isEmpty ? 'Birthday cannot be empty' : null,
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: gender.isNotEmpty ? gender : null,
                focusNode: _focusNodes[4],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration('Gender', _focusNodes[4]),
                items: ['Male', 'Female', 'Other']
                    .map((value) =>
                        DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (val) => setState(() => gender = val ?? ''),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Select Gender' : null,
                dropdownColor: AppColors.white,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: religion.isNotEmpty ? religion : null,
                focusNode: _focusNodes[5],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration('Religion', _focusNodes[5]),
                items: religions
                    .map((religionItem) => DropdownMenuItem(
                        value: religionItem, child: Text(religionItem)))
                    .toList(),
                onChanged: (val) => setState(() => religion = val ?? ''),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Select Religion' : null,
                dropdownColor: AppColors.white,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: willController,
                focusNode: _focusNodes[6],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration('Will', _focusNodes[6]),
                validator: (val) =>
                    val!.isEmpty ? 'Will cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: fixedWishesController,
                focusNode: _focusNodes[7],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration:
                    _buildInputDecoration('Fixed Wishes', _focusNodes[7]),
                validator: (val) =>
                    val!.isEmpty ? 'Fixed Wishes cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: organDonation.isNotEmpty ? organDonation : null,
                focusNode: _focusNodes[8],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration:
                    _buildInputDecoration('Organ Donation', _focusNodes[8]),
                items: organs
                    .map((organ) =>
                        DropdownMenuItem(value: organ, child: Text(organ)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => organDonation = val ?? 'None'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Select Organ Donation' : null,
                dropdownColor: AppColors.white,
              ),

              const SizedBox(height: 10),
              const Divider(thickness: 1.0),
              const SizedBox(height: 10),

              Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 40,
                      color: AppColors.white,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Please check the input before submitting.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 18,
                          fontFamily: 'Inter',
                          color: AppColors.white),
                    ),
                    Text(
                      'All input must be true',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: AppColors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _submitForm,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 15),
                    backgroundColor: AppColors.neon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Add Patient',
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

  String formatDate(dynamic birthday) {
    if (birthday is Timestamp) {
      // If it's a Timestamp, convert to DateTime and format
      return DateFormat('MMMM d, yyyy').format(birthday.toDate());
    } else if (birthday is String) {
      // If it's a String, parse it to DateTime and format
      try {
        DateTime date = DateTime.parse(birthday);
        return DateFormat('MMMM d, yyyy').format(date);
      } catch (e) {
        // Handle invalid date format if necessary
        return 'Invalid Date';
      }
    }
    return 'No Birthday'; // In case of null or unsupported type
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
            title: const Text(
              'Patient Info',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ),
          body: _buildForm()),
    );
  }
}
