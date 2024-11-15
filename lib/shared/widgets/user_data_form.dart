// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/models/my_user.dart';

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

typedef UserDataCallback = void Function({
  required String firstName,
  required String lastName,
  required String middleName,
  required String phoneNumber,
  required String gender,
  required DateTime? birthday,
  required String address,
});

class UserDataFormState extends State<UserDataForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController middleNameController;
  late TextEditingController phoneNumberController;
  late String gender;
  late DateTime? birthday;
  late TextEditingController addressController;
  late TextEditingController birthdayController;

  final firstNameFocusNode = FocusNode();
  final lastNameFocusNode = FocusNode();
  final middleNameFocusNode = FocusNode();
  final phoneNumberFocusNode = FocusNode();
  final addressFocusNode = FocusNode();
  final genderFocusNode = FocusNode();
  final birthdayFocusNode = FocusNode();

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
    gender = widget.userData?.gender ?? '';
    birthday = widget.userData?.birthday;
    addressController =
        TextEditingController(text: widget.userData?.address ?? '');

    birthdayController = TextEditingController(
      text: birthday != null
          ? '${getMonthName(birthday!.month)} ${birthday!.day}, ${birthday!.year}'
          : '',
    );

    // Add listeners to trigger rebuild on focus change
    firstNameFocusNode.addListener(() => setState(() {}));
    lastNameFocusNode.addListener(() => setState(() {}));
    middleNameFocusNode.addListener(() => setState(() {}));
    phoneNumberFocusNode.addListener(() => setState(() {}));
    addressFocusNode.addListener(() => setState(() {}));
    genderFocusNode.addListener(() => setState(() {}));
    birthdayFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    middleNameController.dispose();
    phoneNumberController.dispose();
    addressController.dispose();
    birthdayController.dispose();

    firstNameFocusNode.dispose();
    lastNameFocusNode.dispose();
    middleNameFocusNode.dispose();
    phoneNumberFocusNode.dispose();
    addressFocusNode.dispose();
    genderFocusNode.dispose();
    birthdayFocusNode.dispose();

    super.dispose();
  }

  String? _nameValidation(String value) {
    // Check if the field contains only letters and spaces, including special characters
    final regex = RegExp(r'^[\p{L}\s]+$', unicode: true);
    if (value.isEmpty) {
      return 'This field cannot be empty';
    }
    if (!regex.hasMatch(value)) {
      return 'No numbers or symbols allowed';
    }
    return null; // Valid input returns null
  }

  String? _lastNameValidation(String value) {
    // Allow "Sr." or "Jr." suffix for Last Name, but no other symbols or numbers
    final regex = RegExp(r'^[\p{L}\s\.]+$', unicode: true);
    if (value.isEmpty) {
      return 'This field cannot be empty';
    }
    if (!regex.hasMatch(value)) {
      return 'No numbers or symbols allowed';
    }
    return null; // Valid input returns null
  }

  String? _phoneNumberValidation(String value) {
    // Validate for 11-digit phone number, starting with "09"
    final regex = RegExp(r'^\d{11}$');
    if (value.isEmpty) {
      return 'Phone number cannot be empty';
    }
    if (!regex.hasMatch(value)) {
      return 'Phone number must be 11 digits';
    }
    return null; // Valid input returns null
  }

  String getMonthName(int month) {
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
            dialogBackgroundColor: AppColors.white,
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
            '${getMonthName(picked.month)} ${picked.day}, ${picked.year}';
      });
    }
  }

  Future<bool> _isPhoneNumberAlreadyExist(String phoneNumber) async {
    try {
      // Query Firestore to check if the phone number exists
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users') // Replace with your collection name
          .where('phoneNumber',
              isEqualTo: phoneNumber) // Query the phoneNumber field
          .limit(1) // Limit the result to 1 document
          .get();

      // If the query returns any document, it means the phone number exists
      return result.docs.isNotEmpty;
    } catch (e) {
      print("Error checking phone number existence: $e");
      return false; // Return false if there is an error
    }
  }

  Future<String?> getCurrentPhoneNumber() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;

      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users') // Your collection name
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data[
            'phoneNumber']; // Replace 'phoneNumber' with the correct field
      }
    } catch (e) {
      print("Error fetching phone number: $e");
    }
    return null;
  }

  // In UserDataForm.dart
  Future<void> submitForm() async {
    // Remove trailing spaces and collect form data
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final middleName = middleNameController.text.trim();
    final phoneNumber = phoneNumberController.text.trim();
    final gender = this.gender.trim();
    final birthday = this.birthday;
    final address = addressController.text.trim();

    // Collect validation errors in a list
    List<String> errors = [];

    // Validate all fields manually
    if (firstName.isEmpty) errors.add('First Name cannot be empty');
    if (lastName.isEmpty) errors.add('Last Name cannot be empty');
    if (middleName.isEmpty) errors.add('Middle Name cannot be empty');
    if (phoneNumber.isEmpty) errors.add('Phone Number cannot be empty');
    if (!RegExp(r'^\d{11}$').hasMatch(phoneNumber)) {
      errors.add('Phone number must be 11 digits');
    }
    if (gender.isEmpty) errors.add('Gender cannot be empty');
    if (address.isEmpty) errors.add('Address cannot be empty');
    if (birthday == null) errors.add('Birthday cannot be empty');

    // If there are validation errors, show them all in one SnackBar
    if (errors.isNotEmpty) {
      _showCustomSnackBar(
        message: errors.join(', '),
        backgroundColor: Colors.red,
        textColor: AppColors.white,
      );
      return; // Return early to prevent further processing
    }

    // Fetch current user's phone number from Firestore (skip if it's the same as the current phone number)
    String? currentPhoneNumber = await getCurrentPhoneNumber();

    if (currentPhoneNumber != null && phoneNumber == currentPhoneNumber) {
      // No need to check the phone number again if it's the same
      widget.onButtonPressed(
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        phoneNumber: phoneNumber,
        gender: gender,
        birthday: birthday,
        address: address,
      );
      _showCustomSnackBar(
        message: 'Profile updated successfully!',
        backgroundColor: AppColors.neon,
        textColor: AppColors.white,
      );
      return;
    }

    // Check if the phone number already exists in the database
    if (await _isPhoneNumberAlreadyExist(phoneNumber)) {
      _showCustomSnackBar(
        message: 'Phone number already exists!',
        backgroundColor: Colors.red,
        textColor: AppColors.white,
      );
      return;
    }

    // If everything is valid, call the callback function
    widget.onButtonPressed(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      phoneNumber: phoneNumber,
      gender: gender,
      birthday: birthday,
      address: address,
    );

    // Show success message
    _showCustomSnackBar(
      message: 'Profile updated successfully!',
      backgroundColor: AppColors.neon,
      textColor: AppColors.white,
    );
  }

// Custom function to show SnackBar at the top of the screen
  void _showCustomSnackBar({
    required String message,
    required Color backgroundColor,
    required Color textColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.0), // Adjust the margin to move it to the top
      ),
    );
  }


  InputDecoration _inputDecoration(String label, FocusNode focusNode) {
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
        color: AppColors.black, // Change label color if invalid
      ),
    );
  }

// Helper function to check if the field is invalid

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: firstNameController,
                focusNode: firstNameFocusNode,
                decoration: _inputDecoration('First Name', firstNameFocusNode),
                validator: (val) => widget.newUser && val!.isEmpty
                    ? 'Enter First Name'
                    : _nameValidation(val!),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: middleNameController,
                focusNode: middleNameFocusNode,
                decoration:
                    _inputDecoration('Middle Name', middleNameFocusNode),
                validator: (val) => widget.newUser && val!.isEmpty
                    ? 'Enter Middle Name'
                    : _nameValidation(val!),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: lastNameController,
                focusNode: lastNameFocusNode,
                decoration: _inputDecoration('Last Name', lastNameFocusNode),
                validator: (val) => widget.newUser && val!.isEmpty
                    ? 'Enter Last Name'
                    : _lastNameValidation(val!),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: phoneNumberController,
                focusNode: phoneNumberFocusNode,
                decoration:
                    _inputDecoration('Phone Number', phoneNumberFocusNode),
                validator: (val) => widget.newUser && val!.isEmpty
                    ? 'Enter Phone Number'
                    : _phoneNumberValidation(val!),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: birthdayController,
                focusNode: birthdayFocusNode,
                readOnly: true,
                decoration:
                    _inputDecoration('Birthday', birthdayFocusNode).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.calendar_today,
                      color: birthdayFocusNode.hasFocus
                          ? AppColors.neon
                          : AppColors.black,
                    ),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                onTap: () => _selectDate(context),
                validator: (val) => widget.newUser && val!.isEmpty
                    ? 'Enter your Birthday'
                    : null,
              ),
              const SizedBox(height: 20.0),
              DropdownButtonFormField<String>(
                value:
                    gender.isNotEmpty ? gender : null, // Set to null if empty
                focusNode: genderFocusNode,
                decoration: _inputDecoration('Gender', genderFocusNode),
                dropdownColor: AppColors.white,
                style: TextStyle(
                  fontSize: 16.0,
                  color: AppColors.black,
                ),
                items: ['Male', 'Female', 'Other'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    gender =
                        newValue!; // This will only execute if newValue is not null
                  });
                },
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: genderFocusNode.hasFocus
                      ? AppColors.neon
                      : AppColors.black,
                ),
                validator: (val) =>
                    widget.newUser && (val == null || val.isEmpty)
                        ? 'Select Gender'
                        : null,
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: addressController,
                focusNode: addressFocusNode,
                decoration: _inputDecoration('Address', addressFocusNode),
                validator: (val) =>
                    widget.newUser && val!.isEmpty ? 'Enter Address' : null,
              ),
              const SizedBox(height: 20.0),
              TextButton(
                onPressed: submitForm,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  backgroundColor: AppColors.neon,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
