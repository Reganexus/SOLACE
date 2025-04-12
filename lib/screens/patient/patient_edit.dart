// ignore_for_file: avoid_print

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:solace/models/my_patient.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/case_picker.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/shared/widgets/select_profile_image.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/dropdownfield.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textformfield.dart';
import 'package:solace/themes/textstyle.dart';

class EditPatient extends StatefulWidget {
  final String patientId;
  final String role;

  const EditPatient({super.key, required this.patientId, required this.role});

  @override
  State<EditPatient> createState() => _EditPatientState();
}

class _EditPatientState extends State<EditPatient> {
  final AuthService _auth = AuthService();
  final LogService _logService = LogService();
  final DatabaseService db = DatabaseService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late PatientData patientData;
  List<String> selectedCases = [];
  File? _profileImage;
  String? _profileImageUrl;
  DateTime? birthday;
  String? gender;
  String? religion;
  bool _isLoading = false;

  final List<FocusNode> _focusNodes = List.generate(10, (_) => FocusNode());
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController caseDescriptionController =
      TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();

  static const List<String> religions = [
    'Roman Catholic',
    'Islam',
    'Iglesia ni Cristo',
    'Other',
  ];

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _loadPatientCases() async {
    try {
      final patientDoc =
          await FirebaseFirestore.instance
              .collection('patient')
              .doc(widget.patientId)
              .get();

      if (patientDoc.exists) {
        setState(() {
          selectedCases = List<String>.from(patientDoc.data()?['cases'] ?? []);
        });
        debugPrint('bibibi Selected cases: $selectedCases');
        for (var caseItem in selectedCases) {
          debugPrint('bibibi Case item: $caseItem');
          if (!selectedCases.contains(caseItem)) {
            debugPrint('bibibi Case item $caseItem added');
            _addCase(caseItem);
          }
        }
      } else {
        debugPrint("Patient document does not exist.");
      }
    } catch (e) {
      debugPrint("Error loading patient cases: $e");
    }
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
          // Convert asset to file
          _profileImage = await getFileFromAsset(selectedImage);
        } else {
          // Regular file path
          _profileImage = File(selectedImage);
        }

        setState(() {
          _profileImageUrl = null; // Clear old URLs
        });

        debugPrint("Selected image file path: ${_profileImage!.path}");
      } else {
        debugPrint('No image selected.');
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
      showToast(
        'Failed to pick a profile image.',
        backgroundColor: AppColors.red,
      );
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      patientData = await db.getPatientData(widget.patientId) as PatientData;

      if (patientData != null) {
        setState(() {
          firstNameController.text = patientData.firstName;
          lastNameController.text = patientData.lastName;
          middleNameController.text = patientData.middleName ?? '';
          caseDescriptionController.text = patientData.caseDescription ?? '';
          addressController.text = patientData.address;
          gender = patientData.gender;
          religion = patientData.religion;
          birthday = patientData.birthday;
          birthdayController.text =
              birthday != null
                  ? DateFormat('MMMM d, yyyy').format(birthday!)
                  : '';

          _profileImageUrl = patientData!.profileImageUrl;
        });
      } else {
        showToast(
          'No data found for this user.',
          backgroundColor: AppColors.red,
        );
      }
    } catch (e) {
      showToast('Failed to load user data.', backgroundColor: AppColors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPatientCases();
  }

  @override
  void dispose() {
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = _auth.currentUserId;
        if (user == null) {
          showToast(
            'User is not authenticated',
            backgroundColor: AppColors.red,
          );
          return;
        }
        setState(() => _isLoading = true);

        // Upload profile image if selected
        if (_profileImage != null) {
          _profileImageUrl = await uploadProfileImage(
            userId: widget.patientId,
            file: _profileImage!,
          );
        }

        // Prepare formatted data
        final firstName = firstNameController.text.capitalizeEachWord();
        final lastName = lastNameController.text.capitalizeEachWord();
        final middleName = middleNameController.text.capitalizeEachWord();
        final caseDescription = caseDescriptionController.text.sentenceCase();
        final address = addressController.text.capitalizeEachWord();

        // Log changes
        final List<String> caregiverLogs = [];
        final List<String> patientLogs = [];
        final caregiverName = await _loadCaregiverName(user, widget.role); // Fetch caregiver's name
        final patientName = '$firstName $lastName';

        void logChange(String field, dynamic oldValue, dynamic newValue) {
          if (oldValue != newValue) {
            caregiverLogs.add(
                "Edited $patientName's $field from '$oldValue' to '$newValue'.");
            patientLogs.add(
                "$caregiverName changed $patientName's $field from '$oldValue' to '$newValue'.");
          }
        }

        // Log individual field changes
        logChange('First Name', patientData.firstName, firstName);
        logChange('Middle Name', patientData.middleName, middleName);
        logChange('Last Name', patientData.lastName, lastName);
        logChange('Case Description', patientData.caseDescription, caseDescription);
        logChange('Address', patientData.address, address);
        logChange('Gender', patientData.gender, gender);
        logChange('Religion', patientData.religion, religion);
        logChange(
          'Birthday',
          patientData.birthday is Timestamp
              ? DateFormat('yyyy-MM-dd')
                  .format((patientData.birthday as Timestamp).toDate())
              : patientData.birthday.toString().split(' ')[0],
          birthday != null ? DateFormat('yyyy-MM-dd').format(birthday!) : null,
        );

        // Log case changes
        final oldCases = List<String>.from(patientData.cases);
        final addedCases = selectedCases.where((c) => !oldCases.contains(c)).toList();
        final removedCases = oldCases.where((c) => !selectedCases.contains(c)).toList();

        if (addedCases.isNotEmpty) {
          caregiverLogs.add(
              "Added cases ${addedCases.join(', ')} to $patientName's profile.");
          patientLogs.add(
              "$caregiverName added cases ${addedCases.join(', ')} to $patientName's profile.");
        }

        if (removedCases.isNotEmpty) {
          caregiverLogs.add(
              "Removed cases ${removedCases.join(', ')} from $patientName's profile.");
          patientLogs.add(
              "$caregiverName removed cases ${removedCases.join(', ')} from $patientName's profile.");
        }
        
        // Update Firestore with formatted data
        await FirebaseFirestore.instance
            .collection('patient')
            .doc(widget.patientId)
            .update({
              'firstName': firstName,
              'lastName': lastName,
              'middleName': middleName,
              'cases': selectedCases,
              'caseDescription': caseDescription,
              'address': address,
              'gender': gender,
              'religion': religion,
              'birthday':
                  birthday != null ? Timestamp.fromDate(birthday!) : null,
              'profileImageUrl': _profileImageUrl,
            });

        debugPrint('bibibi Caregiver id: $user');
        debugPrint('bibibi Patient id: ${widget.patientId}');
        
        // Add logs to Firestore
        for (final log in caregiverLogs) {
          await _logService.addLog(userId: user, action: log, relatedUsers: widget.patientId); // Caregiver logs
        }
        for (final log in patientLogs) {
          await _logService.addLog(userId: widget.patientId, action: log, relatedUsers: user); // Patient logs
        }
        
        showToast('User profile updated successfully.');

        // Close the current screen and return to the previous screen
        Navigator.pop(context);
      } catch (e) {
        showToast(
          'Failed to update user profile.',
          backgroundColor: AppColors.red,
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _loadCaregiverName(String userId, String role) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection(role) // Replace with your actual Firestore collection name
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final firstName = data?['firstName'] ?? '';
        final lastName = data?['lastName'] ?? '';
        return '$firstName $lastName'.trim();
      } else {
        debugPrint('User document does not exist for userId: $userId');
        return 'Unknown User';
      }
    } catch (e) {
      debugPrint('Error fetching user name for userId $userId: $e');
      return 'Unknown User';
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
        children: [
          deter(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile Image', style: Textstyle.subheader),
              Text(
                'Tap the camera icon to change your profile image',
                style: Textstyle.body,
              ),
            ],
          ),
          SizedBox(height: 20),
          FormField(
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
            children: [Text('Current Case', style: Textstyle.subheader)],
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
          SizedBox(height: 10),
          CustomTextField(
            controller: caseDescriptionController,
            focusNode: _focusNodes[7],
            labelText: 'Case Description',
            enabled: !_isLoading,
            inputFormatters: [
              LengthLimitingTextInputFormatter(100)
            ],
          ),
          divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Personal Information', style: Textstyle.subheader),
            ],
          ),
          SizedBox(height: 20),

          CustomTextField(
            controller: firstNameController,
            focusNode: _focusNodes[0],
            labelText: 'First Name',
            enabled: !_isLoading,
            validator:
                (val) => val!.isEmpty ? 'First Name cannot be empty' : null,
          ),
          SizedBox(height: 10),

          CustomTextField(
            controller: middleNameController,
            focusNode: _focusNodes[1],
            labelText: 'Middle Name',
            enabled: !_isLoading,
          ),
          SizedBox(height: 10),

          CustomTextField(
            controller: lastNameController,
            focusNode: _focusNodes[2],
            labelText: 'Last Name',
            enabled: !_isLoading,
            validator:
                (val) => val!.isEmpty ? 'Last Name cannot be empty' : null,
          ),
          SizedBox(height: 10),

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

          SizedBox(height: 10),

          CustomDropdownField<String>(
            value: gender,
            focusNode: _focusNodes[4],
            labelText: 'Gender',
            items: ['Male', 'Female', 'Other'],
            onChanged: (val) => setState(() => gender = val ?? ''),
            validator:
                (val) => val == null || val.isEmpty ? 'Select Gender' : null,
            displayItem: (value) => value,
            enabled: !_isLoading,
          ),
          SizedBox(height: 10),

          CustomDropdownField<String>(
            value: religion,
            focusNode: _focusNodes[5],
            labelText: 'Religion',
            items: religions,
            onChanged: (val) => setState(() => religion = val ?? ''),
            validator:
                (val) => val == null || val.isEmpty ? 'Select Religion' : null,
            displayItem: (value) => value,
            enabled: !_isLoading,
          ),
          SizedBox(height: 10),

          CustomTextField(
            controller: addressController,
            focusNode: _focusNodes[6],
            labelText: 'Address',
            enabled: !_isLoading,
            validator: (val) => val!.isEmpty ? 'Address cannot be empty' : null,
          ),
          SizedBox(height: 10),

          divider(),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed:
                  (!_isLoading &&
                          _formKey.currentState?.validate() == true &&
                          (selectedCases != null && selectedCases.isNotEmpty))
                      ? _submitForm
                      : null,
              style:
                  (_isLoading || selectedCases.isEmpty)
                      ? Buttonstyle.gray
                      : Buttonstyle.neon,
              child: Text('Save changes', style: Textstyle.largeButton),
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
          title: Text('Edit Patient Info', style: Textstyle.subheader),
          backgroundColor: AppColors.white,
          scrolledUnderElevation: 0.0,
          centerTitle: true,
          automaticallyImplyLeading: _isLoading ? false : true,
        ),
        body: Container(
          color: AppColors.white,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child:
              _isLoading
                  ? Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Loader.loaderPurple,
                        SizedBox(height: 20),
                        Text(
                          "Saving changes. Please wait.",
                          style: Textstyle.body.copyWith(
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  )
                  : SingleChildScrollView(child: _buildForm()),
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

extension DateTimeExtensions on DateTime {
  String getMonthName() {
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
}
