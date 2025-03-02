// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Ensure Firebase Database is imported
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';

class UserDataForm extends StatefulWidget {
  final UserData? userData;
  final UserDataCallback onButtonPressed;
  final bool isSignUp;
  final bool newUser;
  final bool isVerified; // New field
  final int age;
  final UserRole userRole;

  const UserDataForm({
    super.key,
    this.isSignUp = true,
    required this.onButtonPressed,
    required this.userData,
    required this.userRole,
    required this.newUser,
    required this.isVerified,
    required this.age,
  });

  @override
  UserDataFormState createState() => UserDataFormState();
}

typedef UserDataCallback = Future<void> Function({
  required String firstName,
  required String lastName,
  required String middleName,
  required String phoneNumber,
  required String gender,
  required DateTime? birthday,
  required String address,
  required String profileImageUrl,
  required String religion,
  required int age,
});

class UserDataFormState extends State<UserDataForm> {
  final _formKey = GlobalKey<FormState>();

  late List<FocusNode> _focusNodes;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController middleNameController;
  late TextEditingController phoneNumberController;
  late TextEditingController addressController;
  late TextEditingController birthdayController;

  File? _profileImage;
  String? _profileImageUrl;
  String gender = '';
  String religion = '';
  DateTime? birthday;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    int focusNodeCount = 8; // Base fields (7 common + 1 address)

    // Initialize focus nodes with correct count
    _focusNodes = List.generate(focusNodeCount, (_) => FocusNode());
    debugPrint('Initialized focus nodes: ${_focusNodes.length}'); // Debug log

    _focusNodes = List.generate(focusNodeCount, (_) => FocusNode());
    debugPrint('Focus nodes count: ${_focusNodes.length}');

    firstNameController =
        TextEditingController(text: widget.userData?.firstName ?? '');
    lastNameController =
        TextEditingController(text: widget.userData?.lastName ?? '');
    middleNameController =
        TextEditingController(text: widget.userData?.middleName ?? '');
    phoneNumberController =
        TextEditingController(text: widget.userData?.phoneNumber ?? '');
    addressController =
        TextEditingController(text: widget.userData?.address ?? '');
    birthday = widget.userData?.birthday;
    birthdayController = TextEditingController(
      text: birthday != null
          ? '${_getMonthName(birthday!.month)} ${birthday!.day}, ${birthday!.year}'
          : '',
    );
    gender = widget.userData?.gender ?? '';
    religion = widget.userData?.religion ?? '';
    debugPrint(
        'Religion value: $religion'); // Check if it's populated correctly

    _profileImageUrl = widget.userData?.profileImageUrl;

    // Add focus listeners
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    firstNameController.dispose();
    lastNameController.dispose();
    middleNameController.dispose();
    phoneNumberController.dispose();
    addressController.dispose();
    birthdayController.dispose();

    super.dispose();
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
    'Other', // Add 'Other' option
  ];

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
    final DateTime minDate = DateTime(today.year - 120); // Set 120 years ago as the minimum
    final DateTime maxDate = DateTime(today.year - 1);  // Ensure user is at least 1 year old

    final DateTime initialDate = birthday ?? maxDate;  // Default to maxDate if birthday is null

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: maxDate,  // Allow selecting up to the current date minus 1 year
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
        '${_getMonthName(picked.month)} ${picked.day}, ${picked.year}';
      });
    }
  }


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

  Future<bool> _isPhoneNumberUnique(String phoneNumber) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      // Check across all role-based collections
      List<String> roles = [
        'admin',
        'doctor',
        'caregiver',
        'patient',
        'unregistered'
      ];
      String? currentPhoneNumber;

      for (String role in roles) {
        final String collectionName = role;

        // Fetch the current user's document from the collection
        final userDoc = await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(userId)
            .get();

        if (userDoc.exists) {
          currentPhoneNumber = userDoc.data()?['phoneNumber'];
          break; // Stop searching once the user's document is found
        }
      }

      // If the current user's phone number matches the input, it's valid
      if (phoneNumber == currentPhoneNumber) return true;

      // Check if the phone number exists in any collection
      for (String role in roles) {
        final String collectionName = role;

        final snapshot = await FirebaseFirestore.instance
            .collection(collectionName)
            .where('phoneNumber', isEqualTo: phoneNumber)
            .get();

        // If the phone number is found, it's not unique
        if (snapshot.docs.isNotEmpty) return false;
      }

      // If no matching phone number is found in any collection, it's unique
      return true;
    } catch (e) {
      debugPrint('Error checking phone number uniqueness: $e');
      return false; // Fail-safe: Assume it's not unique if an error occurs
    }
  }

  Future<void> _submitForm() async {
    // Assuming `userRole` is passed as a property

    final nameRegExp = RegExp(r"^[\p{L}\s]+(?:\.\s?[\p{L}]+)*$", unicode: true);

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

    // Phone number validation
    final phoneNumber = phoneNumberController.text.trim();
    final phoneRegExp = RegExp(r'^09\d{9}$');
    if (phoneNumber.isEmpty || !phoneRegExp.hasMatch(phoneNumber)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid phone number.')));
      return;
    }

    final isUnique = await _isPhoneNumberUnique(phoneNumber);
    if (!isUnique) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone number already exists.')));
      return;
    }

    if (birthday == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select a birthday.')));
      return;
    }

    final age = _calculateAge(birthday);

    if (gender.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select your gender.')));
      return;
    }

    if (religion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select your religion.')));
      return;
    }

    if (addressController.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Address must be at least 5 characters long.')));
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    String? profileImageUrl = _profileImageUrl;

    if (_profileImage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Uploading profile image...')));

      try {
        profileImageUrl = await DatabaseService.uploadProfileImage(
          userId: userId,
          file: _profileImage!,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload profile image.')));
        return;
      }
    }

    await widget.onButtonPressed(
      firstName: capitalizeEachWord(firstNameController.text.trim()),
      lastName: capitalizeEachWord(lastNameController.text.trim()),
      middleName: capitalizeEachWord(middleNameController.text.trim()),
      phoneNumber: phoneNumber,
      gender: gender,
      birthday: birthday,
      address: addressController.text.trim(),
      profileImageUrl: profileImageUrl ?? '',
      religion: religion,
      age: age,
    );
  }

// Helper method to calculate age
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                        shape: BoxShape.circle, // Makes the container circular
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
              TextFormField(
                controller: phoneNumberController,
                focusNode: _focusNodes[3],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration:
                    _buildInputDecoration('Phone Number', _focusNodes[3]),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Phone number cannot be empty';
                  }
                  if (!RegExp(r'^09\d{9}$').hasMatch(val)) {
                    return 'Invalid Phone Number';
                  }
                  return null;
                },
              ),

              // Birthday Field
              const SizedBox(height: 20),
              TextFormField(
                controller: birthdayController,
                focusNode: _focusNodes[4],
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
                    color: _focusNodes[4].hasFocus
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
                    color: _focusNodes[4].hasFocus
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
                value: gender.isNotEmpty &&
                        ['Male', 'Female', 'Other'].contains(gender)
                    ? gender
                    : null,
                focusNode: _focusNodes[5],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration('Gender', _focusNodes[5]),
                items: ['Male', 'Female', 'Other']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value,
                          style:
                              TextStyle(color: AppColors.black, fontSize: 16),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => gender = val ?? ''),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Select Gender' : null,
                dropdownColor: AppColors.white,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: religion.isNotEmpty && religions.contains(religion)
                    ? religion
                    : null,
                focusNode: _focusNodes[6],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration('Religion', _focusNodes[6]),
                items: religions
                    .map(
                      (religionItem) => DropdownMenuItem(
                        value: religionItem,
                        child: Text(
                          religionItem,
                          style:
                              TextStyle(color: AppColors.black, fontSize: 16),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() {
                  religion = val ?? ''; // Update the selected religion value
                }),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Select Religion' : null,
                dropdownColor: AppColors.white,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: addressController,
                focusNode: _focusNodes[7],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration('Address', _focusNodes[7]),
                validator: (val) =>
                    val!.isEmpty ? 'Address cannot be empty' : null,
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
                    'Update Profile',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
