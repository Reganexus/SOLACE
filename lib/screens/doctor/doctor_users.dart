// ignore_for_file: unrelated_type_equality_checks, avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solace/models/my_patient.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/user_details.dart';
import 'package:solace/themes/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorUsers extends StatefulWidget {
  final String currentUserId;

  const DoctorUsers({super.key, required this.currentUserId});

  @override
  DoctorUsersState createState() => DoctorUsersState();
}

class DoctorUsersState extends State<DoctorUsers> {
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

  void _toggleSortOrder() {
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
      appBar: AppBar(
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        title: const Text(
          'User List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
            onTap: _toggleSortOrder, // Toggle sort order when tapped
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Image.asset(
                _isAscending
                    ? 'lib/assets/images/shared/navigation/ascending.png' // Path to ascending icon
                    : 'lib/assets/images/shared/navigation/descending.png', // Path to descending icon
                height: 24, // Adjust size as needed
                width: 24,
              ),
            ),
          ),
        ],
      ),
      body: Container(
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
                          color:
                              AppColors.gray, // Background color for TextField
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
                              });}
                            }
                          },
                          items: ['patient', 'caregiver']
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
              Expanded(
                child: filteredUsers.isEmpty
                    ? Center(
                        child: allUsers.isEmpty
                            ? const CircularProgressIndicator()
                            : Text('No $_selectedRole available'),
                      )
                    : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _selectedRole == 'patient' &&
                                  user is PatientData
                              ? _buildPatientItem(user)
                              : _buildCaregiverItem(user as UserData);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientItem(PatientData patient) {
    return GestureDetector(
      onTap: () => _showPatientDetailsDialog(context, patient),
      child: Container(
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
              backgroundImage: patient.profileImageUrl.isNotEmpty
                  ? NetworkImage(patient.profileImageUrl)
                  : const AssetImage('lib/assets/images/shared/placeholder.png')
                      as ImageProvider,
              radius: 24.0,
            ),
            const SizedBox(width: 10.0),
            // Full name
            Expanded(
              child: Text(
                '${patient.firstName} ${patient.lastName}',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaregiverItem(UserData caregiver) {
    return GestureDetector(
      onTap: () => _showCaregiverDetailsDialog(context, caregiver),
      child: Container(
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
            // Full name
            Expanded(
              child: Text(
                '${caregiver.firstName} ${caregiver.lastName}',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Show dialog for patients
  void _showPatientDetailsDialog(BuildContext context, PatientData patient) {
    showDialog(
      context: context,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          return AlertDialog(
            title: Text(
              '${patient.firstName} ${patient.lastName}',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            backgroundColor: AppColors.white,
            content: SizedBox(
              width: constraints.maxWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (patient.profileImageUrl.isNotEmpty)
                    _buildPatientDetails(patient),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  backgroundColor: AppColors.neon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

// Helper widget to display patient details
  Widget _buildPatientDetails(PatientData patient) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (patient.birthday != null)
            _buildProfileInfoSection(
                "Birthday", DateFormat('yyyy-MM-dd').format(patient.birthday!)),
          if (patient.age != null)
            _buildProfileInfoSection("Age", "${patient.age}"),
          if (patient.gender.isNotEmpty)
            _buildProfileInfoSection("Gender", patient.gender),
          if (patient.religion.isNotEmpty)
            _buildProfileInfoSection("Religion", patient.religion),
          if (patient.organDonation.isNotEmpty)
            _buildProfileInfoSection("Organ Donation", patient.organDonation),
          if (patient.fixedWishes.isNotEmpty)
            _buildProfileInfoSection("Fixed Wishes", patient.fixedWishes),
          if (patient.will.isNotEmpty)
            _buildProfileInfoSection("Will", patient.will),
        ]
            .map((e) =>
                Padding(padding: const EdgeInsets.only(bottom: 8.0), child: e))
            .toList(),
      ),
    );
  }

  Widget _buildProfileInfoSection(String header, String data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Colors.grey,
            ),
          ),
          Text(
            data,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.normal,
              fontFamily: 'Inter',
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

// Show dialog for caregivers
  void _showCaregiverDetailsDialog(BuildContext context, UserData caregiver) {
    showDialog(
      context: context,
      builder: (context) {
        return UserDetailsDialog(
          user: caregiver, // Pass the caregiver object
          isAdminView: false,
          onAddContact: () => _addContact(caregiver),
          onCall: () =>
              _makeCall(caregiver.phoneNumber), // Callback for making calls
        );
      },
    );
  }

// Add contact (friend request) logic remains the same
  void _addContact(UserData user) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Fetch current user data
        final currentUserData =
            await DatabaseService().getUserDataById(currentUser.uid);

        if (currentUserData != null) {
          await DatabaseService().sendFriendRequest(
            currentUser.uid, // Current user's role
            user.uid, // Target user's role
          );

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Friend request sent to ${user.firstName}!'),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error fetching current user data.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not logged in.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending friend request: $e')),
      );
    }
  }

// Make call logic remains the same
  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    var status = await Permission.phone.status;
    if (status.isDenied) {
      await Permission.phone.request();
      status = await Permission.phone.status;
    }

    if (status.isGranted) {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        print('Could not launch $launchUri');
      }
    } else {
      print('Permission denied to make calls.');
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
