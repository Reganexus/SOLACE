// ignore_for_file: unused_import, avoid_print

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:solace/screens/caregiver/caregiver_instructions.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/screens/wrapper.dart';
import 'package:solace/services/error_handler.dart';
import 'package:solace/services/loader_screen.dart';
import 'package:solace/services/validator.dart';
import 'package:solace/shared/widgets/select_profile_image.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/dropdownfield.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textformfield.dart';
import 'package:solace/themes/textstyle.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  DatabaseService db = DatabaseService();
  LogService logService = LogService();
  late final String userId;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late List<FocusNode> _focusNodes;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController middleNameController;
  late TextEditingController phoneNumberController;
  late TextEditingController addressController;
  late TextEditingController birthdayController;

  late Map<String, dynamic> originalUserData;
  bool _isFormChanged = false;

  File? _profileImage;
  String? _profileImageUrl;
  String? role;
  String gender = '';
  String religion = '';
  DateTime? birthday;

  static const List<String> religions = [
    'Roman Catholic',
    'Islam',
    'Iglesia ni Cristo',
    'Other', // Add 'Other' option
  ];

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    _focusNodes = List.generate(8, (_) => FocusNode());
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    middleNameController = TextEditingController();
    phoneNumberController = TextEditingController();
    addressController = TextEditingController();
    birthdayController = TextEditingController();

    originalUserData = Map<String, dynamic>.from(widget.userData);

    _initializeUserDetails(widget.userData);
    debugPrint("User Data in Edit Profile: ${widget.userData}");
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

  void _initializeUserDetails(Map<String, dynamic> userData) {
    setState(() {
      firstNameController.text = userData['firstName'] ?? '';
      lastNameController.text = userData['lastName'] ?? '';
      middleNameController.text = userData['middleName'] ?? '';
      phoneNumberController.text = userData['phoneNumber'] ?? '';
      addressController.text = userData['address'] ?? '';

      // Safely handle the birthday parsing
      final rawBirthday = userData['birthday'];
      if (rawBirthday != null) {
        try {
          birthday =
              rawBirthday is Timestamp
                  ? rawBirthday.toDate()
                  : DateTime.parse(rawBirthday);

          // Format birthday to "Month Day, Year"
          birthdayController.text = DateFormat(
            'MMMM d, yyyy',
          ).format(birthday!);
        } catch (e) {
          birthday = null;
          birthdayController.text = '';
        }
      } else {
        birthday = null;
        birthdayController.text = '';
      }

      _profileImageUrl = userData['profileImageUrl'] ?? '';
      gender = userData['gender'] ?? '';
      religion = userData['religion'] ?? '';

      // Safely handle userRole
      final rawUserRole = userData['userRole'];
      role = rawUserRole is String ? rawUserRole : rawUserRole?.toString();
    });
  }

  void _checkForChanges() {
    setState(() {
      _isFormChanged = firstNameController.text.trim() != (originalUserData['firstName'] ?? '') ||
          lastNameController.text.trim() != (originalUserData['lastName'] ?? '') ||
          middleNameController.text.trim() != (originalUserData['middleName'] ?? '') ||
          phoneNumberController.text.trim() != (originalUserData['phoneNumber'] ?? '') ||
          addressController.text.trim() != (originalUserData['address'] ?? '') ||
          birthdayController.text.trim() !=
              (originalUserData['birthday'] != null
                  ? DateFormat('MMMM d, yyyy').format(
                      originalUserData['birthday'] is Timestamp
                          ? originalUserData['birthday'].toDate()
                          : DateTime.parse(originalUserData['birthday']),
                    )
                  : '') ||
          gender != (originalUserData['gender'] ?? '') ||
          religion != (originalUserData['religion'] ?? '') ||
          (_profileImage != null || _profileImageUrl != originalUserData['profileImageUrl']);
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
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint("Image uploaded successfully: $downloadUrl");
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception("Firebase Storage Error: ${e.message}");
    } catch (e) {
      throw Exception("General Error Uploading Profile Image: $e");
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      // Ensure userRole is cast or transformed into a String
      final String role = widget.userData['userRole']?.toString() ?? '';

      debugPrint("Pick Profile Image Role: $role");

      if (role.isEmpty) {
        throw Exception('User role is missing or invalid.');
      }

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
        _profileImage =
            selectedImage.startsWith('lib/')
                ? await getFileFromAsset(selectedImage)
                : File(selectedImage);

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
    final DateTime minDate = DateTime(
      today.year - 120,
    ); // Minimum age of 120 years
    final DateTime maxDate = DateTime(
      today.year - 1,
    ); // Maximum age of 1 year ago
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

  void _showError(List<String> errorMessages) {
    if (errorMessages.isEmpty || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ErrorDialog(title: 'Error', messages: errorMessages),
    );
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

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.isBefore(DateTime(now.year, birthDate.month, birthDate.day))) {
      age--;
    }
    return age;
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in.");

      final userRole = widget.userData['userRole'] ?? '';
      if (userRole.isEmpty) throw Exception("User role not found.");

      if (birthday == null) throw Exception("Please select your birthday.");
      final age = _calculateAge(birthday!);

      if (gender.isEmpty) throw Exception("Please select your gender.");
      if (religion.isEmpty) throw Exception("Please select your religion.");
      if (addressController.text.trim().length < 10) {
        throw Exception("Please input your complete address.");
      }

      String? profileImageUrl = _profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await uploadProfileImage(
          userId: userId,
          file: _profileImage!,
        );
      }

      final userDocRef = FirebaseFirestore.instance
          .collection(userRole) // Dynamically set collection
          .doc(userId);

      await userDocRef.update({
        'firstName':
            StringExtensions(
              firstNameController.text.trim(),
            ).capitalizeEachWord(),
        'lastName':
            StringExtensions(
              lastNameController.text.trim(),
            ).capitalizeEachWord(),
        'middleName':
            StringExtensions(
              middleNameController.text.trim(),
            ).capitalizeEachWord(),
        'phoneNumber': phoneNumberController.text.trim(),
        'gender': gender,
        'birthday': birthday!,
        'address':
            StringExtensions(
              addressController.text.trim(),
            ).capitalizeEachWord(),
        'profileImageUrl': profileImageUrl ?? '',
        'religion': religion,
        'age': age,
        'newUser': widget.userData['newUser'] ?? false,
        'isVerified': true,
      });

      // Determine navigation
      final bool isNewUser = widget.userData['newUser'] == true;
      if (isNewUser) {
        await userDocRef.update({'newUser': false});
        showToast('Account successfully created!');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    CaregiverInstructions(userId: userId, userRole: userRole),
          ),
          (route) => false,
        );
      } else {
        // Log changes
        final List<String> changeLogs = [];
        void logChange(String field, dynamic oldValue, dynamic newValue) {
          if (oldValue != newValue) {
            changeLogs.add("Changed $field from '$oldValue' to '$newValue'.");
          }
        }

        logChange('First Name', originalUserData['firstName'], firstNameController.text.trim());
        logChange('Middle Name', originalUserData['middleName'], middleNameController.text.trim());
        logChange('Last Name', originalUserData['lastName'], lastNameController.text.trim());
        logChange('Phone Number', originalUserData['phoneNumber'], phoneNumberController.text.trim());
        logChange('Birthday', originalUserData['birthday'], birthday);
        logChange('Gender', originalUserData['gender'], gender);
        logChange('Religion', originalUserData['religion'], religion);
        logChange('Address', originalUserData['address'], addressController.text.trim());

        if (_profileImage != null || _profileImageUrl != originalUserData['profileImageUrl']) {
          changeLogs.add("Changed Profile Image.");
        }

        // Log individual changes
        for (final log in changeLogs) {
          await logService.addLog(userId: userId, action: log);
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Wrapper()),
          (route) => false,
        );
      }

      if (mounted) {
        showToast('Profile updated successfully');
      }
    } catch (e) {
      _showError([e.toString()]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Edit Profile', style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: _isLoading ? false : true,
      ),
      body:
          _isLoading
              ? Center(child: Loader.loaderPurple)
              : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage:
                                      _profileImage != null
                                          ? FileImage(_profileImage!)
                                          : (_profileImageUrl != null &&
                                                  _profileImageUrl!.isNotEmpty
                                              ? (_profileImageUrl!.startsWith(
                                                    'http',
                                                  )
                                                  ? NetworkImage(
                                                    _profileImageUrl!,
                                                  )
                                                  : AssetImage(
                                                        _profileImageUrl!,
                                                      )
                                                      as ImageProvider)
                                              : AssetImage(
                                                'lib/assets/images/shared/placeholder.png',
                                              )),
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
                                              _pickProfileImage();
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
                              Text(
                                'Personal Information',
                                style: Textstyle.subheader,
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          CustomTextField(
                            controller: firstNameController,
                            focusNode: _focusNodes[0],
                            labelText: 'First Name',
                            enabled: !_isLoading,
                            validator: (value) => Validator.name(value?.trim()),
                            onChanged: (value) => _checkForChanges(),
                          ),

                          SizedBox(height: 10),
                          CustomTextField(
                            controller: middleNameController,
                            focusNode: _focusNodes[1],
                            labelText: 'Middle Name',
                            enabled: !_isLoading,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              return Validator.name(value.trim());
                            },
                            onChanged: (value) => _checkForChanges(),
                          ),

                          SizedBox(height: 10),
                          CustomTextField(
                            controller: lastNameController,
                            focusNode: _focusNodes[2],
                            labelText: 'Last Name',
                            enabled: !_isLoading,
                            validator: (value) => Validator.name(value?.trim()),
                            onChanged: (value) => _checkForChanges(),
                          ),

                          SizedBox(height: 10),
                          CustomTextField(
                            controller: phoneNumberController,
                            focusNode: _focusNodes[3],
                            labelText: 'Phone Number',
                            keyboardType: TextInputType.phone,
                            enabled: !_isLoading,
                            validator: (value) => Validator.phoneNumber(value?.trim()),
                            onChanged: (value) => _checkForChanges(),
                          ),

                          // Birthday Field
                          SizedBox(height: 10),
                          TextFormField(
                            controller: birthdayController,
                            enabled: !_isLoading,
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
                                color:
                                    _focusNodes[4].hasFocus
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
                                    _focusNodes[4].hasFocus
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
                            onChanged: (value) => _checkForChanges(),
                          ),
                          SizedBox(height: 10),
                          CustomDropdownField<String>(
                            value:
                                gender.isNotEmpty &&
                                        [
                                          'Male',
                                          'Female',
                                          'Other',
                                        ].contains(gender)
                                    ? gender
                                    : null,
                            focusNode: _focusNodes[5],
                            labelText: 'Gender',
                            items: ['Male', 'Female', 'Other'],
                            enabled: !_isLoading,
                            onChanged: (val) {
                              setState(() => gender = val ?? '');
                              _checkForChanges();
                            },
                            validator:
                                (val) =>
                                    val == null || val.isEmpty
                                        ? 'Select Gender'
                                        : null,
                            displayItem: (item) => item,
                          ),
                          SizedBox(height: 10),
                          CustomDropdownField<String>(
                            value:
                                religion.isNotEmpty &&
                                        religions.contains(religion)
                                    ? religion
                                    : null,
                            focusNode: _focusNodes[6],
                            labelText: 'Religion',
                            enabled: !_isLoading,
                            items: religions,
                            onChanged: (val) {
                              setState(() => religion = val ?? '');
                              _checkForChanges();
                            },
                            validator:
                                (val) =>
                                    val == null || val.isEmpty
                                        ? 'Select Religion'
                                        : null,
                            displayItem: (item) => item,
                          ),
                          SizedBox(height: 10),
                          CustomTextField(
                            controller: addressController,
                            focusNode: _focusNodes[7],
                            labelText: 'Address',
                            enabled: !_isLoading,
                            validator: (val) => Validator.address(val?.trim()),
                            onChanged: (value) => _checkForChanges(),
                          ),
                          divider(),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _isFormChanged && !_isLoading ? _submitForm : null,
                              style: _isFormChanged && !_isLoading ? Buttonstyle.neon : Buttonstyle.gray,
                              child: Text(
                                'Update Profile',
                                style: Textstyle.largeButton,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
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
}
