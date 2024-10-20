import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';
import 'dart:io'; // For File class on mobile/desktop
import 'dart:typed_data'; // For Uint8List on web
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  final TextEditingController _newPasswordController = TextEditingController();
  final FocusNode _newPasswordFocusNode = FocusNode();

  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  File? _imageFile; // For mobile/desktop
  Uint8List? _imageBytes; // For web

  @override
  void initState() {
    super.initState();

    // Add listeners to each focus node to rebuild when focused state changes
    _emailFocusNode.addListener(() => setState(() {}));
    _phoneFocusNode.addListener(() => setState(() {}));
    _newPasswordFocusNode.addListener(() => setState(() {}));
    _confirmPasswordFocusNode.addListener(() => setState(() {}));
    _nameFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // Dispose of the controllers and focus nodes
    _emailController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // If on the web, use Image.memory with byte data
        final bytes =
            await pickedFile.readAsBytes(); // Read bytes asynchronously
        setState(() {
          _imageBytes = bytes; // Update the state synchronously
        });
      } else {
        // For mobile/desktop platforms, use File
        setState(() {
          _imageFile = File(pickedFile.path); // Update the state synchronously
        });
      }
    }
  }

  // Function to build each TextFormField with dynamic styles
  Widget _buildTextFormField({
    required String labelText,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool obscureText = false,
    bool isPasswordField = false,
    bool isPasswordVisible = false,
    VoidCallback? togglePasswordVisibility,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: AppColors.gray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.neon,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: focusNode.hasFocus ? AppColors.neon : AppColors.black,
        ),
        suffixIcon: isPasswordField
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: focusNode.hasFocus ? AppColors.neon : AppColors.black,
                ),
                onPressed: togglePasswordVisibility,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: Container(
        color: AppColors.white,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile Details',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 20),

              // Profile Picture with Edit Icon
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: kIsWeb
                          ? (_imageBytes != null
                              ? MemoryImage(_imageBytes!)
                              : const AssetImage(
                                      'lib/assets/images/shared/placeholder.png')
                                  as ImageProvider)
                          : (_imageFile != null
                              ? FileImage(_imageFile!)
                              : const AssetImage(
                                  'lib/assets/images/shared/placeholder.png')),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          backgroundColor: AppColors.neon,
                          radius: 18,
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Name Input Field
              _buildTextFormField(
                labelText: 'Name',
                controller: _nameController,
                focusNode: _nameFocusNode,
              ),
              const SizedBox(height: 20),

              // Email Input Field
              _buildTextFormField(
                labelText: 'Email',
                controller: _emailController,
                focusNode: _emailFocusNode,
              ),
              const SizedBox(height: 20),

              // Phone Number Input Field
              _buildTextFormField(
                labelText: 'Phone Number',
                controller: _phoneController,
                focusNode: _phoneFocusNode,
              ),
              const SizedBox(height: 20),

              // New Password Input Field
              _buildTextFormField(
                labelText: 'New Password',
                controller: _newPasswordController,
                focusNode: _newPasswordFocusNode,
                obscureText: !_isNewPasswordVisible,
                isPasswordField: true,
                isPasswordVisible: _isNewPasswordVisible,
                togglePasswordVisibility: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Confirm Password Input Field
              _buildTextFormField(
                labelText: 'Confirm Password',
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocusNode,
                obscureText: !_isConfirmPasswordVisible,
                isPasswordField: true,
                isPasswordVisible: _isConfirmPasswordVisible,
                togglePasswordVisibility: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Save and Cancel Buttons in a Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        // Save action logic here
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.neon,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // Add spacing between buttons
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Discard changes and go back
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
