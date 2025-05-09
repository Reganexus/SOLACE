// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/screens/admin/admin_home.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';

class EditUserRoleDialog extends StatefulWidget {
  final String uid;
  const EditUserRoleDialog({super.key, required this.uid});

  @override
  EditUserRoleDialogState createState() => EditUserRoleDialogState();
}

class EditUserRoleDialogState extends State<EditUserRoleDialog> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LogService _logService = LogService();
  final DatabaseService db = DatabaseService();
  String? _userName = '';
  String? _selectedRole;
  String? _currentRole;
  bool _isSaving = false;
  bool _isLoading = true;

  final FocusNode _dropdownFocusNode = FocusNode();
  final List<String> allRoles = ['caregiver', 'nurse', 'doctor', 'admin'];

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _fetchUserName();
  }

  @override
  void dispose() {
    _dropdownFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchUserName() async {
    try {
      final userName = await db.fetchUserName(widget.uid);
      setState(() {
        _userName = userName;
        _isLoading = false;
      });
    } catch (e) {
      showToast("Failed to fetch user name.", 
          backgroundColor: AppColors.red);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      final role = await db.fetchAndCacheUserRole(widget.uid);
      setState(() {
        _currentRole = role;
        _isLoading = false;
      });
    } catch (e) {
      showToast("Failed to fetch user role.", 
          backgroundColor: AppColors.red);
      setState(() => _isLoading = false);
    }
  }

  void _changeUserRole() async {
    if (_selectedRole == null || _selectedRole!.isEmpty) {
      showToast("Please select a new role before submitting.", 
          backgroundColor: AppColors.red);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final currentRole = await db.fetchAndCacheUserRole(widget.uid);
      if (currentRole == null) {
        showToast("Error: Unable to determine the current role.", 
            backgroundColor: AppColors.red);
        return;
      }

      if (currentRole == _selectedRole) {
        showToast("The user is already assigned to the selected role.", 
            backgroundColor: AppColors.red);
        return;
      }

      await firestore.runTransaction((transaction) async {
        final currentDocRef = firestore.collection(currentRole).doc(widget.uid);
        final newDocRef = firestore.collection(_selectedRole!).doc(widget.uid);

        final currentDocSnapshot = await transaction.get(currentDocRef);
        if (!currentDocSnapshot.exists) {
          throw Exception(
            "User document not found in collection: $currentRole.",
          );
        }

        final userData = currentDocSnapshot.data();
        if (userData == null) {
          throw Exception("User data is empty.");
        }

        transaction.set(newDocRef, {...userData, 'userRole': _selectedRole!});

        transaction.delete(currentDocRef);
      });

      final user = _auth.currentUser;
      if (user?.uid == null) {
//         debugPrint("Warning: Authenticated user not found.");
      } else {
        await _logService.addLog(
          userId: user!.uid,
          action: "Updated role for $_userName",
        );
      }

      showToast("User role updated successfully.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminHome()),
      );
    } catch (e) {
//       debugPrint("Error during role change: $e");
      showToast("Failed to update role. Please try again.", 
          backgroundColor: AppColors.red);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    List<String> filteredRoles =
        _currentRole != null
            ? allRoles.where((role) => role != _currentRole).toList()
            : allRoles;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text("Change User Role", style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: _isLoading ? false : true,
      ),
      body:
          _isLoading
              ? Center(child: Loader.loaderPurple)
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select the following role you want to change",
                      style: Textstyle.body,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedRole,
                      focusNode: _dropdownFocusNode,
                      hint: Text("Select Role", style: Textstyle.body),
                      decoration: InputDecoration(
                        labelText: "Select Role",
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
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.normal,
                          color:
                              _dropdownFocusNode.hasFocus
                                  ? AppColors.neon
                                  : AppColors.black,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                        color: AppColors.black,
                      ),
                      onChanged:
                          _isSaving
                              ? null
                              : (value) {
                                setState(() => _selectedRole = value);
                              },
                      items:
                          filteredRoles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(
                                    role[0].toUpperCase() + role.substring(1),
                                    style: Textstyle.body,
                                  ),
                                ),
                              )
                              .toList(),

                      dropdownColor: AppColors.white,
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed:
                            (_selectedRole == null || _isSaving)
                                ? null
                                : _changeUserRole,
                        style:
                            _selectedRole == null
                                ? Buttonstyle.buttonGray
                                : Buttonstyle.buttonNeon,
                        child:
                            _isSaving
                                ? Loader.loaderWhite
                                : Text("Submit", style: Textstyle.smallButton),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
