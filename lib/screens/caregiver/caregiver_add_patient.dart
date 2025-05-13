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
import 'package:solace/themes/loader.dart';
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
  String patientName = '';

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
    'Protestant',
    'Iglesia ni Cristo',
    'Aglipayan / Philippine Independent Church',
    'Islam',
    'Orthodox Christian',
    'Indigenous / Ancestral Beliefs',
    'Buddhism',
    'Hinduism',
    'Judaism',
    'Sikhism',
    'Taoism / Chinese Folk Religion',
    'Bahá’í Faith',
    'Spiritual but not religious',
    'Agnostic',
    'Atheist',
    'Prefer not to say',
  ];

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

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
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

      //     debugPrint("Image uploaded successfully: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      //     debugPrint("Error uploading image: $e");
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

        //         debugPrint("Selected image file path: ${_profileImage!.path}");
      } else {
        //         debugPrint('No image selected.');
      }
    } catch (e) {
      //       debugPrint('Error picking profile image: $e');
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

  Future<bool> _showConfirmationDialog(String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text('Confirm Update', style: Textstyle.subheader),
          content: Text(
            'Are you sure you want to add $name as patient?',
            style: Textstyle.body,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: Buttonstyle.buttonRed,
                    child: Text('Cancel', style: Textstyle.smallButton),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: Buttonstyle.buttonNeon,
                    child: Text('Confirm', style: Textstyle.smallButton),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    FocusScope.of(context).unfocus();

    final name =
        '${firstNameController.text.trim().capitalizeEachWord()} ${middleNameController.text.isNotEmpty ? '${middleNameController.text.trim().capitalizeEachWord()} ' : ''}${lastNameController.text.trim().capitalizeEachWord()}';

    setState(() {
      patientName = name;
      _isLoading = false;
    });

    final shouldProceed = await _showConfirmationDialog(patientName);
    if (!shouldProceed) return;

    setState(() => _isLoading = true);
    final user = _auth.currentUserId;

    if (user == null) {
      showToast("User not authenticated.", backgroundColor: AppColors.red);
      return;
    }

    final role = await _database.fetchAndCacheUserRole(user); // Await here

    if (role == null) {
      showToast("User role not found.", backgroundColor: AppColors.red);
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
        showToast('User is not authenticated', backgroundColor: AppColors.red);
        return;
      }

      final userId = newPatientId;
      if (userId == null) {
        showToast('Patient is null', backgroundColor: AppColors.red);
        return;
      }

      showToast("Submitting data. Please wait.");

      // Validate names
      if (Validator.name(firstNameController.text.trim()) != null) {
        throw Exception("Invalid first name.");
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
        currentUserId: user,
      );

      await _logService.addLog(
        userId: user,
        action: "Added Patient $patientName",
      );

      showToast('Patient data submitted successfully!');
      Navigator.of(context).pop();
    } catch (e) {
      _showError(['Error submitting patient data: $e']);
    }
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
            color: AppColors.neon,
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Fields marked with * are required.", style: Textstyle.body),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile Image *', style: Textstyle.subheader),
              Text(
                "Tap the camera icon to change the patient's profile image",
                style: Textstyle.body,
              ),
            ],
          ),
          SizedBox(height: 20),

          // Profile Image Section with FormField for Validation
          FormField(
            validator: (value) {
              if (_profileImage == null &&
                  (_profileImageUrl == null || _profileImageUrl!.isEmpty)) {
                return 'Please select a profile image.';
              }
              return null;
            },
            builder: (FormFieldState state) {
              return Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              _profileImage != null
                                  ? FileImage(_profileImage!) // Picked image
                                  : (_profileImageUrl != null &&
                                          _profileImageUrl!.isNotEmpty
                                      ? NetworkImage(_profileImageUrl!)
                                      : AssetImage(
                                            'lib/assets/images/shared/placeholder.png',
                                          )
                                          as ImageProvider),
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
                            icon: Icon(
                              Icons.camera_alt,
                              color: AppColors.white,
                            ),
                            iconSize: 18,
                          ),
                        ),
                      ],
                    ),
                    // Display error message if validation fails
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          state.errorText ?? '',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Active Case/s', style: Textstyle.subheader)],
          ),
          CasePickerWidget(
            selectedCases: selectedCases,
            onAddCase: _addCase,
            onRemoveCase: _removeCase,
            enabled: !_isLoading,
            validator: (selectedCases) {
              if (selectedCases == null || selectedCases.isEmpty) {
                return 'Please select at least one case.';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          CustomTextField(
            controller: caseDescriptionController,
            focusNode: _focusNodes[7],
            labelText: 'Case Description',
            enabled: !_isLoading,
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
            labelText: 'First Name *',
            enabled: !_isLoading,
            validator: (value) => Validator.name(value?.trim()),
          ),
          const SizedBox(height: 10),

          CustomTextField(
            controller: middleNameController,
            focusNode: _focusNodes[1],
            labelText: 'Middle Name',
            enabled: !_isLoading,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return null;
              }
              final nameRegExp = RegExp(
                r"^(?!['.-])[\p{L}]+(?:[\s'-][\p{L}]+)*(?<!['.-])$",
                unicode: true,
              );

              if (!nameRegExp.hasMatch(val)) {
                return 'Enter a valid name.';
              }
              return null;
            },
            inputFormatters: [LengthLimitingTextInputFormatter(50)],
          ),
          const SizedBox(height: 10),

          CustomTextField(
            controller: lastNameController,
            focusNode: _focusNodes[2],
            labelText: 'Last Name *',
            enabled: !_isLoading,
            validator: (val) => Validator.name(val?.trim()),
            inputFormatters: [LengthLimitingTextInputFormatter(50)],
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
              labelText: 'Birthday *',
              filled: true,
              fillColor: AppColors.gray,
              suffixIcon: Icon(
                Icons.calendar_today,
                color:
                    _focusNodes[3].hasFocus ? AppColors.neon : AppColors.black,
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
                    _focusNodes[3].hasFocus ? AppColors.neon : AppColors.black,
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
            labelText: 'Gender *',
            items: ['Male', 'Female', 'Other'],
            onChanged: (val) => setState(() => gender = val ?? ''),
            validator:
                (val) => val == null || val.isEmpty ? 'Select Gender' : null,
            displayItem: (value) => value,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 10),

          CustomDropdownField<String>(
            value: religion.isNotEmpty ? religion : null,
            focusNode: _focusNodes[5],
            labelText: 'Religion *',
            items: religions,
            onChanged: (val) => setState(() => religion = val ?? ''),
            validator:
                (val) => val == null || val.isEmpty ? 'Select Religion' : null,
            displayItem: (value) => value,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 10),

          CustomTextField(
            controller: addressController,
            focusNode: _focusNodes[6],
            labelText: 'Address *',
            enabled: !_isLoading,
            validator: (val) => Validator.address(val?.trim()),
            inputFormatters: [LengthLimitingTextInputFormatter(200)],
          ),
          const SizedBox(height: 10),

          divider(),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed:
                  (!_isLoading &&
                          _formKey.currentState?.validate() == true &&
                          _profileImage != null &&
                          (selectedCases != null && selectedCases.isNotEmpty))
                      ? _submitForm
                      : null,
              style:
                  (_isLoading || _profileImage == null || selectedCases.isEmpty)
                      ? Buttonstyle.gray
                      : Buttonstyle.neon,
              child: Text('Add Patient', style: Textstyle.largeButton),
            ),
          ),
        ],
      ),
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
          centerTitle: true,
          automaticallyImplyLeading: _isLoading ? false : true,
          title: Text('Patient Info', style: Textstyle.subheader),
        ),
        body:
            _isLoading
                ? Container(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Loader.loaderPurple,
                      SizedBox(height: 20),
                      Text(
                        "Adding Patient $patientName. Please wait.",
                        style: Textstyle.body.copyWith(
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16, 16),
                  child: Column(children: [deter(), _buildForm()]),
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
