import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/models/my_user.dart';

class UserDataForm extends StatefulWidget {
  final UserData? userData;
  final UserDataCallback onButtonPressed;
  final bool isSignUp;

  const UserDataForm({
    super.key,
    required this.onButtonPressed,
    required this.userData,
    this.isSignUp = true,
  });

  @override
  UserDataFormState createState() => UserDataFormState();
}

typedef UserDataCallback = void Function({
required String firstName,
required String lastName,
required String middleName,
required String phoneNumber,
required String sex,
required String birthMonth,
required String birthDay,
required String birthYear,
required String address,
});

class UserDataFormState extends State<UserDataForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController middleNameController;
  late TextEditingController phoneNumberController;
  late String sex;
  late String birthMonth;
  late String birthDay;
  late String birthYear;
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
    sex = widget.userData?.sex ?? '';
    birthMonth = widget.userData?.birthMonth ?? '';
    birthDay = widget.userData?.birthDay ?? '';
    birthYear = widget.userData?.birthYear ?? '';
    addressController =
        TextEditingController(text: widget.userData?.address ?? '');
    birthdayController = TextEditingController(
      text: (widget.userData?.birthMonth != null &&
          widget.userData?.birthDay != null &&
          widget.userData?.birthYear != null)
          ? '${widget.userData!.birthMonth} ${widget.userData!.birthDay}, ${widget.userData!.birthYear}'
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
    firstNameFocusNode.dispose();
    lastNameFocusNode.dispose();
    middleNameFocusNode.dispose();
    phoneNumberFocusNode.dispose();
    addressFocusNode.dispose();
    genderFocusNode.dispose();
    birthdayController.dispose();
    birthdayFocusNode.dispose();

    super.dispose();
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

  int _getMonthNumber(String monthName) {
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
    return monthNames.indexOf(monthName) + 1;
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate;
    if (birthYear.isNotEmpty && birthMonth.isNotEmpty && birthDay.isNotEmpty) {
      int year = int.parse(birthYear);
      int month = _getMonthNumber(birthMonth);
      int day = int.parse(birthDay);
      initialDate = DateTime(year, month, day);
    } else {
      initialDate = DateTime.now();
    }

    // Use a custom theme for the date picker
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: AppColors.white, // Set background color
            colorScheme: ColorScheme.light(
              primary: AppColors.neon, // Header background color
              onPrimary: AppColors.white, // Header text color
              onSurface: AppColors.black, // Text color in the calendar
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        birthMonth = getMonthName(picked.month);
        birthDay = picked.day.toString().padLeft(2, '0');
        birthYear = picked.year.toString();
        birthdayController.text = '$birthMonth $birthDay, $birthYear';
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
        borderSide: BorderSide(
          color: AppColors.neon,
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: focusNode.hasFocus ? AppColors.neon : AppColors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss the keyboard when tapping outside of the text fields
        FocusScope.of(context).unfocus();
      },
      child: Form(
        key: _formKey,
        child: SizedBox(
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: firstNameController,
                  focusNode: firstNameFocusNode,
                  decoration: _inputDecoration('First Name', firstNameFocusNode),
                  validator: (val) => val!.isEmpty ? 'Enter First Name' : null,
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: middleNameController,
                  focusNode: middleNameFocusNode,
                  decoration:
                  _inputDecoration('Middle Name', middleNameFocusNode),
                  validator: (val) => val!.isEmpty ? 'Enter Middle Name' : null,
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: lastNameController,
                  focusNode: lastNameFocusNode,
                  decoration: _inputDecoration('Last Name', lastNameFocusNode),
                  validator: (val) => val!.isEmpty ? 'Enter Last Name' : null,
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: phoneNumberController,
                  focusNode: phoneNumberFocusNode,
                  decoration:
                  _inputDecoration('Phone Number', phoneNumberFocusNode),
                  validator: (val) => val!.isEmpty ? 'Enter Phone Number' : null,
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: birthdayController,
                  focusNode: birthdayFocusNode,
                  readOnly: true,
                  decoration: _inputDecoration('Birthday', birthdayFocusNode).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.calendar_today,
                        color: birthdayFocusNode.hasFocus ? AppColors.neon : AppColors.black,
                      ),
                      onPressed: () => _selectDate(context), // Open the date picker
                    ),
                  ),
                  onTap: () => _selectDate(context),
                  validator: (val) => val!.isEmpty ? 'Enter your Birthday' : null,
                ),
                const SizedBox(height: 20.0),
                DropdownButtonFormField<String>(
                  value: sex,
                  focusNode: genderFocusNode,
                  decoration: _inputDecoration('Gender', genderFocusNode),
                  dropdownColor: AppColors.white,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Inter',
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
                      sex = newValue!;
                    });
                  },
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: genderFocusNode.hasFocus
                        ? AppColors.neon
                        : AppColors.black, // Icon color based on focus
                  ),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: addressController,
                  focusNode: addressFocusNode,
                  decoration: _inputDecoration('Address', addressFocusNode),
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
                        sex: sex,
                        birthMonth: birthMonth,
                        birthDay: birthDay,
                        birthYear: birthYear,
                        address: addressController.text,
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                    backgroundColor: AppColors.neon,
                  ),
                  child: Text(
                    widget.isSignUp ? 'Sign Up' : 'Update Profile',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.white,
                    ),
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