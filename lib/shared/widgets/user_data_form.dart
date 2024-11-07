import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/models/my_user.dart';

class UserDataForm extends StatefulWidget {
  final UserData? userData;
  final UserDataCallback onButtonPressed;
  final bool isSignUp;
  final bool newUser; // Add the newUser flag here

  const UserDataForm({
    super.key,
    required this.onButtonPressed,
    required this.userData,
    this.isSignUp = true,
    required this.newUser, // Ensure newUser is passed in constructor
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onButtonPressed(
                      firstName: firstNameController.text,
                      lastName: lastNameController.text,
                      middleName: middleNameController.text,
                      phoneNumber: phoneNumberController.text,
                      gender: gender,
                      birthday: birthday,
                      address: addressController.text,
                    );
                  }
                },
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
