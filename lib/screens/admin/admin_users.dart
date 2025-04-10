// ignore_for_file: unrelated_type_equality_checks, avoid_print, use_build_context_synchronously, prefer_final_fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/models/my_patient.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/admin/admin_edit.dart';
import 'package:solace/screens/admin/admin_edit_tags.dart';
import 'package:solace/screens/admin/admin_role.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/shared/widgets/audit_logs.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/inputdecoration.dart';
import 'package:solace/themes/textstyle.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  AdminUsersState createState() => AdminUsersState();
}

class AdminUsersState extends State<AdminUsers> {
  final DatabaseService db = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LogService _logService = LogService();
  bool _isAscending = true;
  String _selectedRole = 'caregiver';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<dynamic> filteredUsers = [];
  List<dynamic> allUsers = [];
  late User user;

  @override
  void initState() {
    super.initState();
    _refreshUserList();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await db.clearAllCache();
    });
    final user = _auth.currentUser;

    if (user == null) {
      print("Error: No authenticated user found.");
      return;
    }
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
        allUsers = [];
        filteredUsers = [];
      });
    }

    if (_selectedRole == 'patient') {
      _fetchPatients()
          .listen((patients) {
            if (mounted) {
              setState(() {
                allUsers = patients;
                filteredUsers = List.from(allUsers);
                _sortUsers(); // Sort the list after fetching
              });
            }
          })
          .onError((error) {
            showToast('Error fetching patients.', 
                backgroundColor: AppColors.red);
          });
    } else if (_selectedRole == 'caregiver') {
      _fetchCaregivers()
          .listen((caregivers) {
            if (mounted) {
              setState(() {
                allUsers = caregivers;
                filteredUsers = List.from(allUsers);
                _sortUsers(); // Sort the list after fetching
              });
            }
          })
          .onError((error) {
            showToast('Error fetching caregivers.', 
                backgroundColor: AppColors.red);
          });
    } else if (_selectedRole == 'doctor') {
      _fetchDoctors()
          .listen((doctors) {
            if (mounted) {
              setState(() {
                allUsers = doctors;
                filteredUsers = List.from(allUsers);
                _sortUsers(); // Sort the list after fetching
              });
            }
          })
          .onError((error) {
            showToast('Error fetching caregivers.',   
                backgroundColor: AppColors.red);
          });
    } else if (_selectedRole == 'admin') {
      _fetchAdmins()
          .listen((admins) {
            if (mounted) {
              setState(() {
                allUsers = admins;
                filteredUsers = List.from(allUsers);
                _sortUsers(); // Sort the list after fetching
              });
            }
          })
          .onError((error) {
            showToast('Error fetching caregivers.', 
                backgroundColor: AppColors.red);
          });
    } else if (_selectedRole == 'nurse') {
      _fetchNurses()
          .listen((nurses) {
            if (mounted) {
              setState(() {
                allUsers = nurses;
                filteredUsers = List.from(allUsers);
                _sortUsers(); // Sort the list after fetching
              });
            }
          })
          .onError((error) {
            showToast('Error fetching caregivers.', 
                backgroundColor: AppColors.red);
          });
    }
  }

  void _filterUsers(String query) {
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          filteredUsers = List.from(allUsers);
        } else {
          filteredUsers =
              allUsers.where((user) {
                final fullName =
                    '${user.firstName} ${user.lastName}'.toLowerCase();
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
        filteredUsers.sort(
          (a, b) =>
              _isAscending
                  ? a.firstName.compareTo(b.firstName) // Ascending order
                  : b.firstName.compareTo(a.firstName),
        ); // Descending order
      });
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

  Stream<List<PatientData>> _fetchPatients() {
    return FirebaseFirestore.instance
        .collection('patient')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => PatientData.fromDocument(doc))
                  .where((patient) => patient != null)
                  .toList(),
        );
  }

  Stream<List<UserData>> _fetchCaregivers() {
    return FirebaseFirestore.instance
        .collection('caregiver')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => UserData.fromDocument(doc))
                  .where((caregiver) => caregiver != null)
                  .toList(),
        );
  }

  Stream<List<UserData>> _fetchDoctors() {
    return FirebaseFirestore.instance
        .collection('doctor')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => UserData.fromDocument(doc))
                  .where((doctor) => doctor != null)
                  .toList(),
        );
  }

  Stream<List<UserData>> _fetchAdmins() {
    return FirebaseFirestore.instance
        .collection('admin')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => UserData.fromDocument(doc))
                  .where((admin) => admin != null)
                  .toList(),
        );
  }

  Stream<List<UserData>> _fetchNurses() {
    return FirebaseFirestore.instance
        .collection('nurse')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => UserData.fromDocument(doc))
                  .where((nurse) => nurse != null)
                  .toList(),
        );
  }

  void _showUserDetailsDialog(BuildContext context, dynamic user) {
    db.clearAllCache();
    debugPrint("Admin Users user: $user");

    if (user is! UserData && user is! PatientData) {
      throw ArgumentError('Unsupported user type');
    }

    final String userName = '${user.firstName} ${user.lastName}';

    void navigateToEditProfile() {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminEdit(currentUserId: user.uid),
        ),
      );
    }

    void navigateToEditUserRole() {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditUserRoleDialog(uid: user.uid),
        ),
      );
    }

    void navigateToLogs() {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AuditLogs(uid: user.uid)),
      );
    }

    void navigateToEditTag() {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditTags(currentUserId: user.uid),
        ),
      );
    }

    void confirmDelete(Function action) {
      Navigator.pop(context);
      action();
    }

    void showDeleteDialog(Function action) {
      final deleteAction =
          user is PatientData
              ? () => _showDeceasePatientDialog(context, user.uid, userName)
              : () => _showDeleteUserDialog(context, user.uid, userName);
      confirmDelete(deleteAction);
    }

    Widget buildActionButton(
      String label,
      ButtonStyle style,
      VoidCallback onPressed,
    ) {
      return SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: onPressed,
          style: style,
          child: Text(label, style: Textstyle.smallButton),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Manage $userName', style: Textstyle.subheader),
                  SizedBox(height: 10),
                  Text(
                    'Choose an action for this user.',
                    style: Textstyle.body,
                  ),
                  SizedBox(height: 10),
                  if (user is UserData)
                    buildActionButton(
                      'Change Role',
                      Buttonstyle.buttonNeon,
                      navigateToEditUserRole,
                    ),
                  buildActionButton(
                    'Edit Profile',
                    Buttonstyle.buttonPurple,
                    navigateToEditProfile,
                  ),
                  buildActionButton(
                    'Edit Tags',
                    Buttonstyle.buttonBlue,
                    navigateToEditTag,
                  ),
                  if (user is UserData)
                    buildActionButton(
                      'View Logs',
                      Buttonstyle.buttonDarkBlue,
                      navigateToLogs,
                    ),
                  buildActionButton(
                    'Delete User',
                    Buttonstyle.buttonRed,
                    () => showDeleteDialog(() {}),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: Buttonstyle.buttonNeon,
                        child: Text('Cancel', style: Textstyle.smallButton),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeceasePatientDialog(
    BuildContext context,
    String uid,
    String userName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text('Confirm Deceased?', style: Textstyle.subheader),
          content: Text(
            'Are you sure you want to mark patient $userName as deceased?',
            style: Textstyle.body,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(); // Close the dialog without doing anything
              },
              style: Buttonstyle.buttonNeon,
              child: Text('Cancel', style: Textstyle.smallButton),
            ),
            TextButton(
              onPressed: () async {
                debugPrint("Marking decease patient id: $uid");
                await DatabaseService().markDecease(uid);
                _refreshUserList();

                await _logService.addLog(
                  userId: user.uid,
                  action: "Marked $userName as deceased",
                );

                showToast('$userName has been deleted.');
                Navigator.of(context).pop();
              },
              style: Buttonstyle.buttonRed,
              child: Text('Delete', style: Textstyle.smallButton),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteUserDialog(
    BuildContext context,
    String uid,
    String userName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text('Confirm Deletion', style: Textstyle.subheader),
          content: Text(
            'Are you sure you want to delete $userName from the database?',
            style: Textstyle.body,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(); // Close the dialog without doing anything
              },
              style: Buttonstyle.buttonNeon,
              child: Text('Cancel', style: Textstyle.smallButton),
            ),
            TextButton(
              onPressed: () async {
                debugPrint("Delete User id: $uid");
                await DatabaseService().deleteUser(uid);
                _refreshUserList();

                await _logService.addLog(
                  userId: user.uid,
                  action: "Deleted $userName from the database.",
                );

                showToast('$userName has been deleted.');
                Navigator.of(context).pop();
              },
              style: Buttonstyle.buttonRed,
              child: Text('Delete', style: Textstyle.smallButton),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: double.infinity, // Match height of the Row
              decoration: BoxDecoration(
                color: AppColors.gray, // Background color for TextField
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(
                    10,
                  ), // Rounded corners for left side
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _filterUsers,
                decoration: InputDecorationStyles.build('Search', _focusNode),
              ),
            ),
          ),
          Container(
            width: 120,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.gray,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
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
                items:
                    ['admin', 'caregiver', 'doctor', 'nurse', 'patient']
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                StringExtension(role).capitalize(),
                                style: Textstyle.bodySmall,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                icon: const Icon(Icons.arrow_drop_down),
                isExpanded: true,
                dropdownColor: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLister() {
    if (filteredUsers.isEmpty) {
      return _buildNoData();
    }

    return ListView.builder(
      shrinkWrap: true, // Let it take only the space it needs
      physics:
          const NeverScrollableScrollPhysics(), // Prevent nested scroll conflict
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];

        if (_selectedRole == 'patient' && user is PatientData) {
          return _buildPatientItem(user);
        } else {
          return _buildItem(user as UserData);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserManagementInfo(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 10),
              _buildLister(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoData() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 50, color: AppColors.black),
            const SizedBox(height: 10),
            Text(
              'No ${_selectedRole}s available',
              style: Textstyle.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(UserData role) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          // Profile image
          CircleAvatar(
            backgroundImage:
                role.profileImageUrl.isNotEmpty
                    ? NetworkImage(role.profileImageUrl)
                    : const AssetImage(
                          'lib/assets/images/shared/placeholder.png',
                        )
                        as ImageProvider,
            radius: 18.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              '${role.firstName} ${role.lastName}',
              style: Textstyle.body,
              overflow: TextOverflow.ellipsis, // Add ellipsis
            ),
          ),
          // Menu button
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.black, size: 24),
            onPressed: () => _showUserDetailsDialog(context, role),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientItem(PatientData patient) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          // Profile image
          CircleAvatar(
            backgroundImage:
                patient.profileImageUrl.isNotEmpty
                    ? NetworkImage(patient.profileImageUrl)
                    : const AssetImage(
                          'lib/assets/images/shared/placeholder.png',
                        )
                        as ImageProvider,
            radius: 18.0,
          ),
          const SizedBox(width: 10.0),
          // Full name with ellipsis
          Expanded(
            child: Text(
              '${patient.firstName} ${patient.lastName}',
              style: Textstyle.body,
              overflow: TextOverflow.ellipsis, // Add ellipsis
            ),
          ),
          // Menu button
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.black, size: 24),
            onPressed: () => _showUserDetailsDialog(context, patient),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementInfo() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/images/auth/manage.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(color: AppColors.black.withValues(alpha: 0.4)),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Manager Users',
                style: Textstyle.heading.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Edit, Delete or View Logs of users',
                style: Textstyle.body.copyWith(color: AppColors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
