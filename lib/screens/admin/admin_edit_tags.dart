// edit_tags.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textstyle.dart';

class EditTags extends StatefulWidget {
  final String currentUserId;

  const EditTags({super.key, required this.currentUserId});

  @override
  EditTagsState createState() => EditTagsState();
}

class EditTagsState extends State<EditTags> {
  final AuthService _auth = AuthService();
  final LogService _logService = LogService();
  final DatabaseService _db = DatabaseService();
  List<String> taggedUserIds = [];
  List<String> availableUserIds = [];
  String? _selectedRole = '';
  bool _isTagging = false;
  bool isFetching = false;
  late String userName = '';
  late String adminId = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPatientName();
    _getAdminId();
    debugPrint("Patient Name: $userName");
    debugPrint("Admin ID: $adminId");
  }

  Future<void> _loadPatientName() async {
    final name = await _db.fetchUserName(widget.currentUserId);
    if (mounted) {
      setState(() {
        userName = name ?? 'Unknown';
      });
    }
    debugPrint("Patient Name: $userName");
  }

  Future<void> _getAdminId() async {
    final admin = _auth.currentUserId;
    if (mounted) {
      setState(() {
        adminId = admin ?? 'Unknown';
      });
    }
    debugPrint("Admin ID: $adminId");
  }

  Future<void> _loadUserData() async {
    setState(() {
      isFetching = true;
    });

    try {
      String? userRole = await _db.fetchAndCacheUserRole(widget.currentUserId);

      if (userRole == null) {
        debugPrint("User role is null");
        return;
      }

      var taggedUsers = await _fetchTaggedUsers(userRole);
      var availableUsers = await _fetchAvailableUsers(userRole);

      setState(() {
        taggedUserIds = taggedUsers;
        availableUserIds = availableUsers;
      });
    } catch (e) {
      debugPrint("Error loading user data: $e");
    } finally {
      setState(() {
        isFetching = false;
      });
    }
  }

  Future<List<String>> _fetchTaggedUsers(String userRole) async {
    final userDocRef = FirebaseFirestore.instance
        .collection(userRole)
        .doc(widget.currentUserId);
    final tagCollection = await userDocRef.collection('tags').get();

    return tagCollection.docs.map((doc) => doc.id).toList();
  }

  Future<void> _addTag(String taggedUserId) async {
    try {
      if (adminId.isEmpty) {
        showToast('User is not authenticated');
        return;
      }

      String? userRole = await _db.fetchAndCacheUserRole(widget.currentUserId);
      if (userRole == null) {
        showToast('User has no role.');
        return;
      }

      setState(() {
        _isTagging = true;
      });

      showToast('Tagging in progress...');

      String? taggedUserRole = await _db.fetchAndCacheUserRole(taggedUserId);
      if (taggedUserRole == null) {
        showToast('Selected user has no role.');
        return;
      }

      // Reference to both users' tag subcollections
      final currentUserRef = FirebaseFirestore.instance
          .collection(userRole)
          .doc(widget.currentUserId);
      final taggedUserRef = FirebaseFirestore.instance
          .collection(taggedUserRole)
          .doc(taggedUserId);

      // Add user to each other's tags subcollection
      await currentUserRef.collection('tags').doc(taggedUserId).set({});
      await taggedUserRef.collection('tags').doc(widget.currentUserId).set({});

      setState(() {
        taggedUserIds.add(taggedUserId);
        availableUserIds.remove(taggedUserId);
      });

      final name = await _db.fetchUserName(taggedUserId);

      await _logService.addLog(
        userId: adminId,
        action: "Tagged $name to patient $userName",
      );

      showToast('Successfully tagged user.');
    } catch (e) {
      showToast('Error tagging user: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTagging = false;
        });
      }
    }
  }

  Future<void> _removeTag(String taggedUserId) async {
    try {
      if (adminId.isEmpty) {
        showToast('User is not authenticated');
        return;
      }

      String? userRole = await _db.fetchAndCacheUserRole(widget.currentUserId);
      if (userRole == null) {
        showToast('User has no role.');
        return;
      }

      String? taggedUserRole = await _db.fetchAndCacheUserRole(taggedUserId);
      if (taggedUserRole == null) {
        showToast('Selected user has no role.');
        return;
      }

      setState(() {
        _isTagging = true;
      });

      showToast('Untagging in progress...');

      final currentUserRef = FirebaseFirestore.instance
          .collection(userRole)
          .doc(widget.currentUserId);
      final taggedUserRef = FirebaseFirestore.instance
          .collection(taggedUserRole)
          .doc(taggedUserId);

      // Remove user from each other's tags subcollection
      await currentUserRef.collection('tags').doc(taggedUserId).delete();
      await taggedUserRef.collection('tags').doc(widget.currentUserId).delete();

      setState(() {
        taggedUserIds.remove(taggedUserId);
        availableUserIds.add(taggedUserId);
      });

      final name = await _db.fetchUserName(taggedUserId);

      await _logService.addLog(
        userId: adminId,
        action: "Untagged user $name from $userName",
      );

      showToast('Successfully untagged user.');
    } catch (e) {
      showToast('Error untagging user: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTagging = false;
        });
      }
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  Widget _buildTaggedUserList() {
    if (isFetching) {
      return Center(child: Loader.loaderNeon);
    }

    if (taggedUserIds.isEmpty) {
      return _buildNoTaggedUsersState();
    }

    return Column(
      children:
          taggedUserIds.map((userId) {
            return FutureBuilder<String?>(
              future: _db.fetchUserName(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Error fetching name',
                      style: Textstyle.bodyWhite,
                    ),
                  );
                }

                String userName = snapshot.data ?? 'Unknown User';

                return Container(
                  padding: EdgeInsets.only(left: 10),
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.gray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style: Textstyle.body,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: _isTagging ? AppColors.gray : AppColors.red,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: TextButton(
                          onPressed:
                              () =>
                                  _isTagging
                                      ? null
                                      : _showDeleteConfirmationDialog(userId),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Untag',
                                style: Textstyle.bodySmall.copyWith(
                                  color:
                                      _isTagging
                                          ? AppColors.blackTransparent
                                          : AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 5),
                              Icon(
                                Icons.delete,
                                color:
                                    _isTagging
                                        ? AppColors.blackTransparent
                                        : AppColors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
    );
  }

  Widget _buildAvailableUserList() {
    if (isFetching) {
      return Center(child: Loader.loaderNeon);
    }

    if (availableUserIds.isEmpty) {
      return _buildNoAvailableUsersState();
    }

    return FutureBuilder<String?>(
      future: _db.fetchAndCacheUserRole(widget.currentUserId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error fetching user role', style: Textstyle.body);
        }

        String? userRole = snapshot.data;
        if (userRole == null) {
          return Text('No role assigned to user', style: Textstyle.body);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userRole == 'patient'
                  ? 'Available Healthcare Provider'
                  : 'Available Patients',
              style: Textstyle.subheader,
            ),
            SizedBox(height: 10),
            FutureBuilder<List<String>>(
              future: _fetchAvailableUsers(userRole),
              builder: (context, availableUsersSnapshot) {
                if (availableUsersSnapshot.hasError) {
                  return Text(
                    'Error fetching available users',
                    style: Textstyle.body,
                  );
                }

                List<String> availableUserIds =
                    availableUsersSnapshot.data ?? [];
                if (availableUserIds.isEmpty) {
                  return Text(
                    'No available users to tag',
                    style: Textstyle.body,
                  );
                }

                // If user is a patient, categorize available users into roles
                if (userRole == 'patient') {
                  return FutureBuilder<Map<String, List<String>>>(
                    future: _categorizeAvailableUsers(availableUserIds),
                    builder: (context, categorizedSnapshot) {
                      if (categorizedSnapshot.hasError) {
                        return Text(
                          'Error categorizing users',
                          style: Textstyle.body,
                        );
                      }

                      Map<String, List<String>> categorizedUsers =
                          categorizedSnapshot.data ?? {};
                      List<MapEntry<String, List<String>>> nonEmptyCategories =
                          categorizedUsers.entries
                              .where((entry) => entry.value.isNotEmpty)
                              .toList();

                      if (nonEmptyCategories.isEmpty) {
                        return Text(
                          'No available users to tag',
                          style: Textstyle.body,
                        );
                      }

                      if (nonEmptyCategories.isNotEmpty &&
                          _selectedRole == null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _selectedRole = nonEmptyCategories.first.key;
                            });
                          }
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select one of the following roles to view healthcare providers to tag',
                            style: Textstyle.body,
                          ),
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children:
                                nonEmptyCategories.map((entry) {
                                  return ChoiceChip(
                                    checkmarkColor: AppColors.white,
                                    label: Text(
                                      entry.key.capitalize(),
                                      style: Textstyle.bodySmall.copyWith(
                                        color:
                                            _selectedRole == entry.key
                                                ? AppColors.white
                                                : AppColors.whiteTransparent,
                                        fontWeight:
                                            _selectedRole == entry.key
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    selected: _selectedRole == entry.key,
                                    onSelected: (bool selected) {
                                      setState(() {
                                        _selectedRole =
                                            selected ? entry.key : null;
                                      });
                                    },
                                    selectedColor: AppColors.neon,
                                    backgroundColor: AppColors.black.withValues(
                                      alpha: 0.6,
                                    ),
                                    side: BorderSide(color: Colors.transparent),
                                  );
                                }).toList(),
                          ),
                          SizedBox(height: 20),
                          if (_selectedRole != null &&
                              categorizedUsers.containsKey(_selectedRole))
                            Column(
                              children:
                                  (categorizedUsers[_selectedRole] ?? []).map((
                                    userId,
                                  ) {
                                    return FutureBuilder<String?>(
                                      future: _db.fetchUserName(userId),
                                      builder: (context, nameSnapshot) {
                                        if (nameSnapshot.hasError) {
                                          return Container(
                                            padding: EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppColors.red,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'Error fetching name',
                                              style: Textstyle.bodyWhite,
                                            ),
                                          );
                                        }

                                        String userName =
                                            nameSnapshot.data ?? 'Unknown User';

                                        return Container(
                                          padding: EdgeInsets.only(left: 10),
                                          margin: EdgeInsets.only(bottom: 10),
                                          decoration: BoxDecoration(
                                            color: AppColors.gray,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  userName,
                                                  style: Textstyle.body,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                width: 90,
                                                decoration: BoxDecoration(
                                                  color:
                                                      _isTagging
                                                          ? AppColors.gray
                                                          : AppColors.neon,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                        topRight:
                                                            Radius.circular(10),
                                                        bottomRight:
                                                            Radius.circular(10),
                                                      ),
                                                ),
                                                child: TextButton(
                                                  onPressed:
                                                      () =>
                                                          _isTagging
                                                              ? null
                                                              : _showAddConfirmationDialog(
                                                                userId,
                                                              ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Tag',
                                                        style: Textstyle
                                                            .bodySmall
                                                            .copyWith(
                                                              color:
                                                                  _isTagging
                                                                      ? AppColors
                                                                          .blackTransparent
                                                                      : AppColors
                                                                          .white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                      SizedBox(width: 5),
                                                      Icon(
                                                        Icons.add,
                                                        color:
                                                            _isTagging
                                                                ? AppColors
                                                                    .blackTransparent
                                                                : AppColors
                                                                    .white,
                                                        size: 18,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                            ),
                        ],
                      );
                    },
                  );
                } else {
                  // If user is caregiver, nurse, or doctor, just show available patients
                  return Column(
                    children:
                        availableUserIds.map((userId) {
                          return FutureBuilder<String?>(
                            future: _db.fetchUserName(userId),
                            builder: (context, nameSnapshot) {
                              if (nameSnapshot.hasError) {
                                return Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Error fetching name',
                                    style: Textstyle.bodyWhite,
                                  ),
                                );
                              }

                              String userName =
                                  nameSnapshot.data ?? 'Unknown User';

                              return Container(
                                padding: EdgeInsets.only(left: 10),
                                margin: EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.gray,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        userName,
                                        style: Textstyle.body,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      width: 90,
                                      decoration: BoxDecoration(
                                        color:
                                            _isTagging
                                                ? AppColors.gray
                                                : AppColors.neon,
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(10),
                                          bottomRight: Radius.circular(10),
                                        ),
                                      ),
                                      child: TextButton(
                                        onPressed:
                                            () =>
                                                _isTagging
                                                    ? null
                                                    : _showAddConfirmationDialog(
                                                      userId,
                                                    ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Tag',
                                              style: Textstyle.bodySmall
                                                  .copyWith(
                                                    color:
                                                        _isTagging
                                                            ? AppColors
                                                                .blackTransparent
                                                            : AppColors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            SizedBox(width: 5),
                                            Icon(
                                              Icons.add,
                                              color:
                                                  _isTagging
                                                      ? AppColors
                                                          .blackTransparent
                                                      : AppColors.white,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }).toList(),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, List<String>>> _categorizeAvailableUsers(
    List<String> userIds,
  ) async {
    Map<String, List<String>> categorizedUsers = {
      'caregiver': [],
      'nurse': [],
      'doctor': [],
    };

    for (String userId in userIds) {
      String? role = await _db.fetchAndCacheUserRole(userId);
      if (role != null && categorizedUsers.containsKey(role)) {
        categorizedUsers[role]!.add(userId);
      }
    }

    return categorizedUsers;
  }

  Future<List<String>> _fetchAvailableUsers(String userRole) async {
    if (userRole == 'patient') {
      // Fetch caregivers, nurses, and doctors (excluding already tagged ones)
      return _fetchUsersFromRoles(['caregiver', 'nurse', 'doctor']);
    } else {
      // Fetch patients (excluding already tagged ones)
      return _fetchUsersFromRoles(['patient']);
    }
  }

  Future<List<String>> _fetchUsersFromRoles(List<String> roles) async {
    List<String> userIds = [];
    for (String role in roles) {
      var usersQuery =
          await FirebaseFirestore.instance
              .collection(role)
              .get(); // Fetch all users of the given role

      // Filter out the users who are already taggedW
      var users =
          usersQuery.docs
              .where(
                (doc) => !taggedUserIds.contains(doc.id),
              ) // Exclude already tagged users
              .map((doc) => doc.id)
              .toList();

      userIds.addAll(users);
    }
    return userIds;
  }

  void _showDeleteConfirmationDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove Tag', style: Textstyle.subheader),
          content: Text(
            'Are you sure you want to remove this tag?',
            style: Textstyle.body,
          ),
          backgroundColor: AppColors.white,
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _removeTag(userId);
                      Navigator.pop(context);
                    },
                    style: Buttonstyle.buttonRed,
                    child: Text('Yes', style: Textstyle.smallButton),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: Buttonstyle.buttonNeon,
                    child: Text('No', style: Textstyle.smallButton),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showAddConfirmationDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Tag', style: Textstyle.subheader),
          content: Text(
            'Are you sure you want to tag this user?',
            style: Textstyle.body,
          ),
          backgroundColor: AppColors.white,
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _addTag(userId);
                      Navigator.pop(context);
                    },
                    style: Buttonstyle.buttonRed,
                    child: Text('Yes', style: Textstyle.smallButton),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: Buttonstyle.buttonNeon,
                    child: Text('No', style: Textstyle.smallButton),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoTaggedUsersState() {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off_rounded,
              color: AppColors.black,
              size: 70,
            ),
            const SizedBox(height: 10.0),
            Text(
              "No Tagged users yet",
              style: Textstyle.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAvailableUsersState() {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off_rounded,
              color: AppColors.black,
              size: 70,
            ),
            const SizedBox(height: 10.0),
            Text(
              "No available users to tag",
              style: Textstyle.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Tags', style: Textstyle.subheader),
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: _isTagging ? false : true,
        backgroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tagged Users', style: Textstyle.subheader),
              SizedBox(height: 10),
              _buildTaggedUserList(),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              _buildAvailableUserList(),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
  }
}
