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
  late TextEditingController addressController; // Add this line

  @override
  void initState() {
    super.initState();

    firstNameController = TextEditingController(text: widget.userData?.firstName ?? '');
    lastNameController = TextEditingController(text: widget.userData?.lastName ?? '');
    middleNameController = TextEditingController(text: widget.userData?.middleName ?? '');
    phoneNumberController = TextEditingController(text: widget.userData?.phoneNumber ?? '');
    sex = widget.userData?.sex ?? '';
    birthMonth = widget.userData?.birthMonth ?? '';
    birthDay = widget.userData?.birthDay ?? '';
    birthYear = widget.userData?.birthYear ?? '';
    addressController = TextEditingController(text: widget.userData?.address ?? ''); // Ensure address is set
  }

  @override
  void dispose() {
    // Dispose the controllers to free up resources
    firstNameController.dispose();
    lastNameController.dispose();
    middleNameController.dispose();
    phoneNumberController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: firstNameController,
            decoration: InputDecoration(labelText: 'First Name', fillColor: AppColors.gray, filled: true),
            onChanged: (val) => firstNameController.text = val,
            validator: (val) => val!.isEmpty ? 'Enter First Name' : null,
          ),
          TextFormField(
            controller: lastNameController,
            decoration: InputDecoration(labelText: 'Last Name', fillColor: AppColors.gray, filled: true),
            onChanged: (val) => lastNameController.text = val,
            validator: (val) => val!.isEmpty ? 'Enter Last Name' : null,
          ),
          TextFormField(
            controller: middleNameController,
            decoration: InputDecoration(labelText: 'Middle Name', fillColor: AppColors.gray, filled: true),
            onChanged: (val) => middleNameController.text = val,
            validator: (val) => val!.isEmpty ? 'Enter Middle Name' : null,
          ),
          TextFormField(
            controller: phoneNumberController,
            decoration: InputDecoration(labelText: 'Phone Number', fillColor: AppColors.gray, filled: true),
            onChanged: (val) => phoneNumberController.text = val,
            validator: (val) => val!.isEmpty ? 'Enter Phone Number' : null,
          ),
          DropdownButtonFormField<String>(
            value: sex,
            decoration: InputDecoration(labelText: 'Gender', fillColor: AppColors.gray, filled: true),
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
          ),
          // Address input field
          TextFormField(
            controller: addressController, // Use the controller
            decoration: InputDecoration(
              labelText: 'Address',
              fillColor: AppColors.gray,
              filled: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              addressController.text = value; // Save the address input
            },
          ),
          // Repeat for birthMonth, birthDay, and birthYear dropdowns...

          ElevatedButton(
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
            child: Text(widget.isSignUp ? 'Sign Up' : 'Update Profile'),
          ),
        ],
      ),
    );
  }
}
