import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/services/error_handler.dart';
import 'package:solace/shared/accountflow/user_editprofile.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class RoleChooser extends StatefulWidget {
  final Function(String) onRoleSelected;

  const RoleChooser({super.key, required this.onRoleSelected});

  @override
  State<RoleChooser> createState() => _RoleChooserState();
}

class _RoleChooserState extends State<RoleChooser> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRole;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  final FocusNode dropdownFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (_userData == null) _fetchUserDocument();
    debugPrint("User data: $_userData");
  }

  @override
  void dispose() {
    dropdownFocusNode.dispose();
    super.dispose();
  }

  void _showError(List<String> errorMessages) {
    if (errorMessages.isNotEmpty && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => ErrorDialog(title: 'Error', messages: errorMessages),
      );
    }
  }

  void _navigateToEditProfile() {
    if (mounted) {
      debugPrint("Selected role: $_selectedRole");
      debugPrint("User data: $_userData");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => EditProfileScreen(
                userData: _userData!,
                userRole: _selectedRole!,
              ),
        ),
      );
    }
  }

  Future<void> _fetchUserDocument() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) _showError(["User not logged in. Please try again."]);
        return;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('unregistered')
              .doc(user.uid)
              .get();

      if (doc.exists && doc.data() != null) {
        if (mounted) setState(() => _userData = doc.data());
      } else {
        if (mounted) _showError(["No user document found. Please try again."]);
      }
    } catch (e) {
      if (mounted) _showError(["Failed to fetch user data. Please try again."]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showConfirmationDialog() async {
    final shouldProceed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                backgroundColor: AppColors.white,
                title: Text(
                  'Confirm Role Selection',
                  style: Textstyle.subheader,
                ),
                content: Text(
                  'You selected "${_selectedRole ?? ''}" as a role. Do you want to proceed?',
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
              ),
        ) ??
        false;

    if (shouldProceed) _navigateToEditProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Column(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'lib/assets/images/auth/role.png',
                                semanticLabel: 'Role selection image',
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'What is your role?',
                                style: Textstyle.title,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Every role matters in SOLACE',
                                textAlign: TextAlign.center,
                                style: Textstyle.body,
                              ),
                              const SizedBox(height: 20),
                              Form(
                                key: _formKey,
                                child: DropdownButtonFormField<String>(
                                  focusNode: dropdownFocusNode,
                                  decoration: InputDecoration(
                                    labelText: "Select your role",
                                    filled: true,
                                    fillColor: AppColors.gray,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color:
                                            dropdownFocusNode.hasFocus
                                                ? AppColors.neon
                                                : AppColors.whiteTransparent,
                                        width: 2,
                                      ),
                                    ),
                                    labelStyle: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.normal,
                                      color:
                                          dropdownFocusNode.hasFocus
                                              ? AppColors.neon
                                              : AppColors.black,
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'admin',
                                      child: Text(
                                        'Admin',
                                        style: Textstyle.body,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'caregiver',
                                      child: Text(
                                        'Caregiver (Bedside caregiver)',
                                        style: Textstyle.body,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'doctor',
                                      child: Text(
                                        'Doctor',
                                        style: Textstyle.body,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'nurse',
                                      child: Text(
                                        'Nurse',
                                        style: Textstyle.body,
                                      ),
                                    ),
                                  ],
                                  value: _selectedRole,
                                  onChanged:
                                      (value) =>
                                          setState(() => _selectedRole = value),
                                  validator:
                                      (value) =>
                                          value == null
                                              ? 'Please select a role'
                                              : null,
                                  dropdownColor: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed:
                                _selectedRole == null
                                    ? null
                                    : _showConfirmationDialog,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                              backgroundColor:
                                  _selectedRole == null
                                      ? Colors.grey
                                      : AppColors.neon,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: Textstyle.largeButton,
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
