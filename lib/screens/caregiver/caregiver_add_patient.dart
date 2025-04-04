// ignore_for_file: avoid_print
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/error_handler.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/services/validator.dart';
import 'package:solace/shared/widgets/case_picker.dart';
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
  final AuthService _auth = AuthService();
  final LogService _logService = LogService();
  final DatabaseService _database = DatabaseService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> patientData = {};
  List<String> selectedCases = [];
  File? _profileImage;
  String? _profileImageUrl;
  DateTime? birthday;
  String gender = '';
  String religion = '';
  bool _isLoading = false;
  bool hasError = false;

  final List<FocusNode> _focusNodes = List.generate(13, (_) => FocusNode());
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController religionController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    newPatientId = FirebaseFirestore.instance.collection('patient').doc().id;
    debugPrint("Add patient id: $newPatientId");
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

  void _addCase(String caseItem) {
    setState(() {
      selectedCases.add(caseItem);
    });
  }

  void _removeCase(String caseItem) {
    setState(() {
      selectedCases.remove(caseItem);
    });
  }

  Future<File> getFileFromAsset(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${assetPath.split('/').last}');
    return await tempFile.writeAsBytes(byteData.buffer.asUint8List());
  }

  Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('patient_profile_pictures')
          .child('$userId.jpg');

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print("Image uploaded successfully: $downloadUrl");
      return downloadUrl;
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
          _profileImage = await getFileFromAsset(selectedImage);
        } else {
          _profileImage = File(selectedImage);
        }

        setState(() {
          _profileImageUrl = null;
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
      lastDate: maxDate,
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
        birthdayController.text = DateFormat("MMMM d, yyyy").format(birthday!);
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
        caseDescriptionController.text.trim().isNotEmpty &&
        addressController.text.trim().isNotEmpty &&
        birthday != null &&
        gender.isNotEmpty &&
        religion.isNotEmpty;
  }

  Future<void> _submitForm() async {
    final user = _auth.currentUserId;

    if (user == null) {
      showToast("User not authenticated.");
      return;
    }

    final role = await _database.fetchAndCacheUserRole(user); // Await here

    if (role == null) {
      showToast("User role not found.");
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUserId;
      if (user == null) {
        showToast('User is not authenticated');
        return;
      }

      final userId = newPatientId;
      if (userId == null) {
        showToast('Patient is null');
        return;
      }

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

      if (gender.isEmpty) {
        throw Exception('Please select your gender.');
      }
      if (religion.isEmpty) {
        throw Exception('Please select your religion.');
      }
      if (addressController.text.trim().isEmpty) {
        throw Exception('Address cannot be empty.');
      }
      if (caseDescriptionController.text.trim().isEmpty) {
        throw Exception('Case Description cannot be empty.');
      }

      // Add patient data with conditional tag
      await DatabaseService().addPatientData(
        uid: newPatientId,
        firstName: firstNameController.text.trim().capitalizeEachWord(),
        lastName: lastNameController.text.trim().capitalizeEachWord(),
        middleName: middleNameController.text.trim().capitalizeEachWord(),
        age: age,
        gender: gender,
        religion: religion,
        profileImageUrl: profileImageUrl,
        birthday: birthday,
        cases: selectedCases,
        caseDescription:
            caseDescriptionController.text.trim().capitalizeEachWord(),
        status: 'stable',
        address: addressController.text.trim().capitalizeEachWord(),
        tag: role == 'caregiver' ? [user.toString()] : <String>[],
      );

      final name =
          '${firstNameController.text.trim().capitalizeEachWord()} ${lastNameController.text.trim().capitalizeEachWord()}';

      await _logService.addLog(userId: user, action: "Added Patient $name");

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
      barrierDismissible: false,
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
                CasePickerWidget(
                  selectedCases: selectedCases,
                  onAddCase: _addCase,
                  onRemoveCase: _removeCase,
                ),
                const SizedBox(height: 10),

                CustomTextField(
                  controller: caseDescriptionController,
                  focusNode: _focusNodes[7],
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
                const SizedBox(height: 10),

                CustomTextField(
                  controller: firstNameController,
                  focusNode: _focusNodes[0],
                  labelText: 'First Name',
                  enabled: !_isLoading,
                  validator: (value) => Validator.name(value?.trim()),
                ),
                const SizedBox(height: 10),

                CustomTextField(
                  controller: middleNameController,
                  focusNode: _focusNodes[1],
                  labelText: 'Middle Name',
                  enabled: !_isLoading,
                  validator: (value) => Validator.name(value?.trim()),
                ),
                const SizedBox(height: 10),

                CustomTextField(
                  controller: lastNameController,
                  focusNode: _focusNodes[2],
                  labelText: 'Last Name',
                  enabled: !_isLoading,
                  validator: (value) => Validator.name(value?.trim()),
                ),
                const SizedBox(height: 10),

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

                const SizedBox(height: 10),

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
                const SizedBox(height: 10),

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
                const SizedBox(height: 10),

                CustomTextField(
                  controller: addressController,
                  focusNode: _focusNodes[6],
                  labelText: 'Address',
                  enabled: !_isLoading,
                  validator:
                      (val) => val!.isEmpty ? 'Address cannot be empty' : null,
                ),
                const SizedBox(height: 10),

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
