// ignore_for_file: unrelated_type_equality_checks, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/admin/delete_user.dart';
import 'package:solace/screens/admin/edit_role.dart';
import 'package:solace/shared/widgets/user_details.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  AdminUsersState createState() => AdminUsersState();
}

class AdminUsersState extends State<AdminUsers> {
  String _sortOrder = 'A-Z';
  String _selectedRole = 'patient'; // Default to 'patient'
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<UserData> filteredPatients = [];
  List<UserData> allPatients = []; // Store all patients for searching

  @override
  void initState() {
    super.initState();
    _refreshPatientList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Filter Patients by name
  void _filterPatients(String query) {
    if (mounted) {
      // Check if the widget is still mounted
      setState(() {
        if (query.isEmpty) {
          // Reset filteredPatients to match the selected role
          filteredPatients = allPatients
              .where((patient) => patient.userRole == _selectedRole)
              .toList();
        } else {
          filteredPatients = allPatients.where((patient) {
            final fullName =
                '${patient.firstName} ${patient.lastName}'.toLowerCase();
            return fullName.contains(query.toLowerCase());
          }).toList();
        }
        _sortPatients(); // Apply sorting after filtering
      });
    }
  }

  void _filterByRole(String role) {
    if (mounted) {
      // Ensure the widget is still mounted
      setState(() {
        _selectedRole = role; // Update the selected role
        _searchController.clear(); // Clear the search bar value
        _refreshPatientList(); // Refresh the list for the new role
      });
    }
  }

  // Sort Patients based on the selected order
  void _sortPatients() {
    if (mounted) {
      // Check if the widget is still mounted
      setState(() {
        if (_sortOrder == 'A-Z') {
          filteredPatients.sort((a, b) => a.firstName.compareTo(b.firstName));
        } else {
          filteredPatients.sort((a, b) => b.firstName.compareTo(a.firstName));
        }
      });
    }
  }

  // Toggle Sort Order
  void _toggleSortOrder() {
    if (mounted) {
      // Check if the widget is still mounted
      setState(() {
        _sortOrder = _sortOrder == 'A-Z' ? 'Z-A' : 'A-Z';
        _sortPatients(); // Sort after toggling
      });
    }
  }

  // Build the Patient Item UI
  Widget _buildPatientItem(UserData patient) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          // Display profile image if available, otherwise show a placeholder
          CircleAvatar(
            backgroundImage: patient.profileImageUrl.isNotEmpty
                ? NetworkImage(patient.profileImageUrl)  // Use network image if available
                : AssetImage('lib/assets/images/shared/placeholder.png') as ImageProvider,  // Fallback to placeholder
            radius: 24.0,
          ),
          const SizedBox(width: 10.0),
          // Display patient's full name
          Text(
            '${patient.firstName} ${patient.lastName}',
            style: const TextStyle(
              fontSize: 18.0,
              fontFamily: 'Inter',
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetailsDialog(BuildContext context, UserData patient) {
    showDialog(
      context: context,
      builder: (context) {
        return UserDetailsDialog(
          user: patient,
          isAdminView: true,
          onEditRole: () {
            _showEditRoleDialog(context, patient); // Show Edit Role Dialog
          },
          onDeleteUser: () {
            _showDeleteUserDialog(context, patient); // Show Delete User Dialog
          },
        );
      },
    );
  }

  // Show User Details Dialog
  void _showDeleteUserDialog(BuildContext context, UserData patient) {
    showDialog(
      context: context,
      builder: (context) {
        return DeleteUserDialog(
          userName: '${patient.firstName} ${patient.lastName}',
          onCancel: () {
            Navigator.of(context)
                .pop(); // Close the dialog without doing anything
          },
          // In delete_user_dialog.dart (inside onConfirm callback)
          onConfirm: () async {
            await DatabaseService()
                .deleteUser(patient.uid); // Call deleteUser method
            Navigator.of(context).pop(); // Close the dialog
            _refreshPatientList(); // Refresh the list
          },
        );
      },
    );
  }

  // Show Edit Role Dialog
  void _showEditRoleDialog(BuildContext context, UserData patient) {
    showDialog(
      context: context,
      builder: (context) {
        return EditRoleDialog(
          user: patient,
          currentRole: patient.userRole,
          onRoleUpdated: () {
            _refreshPatientList(); // Refresh list after role update
            Navigator.pop(
                context); // Close EditRoleDialog immediately after role update
          },
        );
      },
    );
  }

  // Refresh the Patient List
  void _refreshPatientList() {
    final DatabaseService databaseService = DatabaseService();

    setState(() {
      allPatients = []; // Clear allPatients list
      filteredPatients = []; // Clear filteredPatients list
    });

    databaseService.getUsersByRole(_selectedRole).listen((users) {
      if (mounted) {
        // Ensure the widget is still mounted
        setState(() {
          allPatients = users; // Update allPatients
          filteredPatients =
              List.from(allPatients); // Copy allPatients to filteredPatients
        });
      }
    }).onError((error) {
      print("Error fetching data: $error"); // Log errors if any
    });
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseService databaseService = DatabaseService();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: StreamBuilder<List<UserData>>(
        stream: databaseService.getUsersByRole(_selectedRole),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading users"));
          }
          if (snapshot.hasData) {
            if (allPatients.isEmpty) {
              allPatients = snapshot.data!;
              filteredPatients = List.from(allPatients);
            }
          }

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50.0,
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            onSubmitted: (value) {
                              _filterPatients(value);
                              FocusScope.of(context).unfocus();
                            },
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: const TextStyle(
                                  color: AppColors.blackTransparent),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.blackTransparent),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.blackTransparent),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.blackTransparent),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 10.0),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_searchController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _refreshPatientList();
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.search,
                                      color: _focusNode.hasFocus
                                          ? AppColors.neon
                                          : Colors.grey,
                                    ),
                                    onPressed: () {
                                      _filterPatients(_searchController.text);
                                      FocusScope.of(context).unfocus();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5.0),
                  Row(
                    children: [
                      SizedBox(
                        height: 40.0,
                        child: TextButton(
                          onPressed: _toggleSortOrder,
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _sortOrder,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(width: 5.0),
                              Icon(
                                _sortOrder == 'A-Z'
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Container(
                        height: 40.0,
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(
                          color: AppColors.neon,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedRole,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _filterByRole(newValue);
                            }
                          },
                          items: <String>['patient', 'doctor']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value.capitalize(),
                                style: const TextStyle(
                                  color: AppColors.white,
                                ),
                              ),
                            );
                          }).toList(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                          dropdownColor: AppColors.neon,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.white,
                          ),
                          isExpanded: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  Expanded(
                    child: filteredPatients.isEmpty
                        ? Center(
                            child: Text(
                              'No $_selectedRole available',
                              style: const TextStyle(
                                fontSize: 18,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                color: AppColors.blackTransparent,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredPatients.length,
                            itemBuilder: (context, index) {
                              final patient = filteredPatients[index];

                              return GestureDetector(
                                onTap: () =>
                                    _showUserDetailsDialog(context, patient),
                                child: _buildPatientItem(patient),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
