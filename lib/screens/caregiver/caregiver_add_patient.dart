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

      print("Selected image file path: ${_profileImage!.path}");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // Define the minimum and maximum date limits
    final DateTime today = DateTime.now();
    final DateTime minDate = DateTime(
      today.year - 120,
    ); // Set 120 years ago as the minimum
    final DateTime maxDate = DateTime(
      today.year - 1,
    ); // Ensure user is at least 1 year old

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
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : '',
        )
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
      'December',
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
  final TextEditingController addressController = TextEditingController();

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
        color: focusNode.hasFocus ? AppColors.neon : AppColors.black,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      String capitalize(String text) => text
          .trim()
          .split(' ')
          .map((str) => str.isNotEmpty
          ? str[0].toUpperCase() + str.substring(1).toLowerCase()
          : '')
          .join(' ');

      String sentenceCase(String text) =>
          text.isEmpty ? text : text[0].toUpperCase() + text.substring(1).toLowerCase();

      final nameRegExp = RegExp(r"^[\p{L}\s]+(?:\.\s?[\p{L}]+)*$", unicode: true);

      final String firstName = capitalize(firstNameController.text);
      final String middleName = capitalize(middleNameController.text.trim());
      final String lastName = capitalize(lastNameController.text);

      // Validate names
      if (!nameRegExp.hasMatch(firstName)) {
        _showError('Invalid first name.');
        return;
      }
      if (middleName.isNotEmpty && !nameRegExp.hasMatch(middleName)) {
        _showError('Invalid middle name.');
        return;
      }
      if (!nameRegExp.hasMatch(lastName)) {
        _showError('Invalid last name.');
        return;
      }

      // Validate birthday
      if (birthday == null) {
        _showError('Please select a birthday.');
        return;
      }

      // Upload profile image if needed
      String profileImageUrl = _profileImageUrl ?? '';
      if (_profileImage != null) {
        profileImageUrl = await _uploadImageOrNotify();
        if (profileImageUrl.isEmpty) return; // Upload failed
      }

      // Validate other fields
      if (gender.isEmpty) {
        _showError('Please select your gender.');
        return;
      }
      if (religion.isEmpty) {
        _showError('Please select your religion.');
        return;
      }
      if (addressController.text.trim().isEmpty) {
        _showError('Address cannot be empty.');
        return;
      }

      // Prepare additional data
      final String will = capitalize(willController.text);
      final String fixedWishes = capitalize(fixedWishesController.text);
      final String caseTitle = capitalize(caseTitleController.text);
      final String caseDescription = sentenceCase(caseDescriptionController.text);
      final String address = sentenceCase(addressController.text);

      if (will.isEmpty || fixedWishes.isEmpty || caseTitle.isEmpty || caseDescription.isEmpty) {
        _showError('Some required fields are empty.');
        return;
      }

      // Submit to database
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
        status: 'stable',
        address: address,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Patient data submitted successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      _showError('Error submitting patient data: $e');
    }
  }

  Future<String> _uploadImageOrNotify() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploading profile image...')),
      );
      return await uploadProfileImage(userId: newPatientId, file: _profileImage!);
    } catch (e) {
      _showError('Failed to upload profile image.');
      return '';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
                      backgroundImage:
                          _profileImage != null
                              ? FileImage(_profileImage!) // Picked image
                              : (_profileImageUrl != null &&
                                      _profileImageUrl!.isNotEmpty
                                  ? AssetImage(_profileImageUrl!) // Asset image
                                  : AssetImage(
                                    'lib/assets/images/shared/placeholder.png',
                                  )),
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
                            'patient',
                          ); // Wrap in an anonymous function
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
                validator:
                    (val) => val!.isEmpty ? 'Case Title cannot be empty' : null,
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
                decoration: _buildInputDecoration(
                  'Case Description',
                  _focusNodes[10],
                ),
                maxLines: 1,
                validator:
                    (val) =>
                        val!.isEmpty
                            ? 'Case Description cannot be empty'
                            : null,
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
                validator:
                    (val) => val!.isEmpty ? 'First Name cannot be empty' : null,
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
                decoration: _buildInputDecoration(
                  'Middle Name',
                  _focusNodes[1],
                ),
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
                validator:
                    (val) => val!.isEmpty ? 'Last Name cannot be empty' : null,
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
                items:
                    ['Male', 'Female', 'Other']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => gender = val ?? ''),
                validator:
                    (val) =>
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
                items:
                    religions
                        .map(
                          (religionItem) => DropdownMenuItem(
                            value: religionItem,
                            child: Text(religionItem),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => religion = val ?? ''),
                validator:
                    (val) =>
                        val == null || val.isEmpty ? 'Select Religion' : null,
                dropdownColor: AppColors.white,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: addressController,
                focusNode: _focusNodes[6],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration(
                  'Address',
                  _focusNodes[6],
                ),
                maxLines: 1,
                validator:
                    (val) =>
                        val!.isEmpty
                            ? 'Address cannot be empty'
                            : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: willController,
                focusNode: _focusNodes[7],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration('Will', _focusNodes[7]),
                validator:
                    (val) => val!.isEmpty ? 'Will cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: fixedWishesController,
                focusNode: _focusNodes[8],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration(
                  'Fixed Wishes',
                  _focusNodes[8],
                ),
                validator:
                    (val) =>
                        val!.isEmpty ? 'Fixed Wishes cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: organDonation.isNotEmpty ? organDonation : null,
                focusNode: _focusNodes[9],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration(
                  'Organ Donation',
                  _focusNodes[9],
                ),
                items:
                    organs
                        .map(
                          (organ) => DropdownMenuItem(
                            value: organ,
                            child: Text(organ),
                          ),
                        )
                        .toList(),
                onChanged:
                    (val) => setState(() => organDonation = val ?? 'None'),
                validator:
                    (val) =>
                        val == null || val.isEmpty
                            ? 'Select Organ Donation'
                            : null,
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
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      'All input must be true',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: AppColors.white,
                      ),
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
                      horizontal: 10,
                      vertical: 15,
                    ),
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
        body: _buildForm(),
      ),
    );
  }
}
