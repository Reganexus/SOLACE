// ignore_for_file: unrelated_type_equality_checks, avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solace/models/my_user.dart';
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
  final String _selectedRole = 'caregiver'; // Default role
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

    if (_selectedRole == 'caregiver') {
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
          'Caregiver List',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
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
                            return _buildCaregiverItem(user as UserData);
                          },
                        ),
                ),
              ],
            ),
          ),
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

// Show dialog for caregivers
  void _showCaregiverDetailsDialog(BuildContext context, UserData caregiver) {
    showDialog(
      context: context,
      builder: (context) {
        return UserDetailsDialog(
          user: caregiver,
          onCall: () =>
              _makeCall(caregiver.phoneNumber), // Callback for making calls
        );
      },
    );
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
