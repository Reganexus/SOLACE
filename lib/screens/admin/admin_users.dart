// ignore_for_file: unrelated_type_equality_checks, avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:solace/models/my_patient.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/admin/admin_logs.dart';
import 'package:solace/screens/admin/delete_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  AdminUsersState createState() => AdminUsersState();
}

class AdminUsersState extends State<AdminUsers> {
  bool _isAscending = true; // Track the current sort order (default: ascending)
  String _selectedRole = 'caregiver'; // Default role
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<dynamic> filteredUsers = [];
  List<dynamic> allUsers = [];

  @override
  void initState() {
    super.initState();
    _refreshUserList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _refreshUserList() {
    if (mounted) {
      setState(() {
        allUsers = []; // Clear the previous list to avoid flickering.
        filteredUsers = []; // Clear the filtered list.
      });
    }

    if (_selectedRole == 'patient') {
      _fetchPatients().listen((patients) {
        if (mounted) {
          setState(() {
            allUsers = patients;
            filteredUsers = List.from(allUsers);
            _sortUsers(); // Sort the list after fetching
          });
        }
      }).onError((error) {
        _showErrorSnackBar('Error fetching patients.');
      });
    } else if (_selectedRole == 'caregiver') {
      _fetchCaregivers().listen((caregivers) {
        if (mounted) {
          setState(() {
            allUsers = caregivers;
            filteredUsers = List.from(allUsers);
            _sortUsers(); // Sort the list after fetching
          });
        }
      }).onError((error) {
        _showErrorSnackBar('Error fetching caregivers.');
      });
    } else if (_selectedRole == 'doctor') {
      _fetchDoctors().listen((doctors) {
        if (mounted) {
          setState(() {
            allUsers = doctors;
            filteredUsers = List.from(allUsers);
            _sortUsers(); // Sort the list after fetching
          });
        }
      }).onError((error) {
        _showErrorSnackBar('Error fetching caregivers.');
      });
    } else if (_selectedRole == 'admin') {
      _fetchAdmins().listen((admins) {
        if (mounted) {
          setState(() {
            allUsers = admins;
            filteredUsers = List.from(allUsers);
            _sortUsers(); // Sort the list after fetching
          });
        }
      }).onError((error) {
        _showErrorSnackBar('Error fetching caregivers.');
      });
    }
  }

  void _filterUsers(String query) {
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          filteredUsers = List.from(allUsers);
        } else {
          filteredUsers = allUsers.where((user) {
            final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
            return fullName.contains(query.toLowerCase());
          }).toList();
        }
        _sortUsers(); // Apply sorting after filtering
      });
    }
  }

  void _sortUsers() {
    if (mounted) {
      setState(() {
        filteredUsers.sort((a, b) => _isAscending
            ? a.firstName.compareTo(b.firstName) // Ascending order
            : b.firstName.compareTo(a.firstName)); // Descending order
      });
    }
  }

  void toggleSortOrder() {
    if (mounted) {
      setState(() {
        _isAscending = !_isAscending; // Toggle the sort order
        _sortUsers(); // Reapply sorting
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Stream<List<PatientData>> _fetchPatients() {
    return FirebaseFirestore.instance.collection('patient').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => PatientData.fromDocument(doc))
              .where((patient) => patient != null)
              .toList(),
        );
  }

  Stream<List<UserData>> _fetchCaregivers() {
    return FirebaseFirestore.instance.collection('caregiver').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => UserData.fromDocument(doc))
              .where((caregiver) => caregiver != null)
              .toList(),
        );
  }

  Stream<List<UserData>> _fetchDoctors() {
    return FirebaseFirestore.instance.collection('doctor').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => UserData.fromDocument(doc))
              .where((doctor) => doctor != null)
              .toList(),
        );
  }

  Stream<List<UserData>> _fetchAdmins() {
    return FirebaseFirestore.instance.collection('admin').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => UserData.fromDocument(doc))
              .where((admin) => admin != null)
              .toList(),
        );
  }

  void _showUserDetailsDialog(BuildContext context, dynamic user) {
    debugPrint("Admin Users user: $user");
    if (user is UserData || user is PatientData) {
      final String userName = '${user.firstName} ${user.lastName}';
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.white,
            title: Text(
              'Manage $userName',
              style: const TextStyle(
                fontSize: 24,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            content: const Text(
              'Choose an action for this user.',
              style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  color: AppColors.black),
            ),
            actions: [
              Row(
                children: [
                  // View Logs Button
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog first
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminLogs(currentUserId: user.uid, userName: userName),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        backgroundColor: AppColors.blue, // Adjust color as needed
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'View Logs',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close this dialog
                        _showDeleteUserDialog(context, user.uid, userName);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        backgroundColor: AppColors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Delete User',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Cancel and close the dialog
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        backgroundColor: AppColors.neon,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    } else {
      throw ArgumentError('Unsupported user type');
    }
  }

  void _showDeleteUserDialog(
      BuildContext context, String uid, String userName) {
    showDialog(
      context: context,
      builder: (context) {
        return DeleteUserDialog(
          userName: userName,
          onCancel: () {
            Navigator.of(context)
                .pop(); // Close the dialog without doing anything
          },
          onConfirm: () async {
            debugPrint("Delete User id: $uid");
            await DatabaseService().deleteUser(uid);
            _refreshUserList();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, FocusNode focusNode) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.gray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
        borderSide: const BorderSide(
          color: AppColors.neon,
          width: 2,
        ),
      ),
      labelStyle: const TextStyle(color: AppColors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: AppColors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // Search TextField container
                      Expanded(
                        child: Container(
                          height: double.infinity, // Match height of the Row
                          decoration: BoxDecoration(
                            color: AppColors
                                .gray, // Background color for TextField
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(
                                  10), // Rounded corners for left side
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            onChanged: _filterUsers,
                            decoration: _inputDecoration('Search', _focusNode),
                          ),
                        ),
                      ),
                      // Dropdown container
                      Container(
                        width: 120, // Fixed width for DropdownButton
                        height: double.infinity, // Match height of the Row
                        decoration: BoxDecoration(
                          color: AppColors
                              .gray, // Background color for DropdownButton
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(
                                10), // Rounded corners for right side
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            onChanged: (role) {
                              if (role != null) {
                                if (mounted) {
                                  setState(() {
                                    _selectedRole = role;
                                    _searchController.clear();
                                    _refreshUserList();
                                  });
                                }
                              }
                            },
                            items: ['admin', 'caregiver', 'doctor', 'patient']
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Text(
                                          role.capitalize(),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ))
                                .toList(),
                            icon: const Icon(Icons.arrow_drop_down),
                            isExpanded: true,
                            dropdownColor: AppColors
                                .white, // Match Dropdown background color
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  fit: FlexFit
                      .loose, // Allows the child to shrink-wrap its content
                  child: filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 50,
                                color: AppColors.black,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No ${_selectedRole}s available',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  fontFamily: 'Inter',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            if (_selectedRole == 'patient' &&
                                user is PatientData) {
                              return _buildPatientItem(user);
                            } else if (_selectedRole == 'caregiver') {
                              return _buildCaregiverItem(user as UserData);
                            } else if (_selectedRole == 'doctor') {
                              return _buildDoctorItem(user as UserData);
                            } else {
                              return _buildAdminItem(user as UserData);
                            }
                          },
                        ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientItem(PatientData patient) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          // Profile image
          CircleAvatar(
            backgroundImage: (patient.profileImageUrl != null && patient.profileImageUrl!.isNotEmpty)
                ? NetworkImage(patient.profileImageUrl!)
                : const AssetImage('lib/assets/images/shared/placeholder.png') as ImageProvider,
            radius: 24.0,
          ),
          const SizedBox(width: 10.0),
          // Full name with ellipsis
          Expanded(
            child: Text(
              '${patient.firstName} ${patient.lastName}',
              style: const TextStyle(
                fontSize: 18.0,
                fontFamily: 'Inter',
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis, // Add ellipsis
            ),
          ),
          // Menu button
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.black),
            onPressed: () => _showUserDetailsDialog(context, patient),
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverItem(UserData caregiver) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          // Profile image
          CircleAvatar(
            backgroundImage: caregiver.profileImageUrl.isNotEmpty
                ? NetworkImage(caregiver.profileImageUrl)
                : const AssetImage('lib/assets/images/shared/placeholder.png')
                    as ImageProvider,
            radius: 24.0,
          ),
          const SizedBox(width: 10.0),
          // Full name with ellipsis
          Expanded(
            child: Text(
              '${caregiver.firstName} ${caregiver.lastName}',
              style: const TextStyle(
                fontSize: 18.0,
                fontFamily: 'Inter',
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis, // Add ellipsis
            ),
          ),
          // Menu button
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.black),
            onPressed: () => _showUserDetailsDialog(context, caregiver),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorItem(UserData doctor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          // Profile image
          CircleAvatar(
            backgroundImage: doctor.profileImageUrl.isNotEmpty
                ? NetworkImage(doctor.profileImageUrl)
                : const AssetImage('lib/assets/images/shared/placeholder.png')
                    as ImageProvider,
            radius: 24.0,
          ),
          const SizedBox(width: 10.0),
          // Full name with ellipsis
          Expanded(
            child: Text(
              '${doctor.firstName} ${doctor.lastName}',
              style: const TextStyle(
                fontSize: 18.0,
                fontFamily: 'Inter',
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis, // Add ellipsis
            ),
          ),
          // Menu button
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.black),
            onPressed: () => _showUserDetailsDialog(context, doctor),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminItem(UserData admin) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          // Profile image
          CircleAvatar(
            backgroundImage: admin.profileImageUrl.isNotEmpty
                ? NetworkImage(admin.profileImageUrl)
                : const AssetImage('lib/assets/images/shared/placeholder.png')
                    as ImageProvider,
            radius: 24.0,
          ),
          const SizedBox(width: 10.0),
          // Full name with ellipsis
          Expanded(
            child: Text(
              '${admin.firstName} ${admin.lastName}',
              style: const TextStyle(
                fontSize: 18.0,
                fontFamily: 'Inter',
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis, // Add ellipsis
            ),
          ),
          // Menu button
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.black),
            onPressed: () => _showUserDetailsDialog(context, admin),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
