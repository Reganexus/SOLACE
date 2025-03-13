// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:solace/shared/widgets/select_profile_image.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';

class UserDataForm extends StatefulWidget {
  final UserData? userData;
  final UserDataCallback onButtonPressed;
  final VoidCallback? onFieldChanged;
  final bool isSignUp;
  final bool newUser;
  final bool isVerified;
  final int age;
  final UserRole userRole;

  const UserDataForm({
    super.key,
    this.isSignUp = true,
    required this.onButtonPressed,
    required this.userData,
    required this.userRole,
    required this.newUser,
    required this.isVerified,
    required this.age,
    this.onFieldChanged,
  });

  @override
  UserDataFormState createState() => UserDataFormState();
}

typedef UserDataCallback = Future<void> Function({
  required String firstName,
  required String lastName,
  required String middleName,
  required String phoneNumber,
  required String gender,
  required DateTime? birthday,
  required String address,
  required String profileImageUrl,
  required String religion,
  required int age,
});

class UserDataFormState extends State<UserDataForm> {
  DatabaseService db = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  late List<FocusNode> _focusNodes;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController middleNameController;
  late TextEditingController phoneNumberController;
  late TextEditingController addressController;
  late TextEditingController birthdayController;

  File? _profileImage;
  String? _profileImageUrl;
  String? role;
  String gender = '';
  String religion = '';
  DateTime? birthday;

  @override
  void initState() {
    super.initState();

    int focusNodeCount = 8; // Base fields (7 common + 1 address)

    // Initialize focus nodes with correct count
    _focusNodes = List.generate(focusNodeCount, (_) => FocusNode());
    debugPrint('Initialized focus nodes: ${_focusNodes.length}'); // Debug log

    _focusNodes = List.generate(focusNodeCount, (_) => FocusNode());
    debugPrint('Focus nodes count: ${_focusNodes.length}');

    role = db.getCollectionForRole(widget.userRole);
    debugPrint("User Data Form user role: $role");

    firstNameController =
        TextEditingController(text: widget.userData?.firstName ?? '');
    lastNameController =
        TextEditingController(text: widget.userData?.lastName ?? '');
    middleNameController =
        TextEditingController(text: widget.userData?.middleName ?? '');
    phoneNumberController =
        TextEditingController(text: widget.userData?.phoneNumber ?? '');
    addressController =
        TextEditingController(text: widget.userData?.address ?? '');
    birthday = widget.userData?.birthday;
    birthdayController = TextEditingController(
      text: birthday != null
          ? '${_getMonthName(birthday!.month)} ${birthday!.day}, ${birthday!.year}'
          : '',
    );
    gender = widget.userData?.gender ?? '';
    religion = widget.userData?.religion ?? '';
    debugPrint(
        'Religion value: $religion'); // Check if it's populated correctly

    _profileImageUrl = widget.userData?.profileImageUrl;

    // Add focus listeners
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() => setState(() {}));
    }
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

  String _getMonthName(int month) {
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

  static const List<String> religions = [
    'Roman Catholic',
    'Islam',
    'Iglesia ni Cristo',
    'Other', // Add 'Other' option
  ];

  Future<File> getFileFromAsset(String assetPath) async {
    final byteData = await rootBundle.load(assetPath); // Load the asset
    final tempDir = await getTemporaryDirectory(); // Get temp directory
    final tempFile =
        File('${tempDir.path}/${assetPath.split('/').last}'); // Create file
    return await tempFile
        .writeAsBytes(byteData.buffer.asUint8List()); // Write byte data to file
  }

  Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      // Reference to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      // Upload file
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
            contentType: 'image/jpeg'), // Ensure correct content type
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
          builder: (context) => SelectProfileImageScreen(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick a profile image.')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // Define the minimum and maximum date limits
    final DateTime today = DateTime.now();
    final DateTime minDate =
        DateTime(today.year - 120); // Set 120 years ago as the minimum
    final DateTime maxDate =
        DateTime(today.year - 1); // Ensure user is at least 1 year old

    final DateTime initialDate =
        birthday ?? maxDate; // Default to maxDate if birthday is null

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: maxDate, // Allow selecting up to the current date minus 1 year
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
        birthdayController.text =
            '${_getMonthName(picked.month)} ${picked.day}, ${picked.year}';
      });
    }
  }

  InputDecoration _buildInputDecoration(String label, FocusNode focusNode) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.gray,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.neon, width: 2)),
      labelStyle: TextStyle(
        fontSize: 16,
        fontFamily: 'Inter',
        fontWeight: FontWeight.normal,
        color: focusNode.hasFocus ? AppColors.neon : AppColors.black,
      ),
    );
  }

  Future<void> _submitForm() async {
    DatabaseService db = DatabaseService();
    final nameRegExp = RegExp(r"^[\p{L}\s]+(?:\.\s?[\p{L}]+)*$", unicode: true);

    // Validate name fields
    if (firstNameController.text.trim().isEmpty ||
        !nameRegExp.hasMatch(firstNameController.text.trim())) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid first name.')));
      return;
    }
    if (middleNameController.text.trim().isNotEmpty &&
        !nameRegExp.hasMatch(middleNameController.text.trim())) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid middle name.')));
      return;
    }
    if (lastNameController.text.trim().isEmpty ||
        !nameRegExp.hasMatch(lastNameController.text.trim())) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid last name.')));
      return;
    }

    // Phone number validation
    final phoneNumber = phoneNumberController.text.trim();
    final phoneRegExp = RegExp(r'^09\d{9}$');
    if (phoneNumber.isEmpty || !phoneRegExp.hasMatch(phoneNumber)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid phone number.')));
      return;
    }

    final isUnique = await db.isPhoneNumberUnique(phoneNumber);
    if (!isUnique) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone number already exists.')));
      return;
    }

    if (birthday == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select a birthday.')));
      return;
    }

    final age = _calculateAge(birthday);

    if (gender.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select your gender.')));
      return;
    }

    if (religion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select your religion.')));
      return;
    }

    if (addressController.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Address must be at least 5 characters long.')));
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    String? profileImageUrl = _profileImageUrl;

    if (_profileImage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Uploading profile image...')));

      try {
        profileImageUrl = await DatabaseService.uploadProfileImage(
          userId: userId,
          file: _profileImage!,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload profile image.')));
        return;
      }
    }

    await widget.onButtonPressed(
      firstName: capitalizeEachWord(firstNameController.text.trim()),
      lastName: capitalizeEachWord(lastNameController.text.trim()),
      middleName: capitalizeEachWord(middleNameController.text.trim()),
      phoneNumber: phoneNumber,
      gender: gender,
      birthday: birthday,
      address: addressController.text.trim(),
      profileImageUrl: profileImageUrl ?? '',
      religion: religion,
      age: age,
    );
  }

// Helper method to calculate age
  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;

    final currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;

    // Check if the birthday has not yet occurred this year
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String capitalizeEachWord(String text) {
    return text
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 75,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (_profileImageUrl != null &&
                                  _profileImageUrl!.isNotEmpty
                              ? (_profileImageUrl!.startsWith('http')
                                  ? NetworkImage(_profileImageUrl!)
                                  : AssetImage(_profileImageUrl!)
                                      as ImageProvider)
                              : AssetImage(
                                  'lib/assets/images/shared/placeholder.png')),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.blackTransparent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          _pickProfileImage(role!);
                        },
                        icon: Icon(Icons.camera_alt, color: AppColors.white),
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Divider(thickness: 1.0),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: firstNameController,
                focusNode: _focusNodes[0],
                decoration: _buildInputDecoration('First Name', _focusNodes[0]),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                validator: (val) =>
                    val!.isEmpty ? 'First Name cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: middleNameController,
                focusNode: _focusNodes[1],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration:
                    _buildInputDecoration('Middle Name', _focusNodes[1]),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: lastNameController,
                focusNode: _focusNodes[2],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration('Last Name', _focusNodes[2]),
                validator: (val) =>
                    val!.isEmpty ? 'Last Name cannot be empty' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: phoneNumberController,
                focusNode: _focusNodes[3],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration:
                    _buildInputDecoration('Phone Number', _focusNodes[3]),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Phone number cannot be empty';
                  }
                  if (!RegExp(r'^09\d{9}$').hasMatch(val)) {
                    return 'Invalid Phone Number';
                  }
                  return null;
                },
              ),

              // Birthday Field
              const SizedBox(height: 20),
              TextFormField(
                controller: birthdayController,
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
                    color: _focusNodes[4].hasFocus
                        ? AppColors.neon
                        : AppColors.black,
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.neon, width: 2)),
                  labelStyle: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: _focusNodes[4].hasFocus
                        ? AppColors.neon
                        : AppColors.black,
                  ),
                ),
                validator: (val) =>
                    val!.isEmpty ? 'Birthday cannot be empty' : null,
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: gender.isNotEmpty &&
                        ['Male', 'Female', 'Other'].contains(gender)
                    ? gender
                    : null,
                focusNode: _focusNodes[5],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration('Gender', _focusNodes[5]),
                items: ['Male', 'Female', 'Other']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value,
                          style:
                              TextStyle(color: AppColors.black, fontSize: 16),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => gender = val ?? ''),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Select Gender' : null,
                dropdownColor: AppColors.white,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: religion.isNotEmpty && religions.contains(religion)
                    ? religion
                    : null,
                focusNode: _focusNodes[6],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration('Religion', _focusNodes[6]),
                items: religions
                    .map(
                      (religionItem) => DropdownMenuItem(
                        value: religionItem,
                        child: Text(
                          religionItem,
                          style:
                              TextStyle(color: AppColors.black, fontSize: 16),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() {
                  religion = val ?? ''; // Update the selected religion value
                }),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Select Religion' : null,
                dropdownColor: AppColors.white,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: addressController,
                focusNode: _focusNodes[7],
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                ),
                decoration: _buildInputDecoration('Address', _focusNodes[7]),
                validator: (val) =>
                    val!.isEmpty ? 'Address cannot be empty' : null,
              ),

              const SizedBox(height: 10),
              const Divider(thickness: 1.0),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _submitForm,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 15),
                    backgroundColor: AppColors.neon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Update Profile',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
