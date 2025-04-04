// ignore_for_file: unused_element

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/services/alert_handler.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/error_handler.dart';
import 'package:solace/shared/accountflow/user_editprofile.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';

class RoleChooser extends StatefulWidget {
  final Function(String) onRoleSelected;

  const RoleChooser({super.key, required this.onRoleSelected});

  @override
  State<RoleChooser> createState() => _RoleChooserState();
}

class _RoleChooserState extends State<RoleChooser> {
  final DatabaseService db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  String? _selectedRole;
  late FocusNode _roleFocusNode;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _roleFocusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Try to get userData from navigation arguments
    final userData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (userData == null || userData.isEmpty) {
      debugPrint("No userData received. Fetching from Firestore...");
      _fetchUserDocument();
    } else {
      debugPrint("Received userData: $userData");
    }
  }

  @override
  void dispose() {
    _roleFocusNode.dispose();
    super.dispose();
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

  Future<void> _fetchUserDocument() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError(["User not logged in. Please try again."]);
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('unregistered') // Adjust collection if needed
              .doc(user.uid)
              .get();

      if (doc.exists && doc.data() != null) {
        final fetchedData = doc.data()!;
        debugPrint("User document fetched: $fetchedData");

        setState(() {
          // Assign the fetched userData
          _userData = fetchedData;
        });
      } else {
        debugPrint("No user document found for ${user.uid}");
      }
    } catch (e) {
      debugPrint("Error fetching user document: $e");
      _showError(["Failed to fetch user data. Please try again."]);
    }
  }

  void _showAlert(List<String> messages) {
    if (messages.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
              AlertHandler(title: 'Action Required', messages: messages),
    );
  }

  void _continue() async {
    if (_formKey.currentState!.validate() && _selectedRole != null) {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showError(["User not logged in. Please try again."]);
        return;
      }

      final userData =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
          _userData; // Use fetched data if arguments are null

      if (userData == null || userData.isEmpty) {
        _showError([
          "Incomplete or invalid user data. Please restart the verification process.",
        ]);
        return;
      }

      try {
        final firestore = FirebaseFirestore.instance;
        final targetCollection = _selectedRole!;
        final targetRef = firestore.collection(targetCollection).doc(user.uid);

        // Perform a transaction to move user to the correct collection
        await firestore.runTransaction((transaction) async {
          transaction.set(targetRef, {...userData, 'userRole': _selectedRole});
          transaction.delete(
            firestore.collection('unregistered').doc(user.uid),
          );
        });

        // Cache the user role
        await db.cacheUserRole(user.uid, _selectedRole!);

        debugPrint(
          "User document transferred to '$targetCollection' collection and role cached as '$_selectedRole'.",
        );

        // Update userData locally with the new role
        userData['userRole'] = _selectedRole;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(userData: userData),
          ),
        );
      } catch (e) {
        debugPrint("Error transferring user document: $e");
        _showError(["Failed to transfer user data. Please try again."]);
      }
    } else {
      _showAlert(["Choose your role within the app."]);
    }
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
                      Text('What is your role?', style: Textstyle.title),
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
                          dropdownColor: AppColors.white,
                          focusNode: _roleFocusNode,
                          decoration: InputDecoration(
                            labelText: "Select your role",
                            labelStyle: Textstyle.body,
                            floatingLabelStyle: Textstyle.bodyNeon,
                            filled: true,
                            fillColor: AppColors.gray,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color:
                                    AppColors.neon, // Border color when focused
                                width: 2.0,
                              ),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin', style: Textstyle.body),
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
                              child: Text('Doctor', style: Textstyle.body),
                            ),
                            DropdownMenuItem(
                              value: 'nurse',
                              child: Text('Nurse', style: Textstyle.body),
                            ),
                          ],
                          value: _selectedRole,
                          onChanged:
                              (value) => setState(() => _selectedRole = value),
                          validator:
                              (value) =>
                                  value == null ? 'Please select a role' : null,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _selectedRole == null ? null : _continue,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      backgroundColor:
                          _selectedRole == null ? Colors.grey : AppColors.neon,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Continue', style: Textstyle.largeButton),
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
