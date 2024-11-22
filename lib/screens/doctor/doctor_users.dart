// ignore_for_file: use_build_context_synchronously, prefer_final_fields

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/shared/widgets/user_details.dart';  // Make sure to import the UserDetails widget

class DoctorUsers extends StatefulWidget {
  const DoctorUsers({super.key});

  @override
  DoctorUsersState createState() => DoctorUsersState();
}

class DoctorUsersState extends State<DoctorUsers> {
  String _sortOrder = 'A-Z';
  String _selectedRole = 'patient'; // Default to 'patient'
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<UserData> filteredUsers = [];
  List<UserData> allUsers = []; // Store all users for searching

  @override
  void initState() {
    super.initState();
    _refreshUserList();  // Call this method to load users initially
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Filter users by name
  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(allUsers); // Reset to all users
      } else {
        filteredUsers = allUsers.where((user) {
          String fullName = '${user.firstName} ${user.lastName}';
          return fullName.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // Sort users based on the selected order
  void _sortUsers() {
    setState(() {
      if (_sortOrder == 'A-Z') {
        filteredUsers.sort((a, b) => a.firstName.compareTo(b.firstName));
      } else {
        filteredUsers.sort((a, b) => b.firstName.compareTo(a.firstName));
      }
    });
  }

  // Toggle sort order
  void _toggleSortOrder() {
    setState(() {
      _sortOrder = _sortOrder == 'A-Z' ? 'Z-A' : 'A-Z';
      _sortUsers();
    });
  }

  // Refresh user list based on role filter
  void _refreshUserList() {
    final DatabaseService databaseService = DatabaseService();
    databaseService.getUsersByRole(_selectedRole).listen((users) {
      setState(() {
        allUsers = users; // Update the list of all users
        filteredUsers = List.from(allUsers); // Initialize filtered list
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50.0,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onSubmitted: (value) {
                          _filterUsers(value);
                          FocusScope.of(context).unfocus();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: const TextStyle(
                            color: AppColors.blackTransparent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.blackTransparent),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.search,
                              color: _focusNode.hasFocus
                                  ? AppColors.neon
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              _filterUsers(_searchController.text);
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5.0),

              // Sort Order Button
              SizedBox(
                height: 40.0,
                child: TextButton(
                  onPressed: _toggleSortOrder,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
              const SizedBox(height: 10.0),

              // User List
              Expanded(
                child: filteredUsers.isEmpty
                    ? Center(
                  child: Text(
                    'No users available',
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackTransparent,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return GestureDetector(
                      onTap: () {
                        // Show user details dialog
                        _showUserDetailsDialog(context, user);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 15.0),
                        margin: const EdgeInsets.symmetric(vertical: 5.0),
                        decoration: BoxDecoration(
                          color: AppColors.gray,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: (user.profileImageUrl.isNotEmpty)
                                  ? NetworkImage(user.profileImageUrl)
                                  : const AssetImage('lib/assets/images/shared/placeholder.png') as ImageProvider,
                              radius: 24.0,
                            ),
                            const SizedBox(width: 10.0),
                            Text(
                              '${user.firstName} ${user.lastName}',
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show user details in a dialog
  void _showUserDetailsDialog(BuildContext context, UserData user) {
    showDialog(
      context: context,
      builder: (context) {
        return UserDetailsDialog(
          user: user,
          isAdminView: false,
          onAddContact: () => _addContact(user),
        );
      },
    );
  }

  // Add contact (Friend request) function
  void _addContact(UserData user) async {
    // Handle adding the user (e.g., sending a friend request)
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await DatabaseService().sendFriendRequest(currentUser.uid, user.uid);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Friend request sent to ${user.firstName}!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending friend request.')));
    }
  }
}
