// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:solace/services/database.dart';  // Import your DatabaseService
import 'package:solace/shared/accountflow/user_editprofile.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/models/my_user.dart'; // Assuming you have the MyUser model
import 'package:provider/provider.dart'; // Import Provider for accessing the current user

class RoleChooser extends StatefulWidget {
  const RoleChooser({super.key});

  @override
  State<RoleChooser> createState() => _RoleChooserState();
}

class _RoleChooserState extends State<RoleChooser> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRole;
  late FocusNode _roleFocusNode; // Focus node for the dropdown

  @override
  void initState() {
    super.initState();
    _roleFocusNode = FocusNode(); // Initialize the focus node
  }

  @override
  void dispose() {
    _roleFocusNode.dispose(); // Dispose the focus node when done
    super.dispose();
  }

  Future<void> _updateUserRoleAndNavigate(String selectedRole) async {
    try {
      final user = Provider.of<MyUser?>(context, listen: false);
      if (user != null) {
        final role = UserRole.values.firstWhere(
                (e) => e.toString().split('.').last == selectedRole,
            orElse: () => UserRole.patient);

        await DatabaseService(uid: user.uid).updateUserRole(user.uid, role);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
        );
      }
    } catch (e) {
      print("Error updating role: $e");
    }
  }

  void _continue() {
    if (_formKey.currentState!.validate() && _selectedRole != null) {
      _updateUserRoleAndNavigate(_selectedRole!);
    } else {
      _showAlertDialog(context); // Show alert if no role selected
    }
  }

  Future<void> _showAlertDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text(
            'Action Required',
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: const Text(
            'Please select a role to continue.',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.normal,
              color: AppColors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.neon,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showAlertDialog(context);
        return false; // Prevent navigation back
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus(); // Remove focus when tapping outside
            },
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'lib/assets/images/auth/role.png',
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'What is your role?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                              fontSize: 30,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Every role matters in SOLACE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontFamily: 'Inter',
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Form(
                            key: _formKey,
                            child: Focus(
                              onFocusChange: (hasFocus) {
                                setState(() {}); // Rebuild on focus change
                              },
                              child: DropdownButtonFormField<String>(
                                focusNode: _roleFocusNode, // Use the focus node
                                dropdownColor: AppColors.white,
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
                                    borderSide: BorderSide(color: AppColors.neon, width: 2),
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.normal,
                                    color: _roleFocusNode.hasFocus
                                        ? AppColors.neon // Change color when focused
                                        : AppColors.black,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'patient',
                                    child: Text('Patient'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'caregiver',
                                    child: Text('Caregiver'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'doctor',
                                    child: Text('Doctor'),
                                  ),
                                ],
                                value: _selectedRole,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value;
                                  });
                                },
                                validator: (value) =>
                                value == null ? 'Please select a role' : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _continue,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                        backgroundColor: AppColors.neon,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
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

