// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/screens/home/home.dart';
import 'package:solace/screens/wrapper.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/accountflow/user_data_form.dart';
import 'package:solace/services/log_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);
    final LogService logService = LogService();
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<UserData?>(
      future: DatabaseService(uid: user.uid).getUserData(),
      builder: (context, snapshot) {
        final stateWidget = _buildFutureState(snapshot);
        if (stateWidget != null) return stateWidget;

        final userData = snapshot.data!;
        final showBackButton = !userData.newUser && userData.isVerified;

        return PopScope(
          canPop: showBackButton,
          onPopInvokedWithResult: (canPop, result) async {
            if (canPop && _hasChanges) {
              final shouldProceed = await _showUnsavedChangesDialog(context);
              if (shouldProceed) {
                if (Navigator.canPop(context)) {
                  Future.microtask(() {
                    Navigator.of(context).pop(result);
                  });
                } else {
                  debugPrint("No routes to pop");
                }
              }
              // Do nothing if the user cancels
            } else if (canPop) {
              if (Navigator.canPop(context)) {
                Future.microtask(() {
                  Navigator.of(context).pop(result);
                });
              } else {
                debugPrint("No routes to pop");
              }
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppBar(
              title: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              backgroundColor: AppColors.white,
              scrolledUnderElevation: 0.0,
              automaticallyImplyLeading: showBackButton,
              leading:
                  showBackButton
                      ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () async {
                          if (_hasChanges) {
                            final shouldProceed =
                                await _showUnsavedChangesDialog(context);
                            if (shouldProceed) Navigator.pop(context);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      )
                      : null,
            ),
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
                  child: Column(
                    children: [
                      UserDataForm(
                        age: userData.age ?? 0,
                        userData: userData,
                        newUser: userData.newUser,
                        isVerified: userData.isVerified,
                        userRole: userData.userRole,
                        onFieldChanged: () {
                          setState(() {
                            _hasChanges = true;
                          });
                        },
                        onButtonPressed: ({
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
                        }) async {
                          await DatabaseService(uid: user.uid).updateUserData(
                            userRole: userData.userRole,
                            firstName: firstName,
                            lastName: lastName,
                            middleName: middleName,
                            phoneNumber: phoneNumber,
                            gender: gender,
                            birthday: birthday,
                            address: address,
                            profileImageUrl: profileImageUrl,
                            religion: religion,
                            newUser: false,
                            isVerified: true,
                            age: age,
                          );

                          if (mounted) {
                            // Add log entry
                            await logService.addLog(
                              userId: user.uid,
                              action: 'Edited profile',
                            );

                            ScaffoldMessenger.of(
                              context,
                            ).removeCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully'),
                              ),
                            );
                            setState(() {
                              _hasChanges = false;
                            });
                            // Navigate to Home() and clear navigation stack
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Wrapper(),
                              ),
                              (route) => false, // Remove all previous routes
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showUnsavedChangesDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes. Do you want to discard them and go back?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
  }

  Widget? _buildFutureState(AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (snapshot.hasError) {
      return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
    } else if (!snapshot.hasData || snapshot.data == null) {
      return const Scaffold(body: Center(child: Text("No user data found.")));
    }
    return null;
  }
}
