// ignore_for_file: avoid_print

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/services/database.dart';

class PatientInfo extends StatefulWidget {
  const PatientInfo({super.key, required this.currentUserId});
  final String currentUserId;

  @override
  State<PatientInfo> createState() => _PatientInfoState();
}

class _PatientInfoState extends State<PatientInfo> {
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _imagePicker = ImagePicker();
  File? _profileImage;
  String? _profileImageUrl;
  DateTime? birthday;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> patientData = {}; // Initialize as an empty map

  bool isLoading = true;
  bool hasError = false;

  // Focus nodes for form fields
  final List<FocusNode> _focusNodes = List.generate(11, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _fetchPatientData(widget.currentUserId);
  }

  Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      // Get a reference to the storage bucket and file
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('patient_profile_pictures')
          .child('$userId.jpg');

      // Upload the file
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg', // Explicitly specify the file type
        ),
      );

      // Wait for the upload to complete and get the download URL
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl; // Return the URL
    } catch (e) {
      // Catch specific Firebase errors if needed
      throw Exception("Error uploading profile image: $e");
    }
  }

  // Method to fetch patient data
  Future<void> _fetchPatientData(String userId) async {
    try {
      var data = await DatabaseService().getPatientData(userId);
      debugPrint("Patient Info Current user: $userId");

      setState(() {
        // If data is null or empty, handle accordingly
        patientData = data ?? {}; // Ensure data is always not null
        isLoading = false;
        hasError = false; // Reset error state if data is fetched successfully
      });

      // Debug the patient data
      debugPrint("Fetched Patient Data: $patientData");

      // If patientData is not empty, show the patient info card
      if (patientData.isNotEmpty) {
        setState(() {
          isLoading = false; // Stop the loading spinner
        });
      } else {
        // If patientData is empty, show the form to add patient data
        setState(() {
          isLoading = false; // Stop the loading spinner
          // You can explicitly set hasError to false if you want to indicate the form should be shown
          hasError = false;
        });
      }
    } catch (e) {
      // Handle error
      setState(() {
        isLoading = false;
        hasError = true; // Indicate an error if fetching fails
      });
      print("Error fetching patient data: $e");
    }
  }

  @override
  void dispose() {
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final XFile? pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
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

  // Form submission logic
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final nameRegExp =
          RegExp(r"^[\p{L}\s]+(?:\.\s?[\p{L}]+)*$", unicode: true);

      // Validate name fields
      if (firstNameController.text.trim().isEmpty ||
          !nameRegExp.hasMatch(firstNameController.text.trim())) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid first name.')));
        return;
      }
      if (middleNameController.text.trim().isNotEmpty &&
          !nameRegExp.hasMatch(middleNameController.text.trim())) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid middle name.')));
        return;
      }
      if (lastNameController.text.trim().isEmpty ||
          !nameRegExp.hasMatch(lastNameController.text.trim())) {
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

      // Get the profile image URL (use a placeholder or empty string if no image is picked)
      String profileImageUrl = _profileImageUrl ?? '';
      if (_profileImage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Uploading profile image...')));
        try {
          String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
          profileImageUrl = await uploadProfileImage(
            userId: userId,
            file: _profileImage!,
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload profile image.')));
          return;
        }
      }

      // Validate Gender
      if (gender.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select your gender.')));
        return;
      }

      // Validate Religion
      if (religion.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select your religion.')));
        return;
      }

      // Validate Will
      if (willController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Will cannot be empty.')));
        return;
      }

      // Validate Fixed Wishes
      if (fixedWishesController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fixed Wishes cannot be empty.')));
        return;
      }

      // Validate Organ Donation
      if (organDonation.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Please select organ donation preference.')));
        return;
      }

      try {
        // Call the addPatientData function from DatabaseService
        await DatabaseService().addPatientData(
          uid: widget.currentUserId,
          firstName: firstNameController.text,
          lastName: lastNameController.text,
          middleName: middleNameController.text,
          age: _calculateAge(birthday),
          gender: gender,
          religion: religion,
          will: willController.text,
          fixedWishes: fixedWishesController.text,
          organDonation: organDonation,
          profileImageUrl: profileImageUrl,
          birthday: birthday,
        );

        // Display success SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient data submitted successfully!')),
        );

        // Re-fetch patient data after successful submission
        await _fetchPatientData(widget.currentUserId);
      } catch (e) {
        // Handle any errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting patient data: $e')),
        );
      }
    }
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
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
                ? _buildErrorWidget()
                : patientData
                        .isEmpty // Check if patientData is empty instead of null
                    ? _buildForm() // If no patient data, show the form
                    : _buildPatientInfoCard(
                        patientData), // If patient data exists, show the info card
      ),
    );
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
                          ? FileImage(_profileImage!)
                          : (_profileImageUrl != null &&
                                  _profileImageUrl!.isNotEmpty
                              ? NetworkImage(_profileImageUrl!)
                              : AssetImage(
                                  'lib/assets/images/shared/placeholder.png')),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.blackTransparent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _pickProfileImage,
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
              ),

              const SizedBox(height: 10),
              const Divider(thickness: 1.0),
              const SizedBox(height: 10),

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

  Widget _buildPatientInfoCard(Map<String, dynamic> patientData) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 75,
              backgroundImage: patientData['profileImageUrl'] != null &&
                      patientData['profileImageUrl'].isNotEmpty
                  ? NetworkImage(patientData['profileImageUrl'])
                      as ImageProvider
                  : const AssetImage(
                      'lib/assets/images/shared/placeholder.png'),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    '${patientData['firstName']} ${patientData['middleName']} ${patientData['lastName']}',
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileInfoSection(
                  'Age', patientData['age']?.toString() ?? 'N/A'),
              _buildProfileInfoSection(
                'Birthday',
                patientData['birthday'] != null
                    ? formatDate(patientData[
                        'birthday']) // Handle both String and Timestamp
                    : '',
              ),
              _buildProfileInfoSection(
                  'Gender', patientData['gender'] ?? 'N/A'),
              _buildProfileInfoSection(
                  'Religion', patientData['religion'] ?? 'N/A'),
              _buildProfileInfoSection('Will', patientData['will'] ?? 'N/A'),
              _buildProfileInfoSection(
                  'Fixed Wishes', patientData['fixedWishes'] ?? 'N/A'),
              _buildProfileInfoSection(
                  'Organ Donation', patientData['organDonation'] ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Text(
        'Error fetching data. Please try again later.',
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildProfileInfoSection(String header, String data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Colors.grey,
            ),
          ),
          Text(
            data,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.normal,
              fontFamily: 'Inter',
              color: Colors.black,
            ),
          ),
        ],
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
}
