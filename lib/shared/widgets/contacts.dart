// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:solace/shared/widgets/qr_scan.dart';

class Contacts extends StatefulWidget {
  final String currentUserId;

  const Contacts({super.key, required this.currentUserId});

  @override
  ContactsScreenState createState() => ContactsScreenState();
}

class ContactsScreenState extends State<Contacts> {
  late final String currentUserId;
  String? currentUserRole;
  bool isLoading = true;

  final DatabaseService db = DatabaseService();

  @override
  void initState() {
    super.initState();
    currentUserId = widget.currentUserId;
    _initializeUserRole();
  }

  Stream<DocumentSnapshot?> _getCurrentUserStream(String userId) async* {
    const roles = ['admin', 'doctor', 'caregiver', 'patient', 'unregistered'];

    for (final role in roles) {
      final docStream =
          FirebaseFirestore.instance.collection(role).doc(userId).snapshots();
      final doc = await docStream.first;
      if (doc.exists) {
        yield* docStream;
        return;
      }
    }
    yield null;
  }

  Future<void> _initializeUserRole() async {
    try {
      const roles = ['admin', 'doctor', 'caregiver', 'patient', 'unregistered'];
      for (final role in roles) {
        final doc = await FirebaseFirestore.instance
            .collection(role)
            .doc(currentUserId)
            .get();
        if (doc.exists) {
          setState(() {
            currentUserRole =
                (doc.data() as Map<String, dynamic>)['userRole'] ?? 'unknown';
            isLoading = false;
          });
          return;
        }
      }
      throw Exception('User document not found');
    } catch (e) {
      debugPrint('Error initializing user role: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize user role: $e')),
      );
    }
  }

  void _handleQRScanResult(BuildContext context, String result) async {
    try {
      if (currentUserRole == null) throw Exception('User role not initialized');

      final targetUserRole = await db.getTargetUserRole(result);
      if (targetUserRole == null) throw Exception('User not found');

      if (await db.isUserFriend(currentUserId, result)) {
        _showSnackBar('You are already friends with this user!');
        return;
      }

      if (await db.hasPendingRequest(currentUserId, result)) {
        _showSnackBar('Friend request already sent!');
        return;
      }

      await db.sendFriendRequest(currentUserId, result);
      _showSnackBar('Friend request successfully sent!');
    } catch (e) {
      debugPrint('Error handling QR scan result: $e');
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await Permission.phone.request().isGranted) {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        debugPrint('Could not launch $launchUri');
      }
    } else {
      debugPrint('Phone permission denied');
    }
  }

  Future<void> _showSearchModal(BuildContext context) async {
    final uidController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          return AlertDialog(
            backgroundColor: AppColors.white,
            contentPadding: const EdgeInsets.all(20),
            title: const Text(
              'Add Friend',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: constraints.maxWidth, // Full width of the screen
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: uidController,
                    decoration: InputDecoration(
                      labelText: 'Enter User UID',
                      labelStyle: const TextStyle(
                        color: AppColors.black, // Default label color
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: AppColors.neon, // Label color when focused
                      ),
                      filled: true,
                      fillColor: AppColors.gray, // Subtle fill
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.black, // Default border color
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.neon, // Border color when focused
                          width: 2.0,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.red, // Border color for errors
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.red, // Border for focused error
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.neon,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: TextButton(
                            onPressed: () async {
                              final targetUserId = uidController.text.trim();
                              try {
                                print("Starting friend request process...");

                                // Check if the user is trying to add themselves
                                if (currentUserId == targetUserId) {
                                  print("User is trying to add themselves.");
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                  _showSnackBar(
                                      "You cannot add yourself as a friend!");
                                  return;
                                }

                                // Get the target user's role
                                print("Fetching target user role...");
                                final targetUserRole =
                                    await db.getTargetUserRole(targetUserId);
                                print("Target user role: $targetUserRole");

                                if (targetUserRole == null) {
                                  print("Target user role is null.");
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                  _showSnackBar('User not found!');
                                  return;
                                }

                                // Check if users are already friends
                                print(
                                    "Checking if user is already a friend...");
                                if (await db.isUserFriend(
                                    currentUserId, targetUserId)) {
                                  print("Users are already friends.");
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                  _showSnackBar(
                                      'You are already friends with this user!');
                                  return;
                                }

                                // Check for pending friend requests
                                print("Checking for pending requests...");
                                if (await db.hasPendingRequest(
                                    currentUserId, targetUserId)) {
                                  print("Pending request exists.");
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                  _showSnackBar('Friend request already sent!');
                                  return;
                                }

                                // Send the friend request
                                print("Sending friend request...");
                                await db.sendFriendRequest(
                                    currentUserId, targetUserId);
                                print("Friend request sent successfully.");
                                Navigator.of(context).pop(); // Close the dialog
                                _showSnackBar('Friend request sent!');
                              } catch (e) {
                                debugPrint('Error adding friend: $e');
                                Navigator.of(context).pop(); // Close the dialog
                                _showSnackBar('Error: $e');
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_add,
                                  color: AppColors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Add Friend',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        title: const Text(
          'Contacts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
            onTap: () => _showSearchModal(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Icon(
                Icons.person_add,
                size: 30,
                color: AppColors.black,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QRScannerPage()),
              );
              if (result != null) _handleQRScanResult(context, result);
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: Icon(
                Icons.qr_code_scanner,
                size: 30,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot?>(
        stream: _getCurrentUserStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('User data not found'));
          }

          final userDoc = snapshot.data!.data() as Map<String, dynamic>?;
          if (userDoc == null) {
            return const Center(child: Text('User data is empty'));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
              child: Column(
                children: [
                  _buildHeader('Contacts'),
                  const SizedBox(height: 10),
                  _buildFriendsList(),
                  const SizedBox(height: 20),
                  _buildHeader('Contact Requests'),
                  const SizedBox(height: 10),
                  _buildRequestsList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Header for Friends & Requests list
  Widget _buildHeader(String title) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        title,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 24,
          fontFamily: 'Outfit',
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
      ),
    );
  }

  Widget _buildContactsList(String type, String emptyMessage,
      Function(String, UserRole) cardBuilder) {
    return StreamBuilder<DocumentSnapshot?>(
      stream: _getCurrentUserStream(currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.neon),
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final contacts = data?['contacts'] as Map<String, dynamic>?;
        final contactsData = contacts?[type] as Map<String, dynamic>?;

        if (contactsData == null || contactsData.isEmpty) {
          return _buildEmptyState(emptyMessage);
        }

        final items = contactsData.entries.toList();
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final contactId = items[index].key;
            final contactRole = items[index].value;
            return cardBuilder(
              contactId,
              UserRole.values.firstWhere(
                (role) => role.toString().split('.').last == contactRole,
                orElse: () => UserRole.caregiver,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCard({
    required String name,
    required String profileImageUrl,
    required Widget trailingWidget,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: profileImageUrl.isNotEmpty
                ? NetworkImage(profileImageUrl)
                : const AssetImage('lib/assets/images/shared/placeholder.png')
                    as ImageProvider,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.normal,
                color: AppColors.black,
              ),
            ),
          ),
          trailingWidget,
        ],
      ),
    );
  }

  // Friends list
  Widget _buildFriendsList() {
    return _buildContactsList('friends', 'No friends yet', _buildFriendCard);
  }

  Widget _buildRequestsList() {
    return _buildContactsList('requests', 'No requests', _buildRequestCard);
  }

  // Friend Card
  Widget _buildFriendCard(String friendId, UserRole friendRole) {
    return FutureBuilder<String>(
      future: db.getUserName(friendId, friendRole),
      builder: (context, nameSnapshot) {
        if (!nameSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        String friendName = nameSnapshot.data ?? 'Unknown';

        return FutureBuilder<String>(
          future: db.getProfileImageUrl(friendId, friendRole),
          builder: (context, imageSnapshot) {
            String profileImageUrl = imageSnapshot.data ?? '';

            return _buildCard(
              name: friendName,
              profileImageUrl: profileImageUrl,
              trailingWidget: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () =>
                    _showFriendOptions(context, friendId, friendRole),
              ),
            );
          },
        );
      },
    );
  }

  // Request Card
  Widget _buildRequestCard(String requestId, UserRole requestRole) {
    return FutureBuilder<String>(
      future: db.getUserName(requestId, requestRole),
      builder: (context, nameSnapshot) {
        if (!nameSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        String requesterName = nameSnapshot.data ?? 'Unknown';

        return FutureBuilder<String>(
          future: db.getProfileImageUrl(requestId, requestRole),
          builder: (context, imageSnapshot) {
            String profileImageUrl = imageSnapshot.data ?? '';

            return _buildCard(
              name: requesterName,
              profileImageUrl: profileImageUrl,
              trailingWidget: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () =>
                        db.acceptFriendRequest(currentUserId, requestId),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () =>
                        db.declineFriendRequest(currentUserId, requestId),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Empty State Widget
  Widget _buildEmptyState(String message) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.gray,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.normal,
              color: AppColors.black,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showFriendOptions(
      BuildContext context, String friendId, UserRole friendRole) async {
    try {
      // Fetch the friend's name and phone number based on role
      String friendName = await db.getUserName(friendId, friendRole);

      DocumentSnapshot friendDoc = await FirebaseFirestore.instance
          .collection(
              friendRole.toString().split('.').last) // Dynamic role-based collection
          .doc(friendId)
          .get();

      String phoneNumber = friendDoc['phoneNumber'] ??
          'Not available'; // Assuming phoneNumber field exists

      // Extract the timestamp for when you became friends
      var friendData = friendDoc['contacts']['friends'][currentUserId];

      String formattedTimestamp = 'Unknown';
      if (friendData is Timestamp) {
        formattedTimestamp =
            DateFormat('yyyy-MM-dd').format(friendData.toDate());
      } else if (friendData is Map) {
        var timestamp = friendData[
            'timestamp']; // Assuming the timestamp is stored as 'timestamp'
        if (timestamp is Timestamp) {
          formattedTimestamp =
              DateFormat('yyyy-MM-dd').format(timestamp.toDate());
        }
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.white,
            title: Text(
              friendName,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone, color: AppColors.black),
                          SizedBox(width: 10),
                          Text(
                            phoneNumber,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.people, color: AppColors.black),
                          SizedBox(width: 10),
                          Text(
                            formattedTimestamp,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.neon,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: TextButton(
                            onPressed: () => _makeCall(phoneNumber),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.neon,
                              foregroundColor: AppColors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.call, color: AppColors.white),
                                SizedBox(width: 10),
                                Text(
                                  'Call',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text(
                                      'Confirm Removal',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    content: const Text(
                                      'Are you sure you want to remove this friend?',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // Close the confirmation dialog
                                        },
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          db.removeFriend(
                                            currentUserId,
                                            friendId,
                                          );
                                          Navigator.of(context)
                                              .pop(); // Close the confirmation dialog
                                          Navigator.of(context)
                                              .pop(); // Close the original dialog
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: AppColors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_remove,
                                    color: AppColors.white),
                                SizedBox(width: 10),
                                Text(
                                  'Remove',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing friend options: $e');
    }
  }
}
