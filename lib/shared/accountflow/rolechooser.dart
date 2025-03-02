// ignore_for_file: unused_element

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/shared/accountflow/user_editprofile.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/models/my_user.dart';

class RoleChooser extends StatefulWidget {
  final Function(String) onRoleSelected;

  const RoleChooser({super.key, required this.onRoleSelected});

  @override
  State<RoleChooser> createState() => _RoleChooserState();
}

class _RoleChooserState extends State<RoleChooser> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRole;
  late FocusNode _roleFocusNode;

  @override
  void initState() {
    super.initState();
    _roleFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _roleFocusNode.dispose();
    super.dispose();
  }

  void _continue() async {
    if (_formKey.currentState!.validate() && _selectedRole != null) {
      final user = Provider.of<MyUser?>(context, listen: false);

      if (user == null) {
        _showErrorDialog("Error", "User not logged in. Please try again.");
        return;
      }

      try {
        final firestore = FirebaseFirestore.instance;
        final unregisteredRef =
            firestore.collection('unregistered').doc(user.uid);
        final unregisteredDoc = await unregisteredRef.get();

        if (!unregisteredDoc.exists) {
          debugPrint(
              "User document not found in 'unregistered' collection for UID: ${user.uid}");
          _showErrorDialog(
              "Error", "User document not found in 'unregistered' collection.");
          return;
        }

        final userData = unregisteredDoc.data();
        if (userData == null) {
          _showErrorDialog(
              "Error", "User data is empty in 'unregistered' document.");
          return;
        }

        final targetCollection = _selectedRole!;
        final targetRef = firestore.collection(targetCollection).doc(user.uid);

        await targetRef.set({
          ...userData,
          'userRole': _selectedRole,
        });

        await unregisteredRef.delete();

        debugPrint(
            "User document transferred to '$targetCollection' collection.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
        );
      } catch (e) {
        debugPrint("Error transferring user document: $e");
        _showErrorDialog(
            "Error", "Failed to transfer user data. Please try again.");
      }
    } else {
      _showAlertDialog(context);
    }
  }

  Future<Map<String, String>?> _findUserInCollections(String uid) async {
    final List<String> collections = [
      'admin',
      'doctor',
      'caregiver',
      'patient',
      'unregistered'
    ];

    for (String collection in collections) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection(collection)
          .doc(uid)
          .get();

      if (docSnapshot.exists) {
        return {
          'role': collection.substring(
              0, collection.length - 1), // Singular role name
          'collection': collection,
        };
      }
    }

    // Return null if user is not found
    return null;
  }

  UserRole _mapStringToUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'caregiver':
        return UserRole.caregiver;
      case 'doctor':
        return UserRole.doctor;
      case 'patient':
        return UserRole.patient;
      default:
        throw Exception("Invalid role string: $role");
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
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.neon,
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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

  Future<void> _showErrorDialog(String title, String message) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.normal,
              color: AppColors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.neon,
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('lib/assets/images/auth/role.png'),
                      const SizedBox(height: 20),
                      const Text(
                        'What is your role?',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 30),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Every role matters in SOLACE',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: DropdownButtonFormField<String>(
                          dropdownColor: AppColors.white,
                          focusNode: _roleFocusNode,
                          decoration: InputDecoration(
                            labelText: "Select your role",
                            labelStyle: const TextStyle(
                              color: AppColors.black, // Default label color
                            ),
                            floatingLabelStyle: const TextStyle(
                              color: AppColors.neon, // Label color when focused
                            ),
                            filled: true,
                            fillColor: AppColors.gray,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.neon, // Border color when focused
                                width: 2.0,
                              ),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'caregiver', child: Text('Caregiver')),
                            DropdownMenuItem(
                                value: 'doctor', child: Text('Doctor')),
                            DropdownMenuItem(
                                value: 'admin', child: Text('Admin')),
                          ],
                          value: _selectedRole,
                          onChanged: (value) =>
                              setState(() => _selectedRole = value),
                          validator: (value) =>
                              value == null ? 'Please select a role' : null,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _continue,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: AppColors.neon,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white),
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
