// ignore_for_file: avoid_print

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/select_profile_image.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/dropdownfield.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textformfield.dart';
import 'package:solace/themes/textstyle.dart';

class EditPatient extends StatefulWidget {
  final String patientId;

  const EditPatient({super.key, required this.patientId});

  @override
  State<EditPatient> createState() => _EditPatientState();
}

class _EditPatientState extends State<EditPatient> {
  final DatabaseService db = DatabaseService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Map<String, dynamic> patientData = {};
  File? _profileImage;
  String? _profileImageUrl;
  DateTime? birthday;
  String gender = '';
  String religion = '';
  String organDonation = 'None';
  bool _isLoading = false;

  final List<FocusNode> _focusNodes = List.generate(13, (_) => FocusNode());
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController caseTitleController = TextEditingController();
  final TextEditingController caseDescriptionController =
      TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController willController = TextEditingController();
  final TextEditingController fixedWishesController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();

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
      showToast('Failed to pick a profile image.');
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final patientData = await db.getPatientData(widget.patientId);

      if (patientData != null) {
        setState(() {
          firstNameController.text = patientData.firstName;
          lastNameController.text = patientData.lastName;
          middleNameController.text = patientData.middleName;
          caseTitleController.text = patientData.caseTitle;
          caseDescriptionController.text = patientData.caseDescription;
          addressController.text = patientData.address;
          willController.text = patientData.will;
          fixedWishesController.text = patientData.fixedWishes;
          gender = patientData.gender;
          religion = patientData.religion;
          organDonation = patientData.organDonation;
          birthday = patientData.birthday;
          birthdayController.text =
              birthday != null
                  ? DateFormat('MMMM d, yyyy').format(birthday!)
                  : '';

          _profileImageUrl = patientData.profileImageUrl;
        });
      } else {
        showToast('No data found for this user.');
      }
    } catch (e) {
      showToast('Failed to load user data.');
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
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
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
            birthday != null ? DateFormat.yMd().format(birthday!) : '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
        final caseTitle = caseTitleController.text.sentenceCase();
        final caseDescription = caseDescriptionController.text.sentenceCase();
        final address = addressController.text.capitalizeEachWord();
        final will = willController.text.sentenceCase();
        final fixedWishes = fixedWishesController.text.sentenceCase();

        // Update Firestore with formatted data
        await FirebaseFirestore.instance
            .collection('patient')
            .doc(widget.patientId)
            .update({
              'firstName': firstName,
              'lastName': lastName,
              'middleName': middleName,
              'caseTitle': caseTitle,
              'caseDescription': caseDescription,
              'address': address,
              'will': will,
              'fixedWishes': fixedWishes,
              'gender': gender,
              'religion': religion,
              'organDonation': organDonation,
              'birthday':
                  birthday != null ? Timestamp.fromDate(birthday!) : null,
              'profileImageUrl': _profileImageUrl,
            });

        showToast('User profile updated successfully.');

        // Close the current screen and return to the previous screen
        Navigator.pop(context);
      } catch (e) {
        showToast('Failed to update user profile.');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _areAllFieldsFilled() {
    return firstNameController.text.trim().isNotEmpty &&
        lastNameController.text.trim().isNotEmpty &&
        caseTitleController.text.trim().isNotEmpty &&
        caseDescriptionController.text.trim().isNotEmpty &&
        addressController.text.trim().isNotEmpty &&
        willController.text.trim().isNotEmpty &&
        fixedWishesController.text.trim().isNotEmpty &&
        birthday != null &&
        gender.isNotEmpty &&
        religion.isNotEmpty &&
        organDonation.isNotEmpty;
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
          title: Text('Patient Info', style: Textstyle.subheader),
          backgroundColor: AppColors.white,
          scrolledUnderElevation: 0.0,
          automaticallyImplyLeading: _isLoading ? false : true,
        ),
        body: Container(
          color: AppColors.white,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child:
              _isLoading
                  ? Center(child: Loader.loaderPurple)
                  : SingleChildScrollView(
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
                                          ? FileImage(
                                            _profileImage!,
                                          ) // Use picked image
                                          : (_profileImageUrl != null &&
                                                      _profileImageUrl!
                                                          .isNotEmpty
                                                  ? NetworkImage(
                                                    _profileImageUrl!,
                                                  ) // Use network image
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
                                    icon: Icon(
                                      Icons.camera_alt,
                                      color: AppColors.white,
                                    ),
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
                            children: [
                              Text('Current Case', style: Textstyle.subheader),
                            ],
                          ),
                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: caseTitleController,
                            focusNode: _focusNodes[10],
                            labelText: 'Case Title',
                            enabled:
                                !_isLoading, // Ensure it's not set to false
                            validator:
                                (val) =>
                                    val!.isEmpty
                                        ? 'Case Title cannot be empty'
                                        : null,
                          ),

                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: caseDescriptionController,
                            focusNode: _focusNodes[11],
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
                              Text(
                                'Personal Information',
                                style: Textstyle.subheader,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: firstNameController,
                            focusNode: _focusNodes[0],
                            labelText: 'First Name',
                            enabled: !_isLoading,
                            validator:
                                (val) =>
                                    val!.isEmpty
                                        ? 'First Name cannot be empty'
                                        : null,
                          ),
                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: middleNameController,
                            focusNode: _focusNodes[1],
                            labelText: 'Middle Name',
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: lastNameController,
                            focusNode: _focusNodes[2],
                            labelText: 'Last Name',
                            enabled: !_isLoading,
                            validator:
                                (val) =>
                                    val!.isEmpty
                                        ? 'Last Name cannot be empty'
                                        : null,
                          ),
                          const SizedBox(height: 20),

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
                                borderSide: BorderSide(
                                  color: AppColors.neon,
                                  width: 2,
                                ),
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
                                (val) =>
                                    val!.isEmpty
                                        ? 'Birthday cannot be empty'
                                        : null,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                          ),

                          const SizedBox(height: 20),

                          CustomDropdownField<String>(
                            value: gender.isNotEmpty ? gender : null,
                            focusNode: _focusNodes[4],
                            labelText: 'Gender',
                            items: ['Male', 'Female', 'Other'],
                            onChanged:
                                (val) => setState(() => gender = val ?? ''),
                            validator:
                                (val) =>
                                    val == null || val.isEmpty
                                        ? 'Select Gender'
                                        : null,
                            displayItem: (value) => value,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 20),

                          CustomDropdownField<String>(
                            value: religion.isNotEmpty ? religion : null,
                            focusNode: _focusNodes[5],
                            labelText: 'Religion',
                            items: religions,
                            onChanged:
                                (val) => setState(() => religion = val ?? ''),
                            validator:
                                (val) =>
                                    val == null || val.isEmpty
                                        ? 'Select Religion'
                                        : null,
                            displayItem: (value) => value,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: addressController,
                            focusNode: _focusNodes[6],
                            labelText: 'Address',
                            enabled: !_isLoading,
                            validator:
                                (val) =>
                                    val!.isEmpty
                                        ? 'Address cannot be empty'
                                        : null,
                          ),
                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: willController,
                            focusNode: _focusNodes[7],
                            labelText: 'Will',
                            enabled: !_isLoading,
                            validator:
                                (val) =>
                                    val!.isEmpty
                                        ? 'Will cannot be empty'
                                        : null,
                          ),
                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: fixedWishesController,
                            focusNode: _focusNodes[8],
                            labelText: 'Fixed Wishes',
                            enabled: !_isLoading,
                            validator:
                                (val) =>
                                    val!.isEmpty
                                        ? 'Fixed Wishes cannot be empty'
                                        : null,
                          ),
                          const SizedBox(height: 20),

                          CustomDropdownField<String>(
                            value:
                                organDonation.isNotEmpty ? organDonation : null,
                            focusNode: _focusNodes[9],
                            labelText: 'Organ Donation',
                            items: organs,
                            onChanged:
                                (val) => setState(
                                  () => organDonation = val ?? 'None',
                                ),
                            validator:
                                (val) =>
                                    val == null || val.isEmpty
                                        ? 'Select Organ Donation'
                                        : null,
                            displayItem: (value) => value,
                            enabled: !_isLoading,
                          ),

                          divider(),

                          _areAllFieldsFilled()
                              ? deter()
                              : const SizedBox.shrink(),

                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _submitForm,
                              style:
                                  _isLoading
                                      ? Buttonstyle.gray
                                      : Buttonstyle.neon,
                              child: Text(
                                'Add Patient',
                                style: Textstyle.largeButton,
                              ),
                            ),
                          ),
                        ],
                      ),
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
