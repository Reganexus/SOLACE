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

  const UserDataForm({
    super.key,
    required this.onButtonPressed,
    required this.userData,
    this.isSignUp = true,
    required this.newUser,
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
});

class UserDataFormState extends State<UserDataForm> {
  final _formKey = GlobalKey<FormState>();


  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController middleNameController;
  late TextEditingController phoneNumberController;
  late TextEditingController addressController;
  late TextEditingController birthdayController;

  File? _profileImage;
  String? _profileImageUrl;
  String gender = '';
  DateTime? birthday;

  final _focusNodes = List.generate(7, (_) => FocusNode());
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

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
    _profileImageUrl = widget.userData?.profileImageUrl;

    // Add focus listeners
    _focusNodes[0].addListener(() => setState(() {}));
    _focusNodes[1].addListener(() => setState(() {}));
    _focusNodes[2].addListener(() => setState(() {}));
    _focusNodes[3].addListener(() => setState(() {}));
    _focusNodes[4].addListener(() => setState(() {}));
    _focusNodes[5].addListener(() => setState(() {}));
    _focusNodes[6].addListener(() => setState(() {}));
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
    final DateTime initialDate = birthday ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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

      // Fetch the current user's data
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final currentPhoneNumber = currentUserDoc.data()?['phoneNumber'];

      // If the input matches the current user's phone number, consider it valid
      if (phoneNumber == currentPhoneNumber) return true;

      // Check if any other user has the same phone number
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      // If there's any document with the same phone number, it's not unique
      return snapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking phone number uniqueness: $e');
      return false; // Fail-safe: Assume it's not unique if an error occurs
    }
  }


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if phone number is unique
    final phoneNumber = phoneNumberController.text.trim();
    final isUnique = await _isPhoneNumberUnique(phoneNumber);

    if (!isUnique) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number already exists. Please use a different one.'),
        ),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    String? profileImageUrl = _profileImageUrl;

    if (_profileImage != null) {
      // Show snackbar while uploading the image
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 24, // Set the desired width
                height: 24, // Set the desired height
                child: CircularProgressIndicator(
                  color: AppColors.neon,
                  strokeWidth: 4.0, // Optional: Adjust the thickness of the indicator
                ),
              ),
              SizedBox(width: 15),
              Text('Uploading profile image...'),
            ],
          ),
          duration: Duration(minutes: 1), // Long duration to ensure visibility during upload
        ),
      );


      try {
        profileImageUrl = await DatabaseService.uploadProfileImage(
          userId: userId,
          file: _profileImage!,
        );

        // Dismiss the snackbar once the upload is successful
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      } catch (e) {
        // Show error snackbar if the upload fails
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile image. Please try again.')),
        );
        return;
      }
    }

    await widget.onButtonPressed(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      middleName: middleNameController.text.trim(),
      phoneNumber: phoneNumber,
      gender: gender,
      birthday: birthday,
      address: addressController.text.trim(),
      profileImageUrl: profileImageUrl ?? '',
    );

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated successfully!')),
    );
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
                          : (_profileImageUrl != null
                                  ? NetworkImage(_profileImageUrl!)
                                  : AssetImage(
                                      'lib/assets/images/shared/placeholder.png'))
                              as ImageProvider,
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
                validator: (val) =>
                    val!.isEmpty ? 'Phone number cannot be empty' : null,
              ),
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
                decoration: _buildInputDecoration('Birthday', _focusNodes[4]),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: gender.isNotEmpty ? gender : null,
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
              TextFormField(
                controller: addressController,
                focusNode: _focusNodes[6],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration('Address', _focusNodes[6]),
                validator: (val) =>
                    val!.isEmpty ? 'Address cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _submitForm,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  backgroundColor: AppColors.neon,
                ),
                child: Text(
                  'Update Profile',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.white,
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
