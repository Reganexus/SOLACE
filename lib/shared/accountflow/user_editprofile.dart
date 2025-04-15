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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solace/screens/caregiver/caregiver_instructions.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/screens/wrapper.dart';
import 'package:solace/services/error_handler.dart';
import 'package:solace/services/loader_screen.dart';
import 'package:solace/services/validator.dart';
import 'package:solace/shared/accountflow/rolechooser.dart';
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

/// Screen for editing user profile.
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userRole;

  const EditProfileScreen({
    super.key,
    required this.userData,
    required this.userRole,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  DatabaseService db = DatabaseService();
  LogService logService = LogService();
  late final String userId;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _navigated = false;
  bool _autoValidate = false;

  late List<FocusNode> _focusNodes;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController middleNameController;
  late TextEditingController phoneNumberController;
  late TextEditingController addressController;
  late TextEditingController birthdayController;

  late Map<String, dynamic> originalUserData;

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
    if (userId.isEmpty) {
//       debugPrint("User ID is empty. User not logged in.");
      return;
    }

    _focusNodes = List.generate(8, (_) => FocusNode());
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    middleNameController = TextEditingController();
    phoneNumberController = TextEditingController();
    addressController = TextEditingController();
    birthdayController = TextEditingController();

    originalUserData = Map<String, dynamic>.from(widget.userData);

    _initializeUserDetails(widget.userData);

    if (widget.userData['newUser'] == true) {
      _checkAndLoadFormData();
    } else {
      _initializeUserDetails(widget.userData);
    }

//     debugPrint("_autoValidate = $_autoValidate");
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

  Future<void> _checkAndLoadFormData() async {
    final prefs = await SharedPreferences.getInstance();
    // Check if there are any stored preferences for the user
    final hasData =
        prefs.containsKey('firstName_$userId') ||
        prefs.containsKey('middleName_$userId') ||
        prefs.containsKey('lastName_$userId') ||
        prefs.containsKey('phoneNumber_$userId') ||
        prefs.containsKey('birthday_$userId') ||
        prefs.containsKey('gender_$userId') ||
        prefs.containsKey('religion_$userId') ||
        prefs.containsKey('address_$userId') ||
        prefs.containsKey('imagePath_$userId');

    if (hasData) {
      // Load the form data if any preference exists for the user
      await loadFormData(userId);
    }
  }

  Future<void> loadFormData(String userId) async {
    /// Loads form data from shared preferences.
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstNameController.text = prefs.getString('firstName_$userId') ?? ' ';
      middleNameController.text = prefs.getString('middleName_$userId') ?? ' ';
      lastNameController.text = prefs.getString('lastName_$userId') ?? ' ';
      phoneNumberController.text =
          prefs.getString('phoneNumber_$userId') ?? ' ';
      birthdayController.text = prefs.getString('birthday_$userId') ?? ' ';
      gender = prefs.getString('gender_$userId') ?? ' ';
      religion = prefs.getString('religion_$userId') ?? '';
      addressController.text = prefs.getString('address_$userId') ?? ' ';
      _profileImageUrl = prefs.getString('imagePath_$userId');
      if (_profileImageUrl != null) {
        _profileImage = File(_profileImageUrl!);
      }
    });
  }

  void _initializeUserDetails(Map<String, dynamic> userData) {
    /// Initializes the user details from provided data.
    setState(() {
      firstNameController.text = userData['firstName'] ?? '';
      lastNameController.text = userData['lastName'] ?? '';
      middleNameController.text = userData['middleName'] ?? '';
      phoneNumberController.text = userData['phoneNumber'] ?? '';
      addressController.text = userData['address'] ?? '';
      birthday =
          userData['birthday'] is Timestamp
              ? (userData['birthday'] as Timestamp).toDate()
              : DateTime.tryParse(userData['birthday'] ?? '');
      birthdayController.text =
          birthday != null ? DateFormat('MMMM d, yyyy').format(birthday!) : '';
      _profileImageUrl = userData['profileImageUrl'] ?? '';
      gender = userData['gender'] ?? '';
      religion = userData['religion'] ?? '';
      role = widget.userRole;
    });
  }

  Future<File> getFileFromAsset(String assetPath) async {
    /// Gets a file from the asset path.
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
    /// Uploads profile image to Firebase Storage.
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
//       debugPrint("Image uploaded successfully: $downloadUrl");
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception("Firebase Storage Error: ${e.message}");
    } catch (e) {
      throw Exception("General Error Uploading Profile Image: $e");
    }
  }

  Future<void> _pickProfileImage() async {
    /// Allows user to pick a profile image.
    try {
      final selectedImage = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SelectProfileImageScreen(
                role: widget.userRole,
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
          _profileImageUrl = _profileImage!.path;
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
    /// Opens date picker to select a date.
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
    /// Displays an error dialog with given messages.
    if (errorMessages.isEmpty || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ErrorDialog(title: 'Error', messages: errorMessages),
    );
  }

  void showToast(String message) {
    /// Shows a toast message.
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
    /// Calculates age based on birth date.
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.isBefore(DateTime(now.year, birthDate.month, birthDate.day))) {
      age--;
    }
    return age;
  }

  Widget divider() {
    /// Returns a divider widget.
    return Column(
      children: [
        const SizedBox(height: 10),
        const Divider(thickness: 1.0),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<bool> _showConfirmationDialog() async {
    /// Shows a confirmation dialog.
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text('Confirm Update', style: Textstyle.subheader),
          content: Text(
            'Are you sure you want to update your profile?',
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

  void navigateToRoleChooser(Map<String, dynamic> userData) {
    /// Navigates to the role chooser screen.
    if (!_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => RoleChooser(
                  onRoleSelected: (role) {
//                     debugPrint("Selected role: $role");
                  },
                ),
            settings: RouteSettings(arguments: userData),
          ),
        );
      });
    }
  }

  Future<void> _handleBackPress() async {
    /// Handles back press action.
    final isNewUser = widget.userData['newUser'] ?? false;

    if (_hasUnsavedChanges()) {
      final shouldDiscardChanges = await _showDiscardChangesDialog(isNewUser);
      if (!shouldDiscardChanges) {
        return;
      }
    }

    if (isNewUser) {
//       debugPrint("imagepath: $_profileImageUrl");
      await db.cacheFormData(
        userId: userId,
        firstName: firstNameController.text.trim(),
        middleName: middleNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        phoneNumber: phoneNumberController.text.trim(),
        birthday: birthdayController.text.trim(),
        gender: gender,
        religion: religion,
        address: addressController.text.trim(),
        imagePath: _profileImageUrl ?? '',
      );
      navigateToRoleChooser(widget.userData);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Wrapper()),
      );
    }
  }

  bool _hasUnsavedChanges() {
    /// Checks if there are any unsaved changes in the form.
    return firstNameController.text.trim() !=
            widget.userData['firstName']?.trim() ||
        middleNameController.text.trim() !=
            widget.userData['middleName']?.trim() ||
        lastNameController.text.trim() != widget.userData['lastName']?.trim() ||
        phoneNumberController.text.trim() !=
            widget.userData['phoneNumber']?.trim() ||
        birthdayController.text.trim() !=
            (widget.userData['birthday'] != null
                ? DateFormat('MMMM d, yyyy').format(
                  widget.userData['birthday'] is Timestamp
                      ? widget.userData['birthday'].toDate()
                      : DateTime.parse(widget.userData['birthday']),
                )
                : '') ||
        gender != widget.userData['gender'] ||
        religion != widget.userData['religion'] ||
        addressController.text.trim() != widget.userData['address']?.trim() ||
        _profileImageUrl != originalUserData['profileImageUrl'];
  }

  Future<bool> _showDiscardChangesDialog(bool newUser) async {
    /// Shows a dialog to confirm discarding changes.
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: AppColors.white,
                title: Text(
                  newUser ? 'Go Back?' : 'Discard Changes?',
                  style: Textstyle.subheader,
                ),
                content: Text(
                  newUser
                      ? "Go back to role selection? Don't worry, your changes will be saved."
                      : 'You have unsaved changes. Do you want to discard them and go back?',
                  style: Textstyle.body,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false), // Cancel
                    style: Buttonstyle.buttonRed,
                    child: Text('Cancel', style: Textstyle.smallButton),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true), // Confirm
                    style: Buttonstyle.buttonNeon,
                    child: Text(
                      newUser ? 'Confirm' : 'Discard',
                      style: Textstyle.smallButton,
                    ),
                  ),
                ],
              ),
        ) ??
        false; // Default to false if dialog is dismissed
  }

  Future<void> _submitForm() async {
    /// Submits the form after validation.
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    FocusScope.of(context).unfocus();

    final shouldProceed = await _showConfirmationDialog();
    if (!shouldProceed) return;
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final firestore = FirebaseFirestore.instance;
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

      // Document Transfer for New Users
      final isNewUser = widget.userData['newUser'] == true;
      final userDocData = {
        ...widget.userData,
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
        'newUser': false,
        'isVerified': true,
        'userRole': widget.userRole,
      };

      db.cacheUserRole(userId, widget.userRole);

      if (isNewUser) {
        final unregisteredRef = firestore
            .collection('unregistered')
            .doc(userId);
        final targetRef = firestore.collection(widget.userRole).doc(userId);

        await firestore.runTransaction((transaction) async {
          transaction.set(targetRef, userDocData);
          transaction.delete(unregisteredRef);
        });
      } else {
        // Update Document for Existing Users
        final userDocRef = firestore.collection(widget.userRole).doc(userId);
        await userDocRef.update(userDocData);
      }

      // Navigation Logic
      if (isNewUser) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (context) => CaregiverInstructions(
                  userId: userId,
                  userRole: widget.userRole,
                ),
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

        logChange(
          'First Name',
          originalUserData['firstName'],
          firstNameController.text.trim(),
        );
        logChange(
          'Middle Name',
          originalUserData['middleName'],
          middleNameController.text.trim(),
        );
        logChange(
          'Last Name',
          originalUserData['lastName'],
          lastNameController.text.trim(),
        );
        logChange(
          'Phone Number',
          originalUserData['phoneNumber'],
          phoneNumberController.text.trim(),
        );
        logChange(
          'Birthday',
          originalUserData['birthday'] is Timestamp
              ? DateFormat(
                'yyyy-MM-dd',
              ).format((originalUserData['birthday'] as Timestamp).toDate())
              : originalUserData['birthday']?.toString().split(
                ' ',
              )[0], // Fallback if not a Timestamp
          birthday != null ? DateFormat('yyyy-MM-dd').format(birthday!) : null,
        );
        logChange('Gender', originalUserData['gender'], gender);
        logChange('Religion', originalUserData['religion'], religion);
        logChange(
          'Address',
          originalUserData['address'],
          addressController.text.trim(),
        );

        if (_profileImage != null ||
            _profileImageUrl != originalUserData['profileImageUrl']) {
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

      // Logging and Feedback
      if (mounted) {
        await logService.addLog(userId: userId, action: 'Edited profile');
        showToast('Profile updated successfully');
      }
    } catch (e) {
      _showError([e.toString()]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildForm() {
    return Form(
      autovalidateMode:
          _autoValidate
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                                      _pickProfileImage();
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
            children: [
              Text('Personal Information', style: Textstyle.subheader),
            ],
          ),
          SizedBox(height: 10),
          CustomTextField(
            controller: firstNameController,
            focusNode: _focusNodes[0],
            labelText: 'First Name',
            enabled: !_isLoading,
            validator: (value) => Validator.name(value?.trim()),
          ),

          SizedBox(height: 10),
          CustomTextField(
            controller: middleNameController,
            focusNode: _focusNodes[1],
            labelText: 'Middle Name (Optional)',
            enabled: !_isLoading,
          ),

          SizedBox(height: 10),
          CustomTextField(
            controller: lastNameController,
            focusNode: _focusNodes[2],
            labelText: 'Last Name',
            enabled: !_isLoading,
            validator: (value) => Validator.name(value?.trim()),
          ),

          SizedBox(height: 10),
          CustomTextField(
            controller: phoneNumberController,
            focusNode: _focusNodes[3],
            labelText: 'Mobile Number',
            keyboardType: TextInputType.phone,
            enabled: !_isLoading,
            validator: (value) => Validator.phoneNumber(value?.trim()),
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
                    _focusNodes[4].hasFocus ? AppColors.neon : AppColors.black,
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
                    _focusNodes[4].hasFocus ? AppColors.neon : AppColors.black,
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Birthday cannot be empty';
              }
              return null;
            },
            readOnly: true,
            onTap: () => _selectDate(context),
          ),
          SizedBox(height: 10),
          CustomDropdownField<String>(
            value:
                gender.isNotEmpty &&
                        ['Male', 'Female', 'Other'].contains(gender)
                    ? gender
                    : null,
            focusNode: _focusNodes[5],
            labelText: 'Gender',
            items: ['Male', 'Female', 'Other'],
            enabled: !_isLoading,
            onChanged: (val) {
              setState(() => gender = val ?? '');
            },
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Gender cannot be empty';
              }
              return null;
            },

            displayItem: (item) => item,
          ),
          SizedBox(height: 10),
          CustomDropdownField<String>(
            value:
                religion.isNotEmpty && religions.contains(religion)
                    ? religion
                    : null,
            focusNode: _focusNodes[6],
            labelText: 'Religion',
            enabled: !_isLoading,
            items: religions,
            onChanged: (val) {
              setState(() => religion = val ?? '');
            },
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Religion cannot be empty';
              }
              return null;
            },
            displayItem: (item) => item,
          ),
          SizedBox(height: 10),
          CustomTextField(
            controller: addressController,
            focusNode: _focusNodes[7],
            labelText: 'Address',
            enabled: !_isLoading,
            validator: (val) => Validator.address(val?.trim()),
          ),
          divider(),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed:
                  !_isLoading && _hasUnsavedChanges()
                      ? () {
                        setState(() {
                          _autoValidate = true; // Enable autovalidation
                        });

                        // Validate the form and submit if valid
                        if (_formKey.currentState?.validate() == true) {
                          _submitForm();
                        }
                      }
                      : null,
              style:
                  !_isLoading && _hasUnsavedChanges()
                      ? Buttonstyle.neon
                      : Buttonstyle.gray,
              child: Text('Save Changes', style: Textstyle.largeButton),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neon,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, size: 40, color: AppColors.white),
          SizedBox(height: 20),
          Text(
            'Fill in your personal information',
            style: Textstyle.subheader.copyWith(color: AppColors.white),
          ),
          Text(
            'Please answer all the following fields',
            style: Textstyle.bodyWhite,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          _isLoading ? '' : 'Edit Profile',
          style: Textstyle.subheader,
        ),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        centerTitle: true,
        automaticallyImplyLeading: _isLoading ? false : true,
        leading:
            _isLoading
                ? null
                : IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.black),
                  onPressed: () {
                    _handleBackPress();
                  },
                ),
      ),
      body:
          _isLoading
              ? Container(
                color: AppColors.white,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Loader.loaderPurple,
                    SizedBox(height: 20),
                    Text(
                      "Saving your data. Please wait.",
                      style: Textstyle.body.copyWith(
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              )
              : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        _buildHeader(),
                        SizedBox(height: 20),
                        _buildForm(),
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
}
