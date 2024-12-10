// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solace/services/database.dart';
import 'package:solace/themes/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:solace/shared/widgets/qr_scan.dart';

class Contacts extends StatelessWidget {
  final String currentUserId;
  final DatabaseService db = DatabaseService();

  Contacts({super.key, required this.currentUserId});

  void _handleQRScanResult(BuildContext context, String result) async {
    print('Scanned user ID: $result');

    // Check if the user exists
    bool exists = await db.checkUserExists(result);
    if (!exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found')),
      );
      return;
    }

    // Check if already friends
    bool isFriend = await db.isUserFriend(currentUserId, result);
    if (isFriend) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are already friends with this user!')),
      );
      return;
    }

    // Check if a request is already pending
    bool hasPendingRequest = await db.hasPendingRequest(currentUserId, result);
    if (hasPendingRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request already sent!')),
      );
      return;
    }

    // Send the friend request if all checks pass
    await db.sendFriendRequest(currentUserId, result);

    // Show a snackbar indicating the friend request was successfully sent
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Friend request successfully sent!')),
    );
  }

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
      } else {}
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Padding(
          padding: const EdgeInsets.only(
              left: 14.0, right: 20.0), // Add padding here
          child: AppBar(
            title: Text('Contacts'),
            backgroundColor: AppColors.white,
            scrolledUnderElevation: 0.0,
            actions: [
              IconButton(
                color: AppColors.black,
                icon: Icon(Icons.person_add),
                iconSize: 30.0,
                onPressed: () => _showSearchModal(context),
              ),
              IconButton(
                color: AppColors.black,
                icon: Icon(Icons.qr_code_scanner),
                iconSize: 30.0,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const QRScannerPage()),
                  );

                  if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('QR Code detected'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _handleQRScanResult(context, result);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var contacts = snapshot.data!['contacts'];
          if (contacts == null || contacts.isEmpty) {
            // Only show 'No caregivers added' message for patients or caregivers
            var userRole = snapshot.data!['userRole'];
            if (userRole == 'patient' || userRole == 'caregiver') {
              return _noRequestsMessage('No caregivers added');
            }
          }

          var healthcare = contacts['healthcare'];
          if (healthcare == null || healthcare.isEmpty) {
            // Only show 'No caregivers added' message for patients or caregivers
            var userRole = snapshot.data!['userRole'];
            if (userRole == 'patient' || userRole == 'caregiver') {
              return _noRequestsMessage('No caregivers added');
            }
          }

          var userRole = snapshot.data!['userRole'];

          // Check if a caregiver is already assigned
          var caregivers = healthcare.entries
              .where(
                  (entry) => entry.key != 'requests') // Exclude 'requests' key
              .map((entry) => entry.key)
              .toList();

          bool hasCaregiver = caregivers.isNotEmpty;

          return SingleChildScrollView(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
              child: Column(
                children: [
                  // Display caregiver section only if the user is a patient or caregiver and no caregiver is assigned
                  if (userRole == 'patient' || userRole == 'caregiver') ...[
                    // Show the caregiver or patient section if `hasCaregiver` is false
                    if (hasCaregiver) ...[
                      _buildHeader(
                        userRole == 'patient' ? 'Caregiver' : 'Patient',
                      ),
                      _buildCaregiversList(),
                      SizedBox(height: 20),
                    ],

                    // Show caregiver requests only if `hasCaregiver` is false
                    if (!hasCaregiver) ...[
                      _buildHeader('Caregiver Requests'),
                      _buildHealthcareRequestsList(),
                      SizedBox(height: 20),
                    ],
                  ],

                  // Always show the contacts and contact requests section
                  _buildHeader('Contacts'),
                  _buildFriendsList(),
                  SizedBox(height: 20),
                  _buildHeader('Contact Requests'),
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

  // Friends list
  Widget _buildFriendsList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.neon),
          );
        }

        var friendsData = snapshot.data!['contacts']['friends'];

        // Check if friendsData is null or empty
        if (friendsData == null ||
            (friendsData is Map && friendsData.isEmpty)) {
          return Column(
            children: [
              SizedBox(
                height: 20,
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.gray,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  'No friends yet',
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

        if (friendsData is Map) {
          var friends = friendsData.keys.toList();

          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              String friendId = friends[index];

              return FutureBuilder<String>(
                future: db.getUserName(friendId),
                builder: (context, nameSnapshot) {
                  if (!nameSnapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  String friendName = nameSnapshot.data ?? 'Unknown';

                  return FutureBuilder<String>(
                    future: db.getProfileImageUrl(
                        friendId), // Assuming this method fetches the profile image URL
                    builder: (context, imageSnapshot) {
                      String profileImageUrl = imageSnapshot.data ?? '';

                      return Container(
                        width: double.infinity,
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        margin: EdgeInsets.symmetric(vertical: 8),
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
                                  : AssetImage(
                                          'lib/assets/images/shared/placeholder.png')
                                      as ImageProvider,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                friendName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.normal,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.more_vert),
                              onPressed: () =>
                                  _showFriendOptions(context, friendId),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        }
        return Container(); // In case no friends are found.
      },
    );
  }

  // Requests list
  Widget _buildRequestsList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var requestsData = snapshot.data!['contacts']['requests'];

        // Check if requestsData is null or empty
        if (requestsData == null ||
            (requestsData is Map && requestsData.isEmpty)) {
          return Column(
            children: [
              SizedBox(
                height: 20,
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.gray,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  'No requests',
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

        if (requestsData is Map) {
          var requests = requestsData.keys.toList();

          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              String requestId = requests[index];

              return FutureBuilder<String>(
                future: db.getUserName(requestId),
                builder: (context, nameSnapshot) {
                  if (!nameSnapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  String requesterName = nameSnapshot.data ?? 'Unknown';

                  return FutureBuilder<String>(
                    future: db.getProfileImageUrl(
                        requestId), // Assuming this method fetches the profile image URL
                    builder: (context, imageSnapshot) {
                      String profileImageUrl = imageSnapshot.data ?? '';

                      return Container(
                        width: double.infinity,
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        margin: EdgeInsets.symmetric(vertical: 8),
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
                                  : AssetImage(
                                          'lib/assets/images/shared/placeholder.png')
                                      as ImageProvider,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                requesterName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.normal,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () => db.acceptFriendRequest(
                                      currentUserId, requestId),
                                ),
                                IconButton(
                                  icon: Icon(Icons.clear, color: Colors.red),
                                  onPressed: () => db.declineFriendRequest(
                                      currentUserId, requestId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        }
        return Container(); // In case no requests are found.
      },
    );
  }

  Widget _buildHealthcareRequestsList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        // Accessing the nested structure
        var contacts = snapshot.data!['contacts'];
        if (contacts == null || contacts.isEmpty) {
          return _noRequestsMessage('No healthcare requests');
        }

        var healthcare = contacts['healthcare'];
        if (healthcare == null || healthcare.isEmpty) {
          return _noRequestsMessage('No healthcare requests');
        }

        var requests = healthcare['requests'];
        if (requests == null || requests.isEmpty) {
          return _noRequestsMessage('No healthcare requests');
        }

        if (requests is Map) {
          var requestKeys = requests.keys.toList();

          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: requestKeys.length,
            itemBuilder: (context, index) {
              String requestId = requestKeys[index];

              return FutureBuilder<String>(
                future: db.getUserName(requestId),
                builder: (context, nameSnapshot) {
                  if (!nameSnapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  String requesterName = nameSnapshot.data ?? 'Unknown';

                  return FutureBuilder<String>(
                    future: db.getProfileImageUrl(requestId),
                    builder: (context, imageSnapshot) {
                      String profileImageUrl = imageSnapshot.data ?? '';

                      return Container(
                        width: double.infinity,
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        margin: EdgeInsets.symmetric(vertical: 8),
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
                                  : AssetImage(
                                          'lib/assets/images/shared/placeholder.png')
                                      as ImageProvider,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                requesterName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.normal,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () => db.acceptHealthcareRequest(
                                      currentUserId, requestId),
                                ),
                                IconButton(
                                  icon: Icon(Icons.clear, color: Colors.red),
                                  onPressed: () => db.declineHealthcareRequest(
                                      currentUserId, requestId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        }

        return _noRequestsMessage('No healthcare requests');
      },
    );
  }

  Widget _buildCaregiversList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        debugPrint("Contacts: $snapshot");

        // Accessing the nested structure
        var contacts = snapshot.data!['contacts'];
        if (contacts == null || contacts.isEmpty) {
          return _noRequestsMessage('No caregivers added');
        }

        var healthcare = contacts['healthcare'];
        if (healthcare == null || healthcare.isEmpty) {
          return _noRequestsMessage('No caregivers added');
        }

        // Filtering out the 'requests' array and getting only the caregiver documents
        var caregivers = healthcare.entries
            .where((entry) => entry.key != 'requests') // Exclude 'requests' key
            .map((entry) => entry.key) // Get only the caregiver IDs
            .toList();

        if (caregivers.isEmpty) {
          return _noRequestsMessage('No caregivers added');
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: caregivers.length,
          itemBuilder: (context, index) {
            String caregiverId = caregivers[index];

            return FutureBuilder<String>(
              future: db.getUserName(caregiverId),
              builder: (context, nameSnapshot) {
                if (!nameSnapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                String caregiverName = nameSnapshot.data ?? 'Unknown';

                return FutureBuilder<String>(
                  future: db.getProfileImageUrl(
                      caregiverId), // Fetch caregiver's profile image URL
                  builder: (context, imageSnapshot) {
                    String profileImageUrl = imageSnapshot.data ?? '';

                    return Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      margin: EdgeInsets.symmetric(vertical: 8),
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
                                : AssetImage(
                                        'lib/assets/images/shared/placeholder.png')
                                    as ImageProvider,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              caregiverName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.normal,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.more_vert),
                            onPressed: () =>
                                _showCaregiverOptions(context, caregiverId),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

// Helper widget for displaying a no-requests message
  Widget _noRequestsMessage(String message) {
    return Column(
      children: [
        SizedBox(height: 20),
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

  // Friend Options Modal
  Future<void> _showSearchModal(BuildContext context) async {
    final TextEditingController uidController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            'Add Friend',
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
                TextField(
                  controller: uidController,
                  decoration: InputDecoration(
                    labelText: 'Enter User UID',
                    filled: true,
                    fillColor: AppColors.gray,
                    focusColor: AppColors.neon,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.neon),
                    ),
                    labelStyle: TextStyle(color: AppColors.black),
                  ),
                  maxLines: 1,
                  expands: false,
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.normal),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0.0, vertical: 0.0),
                      decoration: BoxDecoration(
                        color: AppColors.neon,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: TextButton(
                        onPressed: () async {
                          String targetUserId = uidController.text.trim();
                          // Check if user exists
                          bool exists = await db.checkUserExists(targetUserId);
                          if (!exists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('User not found')),
                            );
                            return;
                          }

                          // Check if already friends
                          bool isFriend = await db.isUserFriend(
                              currentUserId, targetUserId);
                          if (isFriend) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'You are already friends with this user!')),
                            );
                            return;
                          }

                          // Check if request is pending
                          bool hasPendingRequest = await db.hasPendingRequest(
                              currentUserId, targetUserId);
                          if (hasPendingRequest) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Friend request already sent!')),
                            );
                            return;
                          }

                          // Send the friend request if all checks pass
                          await db.sendFriendRequest(
                              currentUserId, targetUserId);
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Friend request sent!')),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.neon,
                          foregroundColor: AppColors.white,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.group_add),
                            SizedBox(width: 10),
                            Text(
                              'Add friend',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.bold, // Bold text style
                              ),
                            ),
                          ],
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
  }

  Future<void> _showFriendOptions(BuildContext context, String friendId) async {
    // Fetch the friend's name and phone number asynchronously
    String friendName = await db.getUserName(friendId);
    DocumentSnapshot friendDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(friendId)
        .get();

    String phoneNumber = friendDoc['phoneNumber'] ??
        'Not available'; // Assuming phoneNumber field exists

    // Extract the timestamp for when you became friends
    var friendData = friendDoc['contacts']['friends'][currentUserId];

    String formattedTimestamp = 'Unknown';
    if (friendData is Timestamp) {
      formattedTimestamp = DateFormat('yyyy-MM-dd').format(friendData.toDate());
    } else if (friendData is Map) {
      // If the data is a Map, we might need to extract the timestamp from within it
      var timestamp = friendData[
          'timestamp']; // assuming the timestamp is stored as 'timestamp'
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0.0, vertical: 0.0),
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
                              children: [
                                Icon(Icons.call),
                                SizedBox(width: 10),
                                Text(
                                  'Call',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.bold, // Bold text style
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0.0, vertical: 0.0),
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: TextButton(
                            onPressed: () {
                              db.removeFriend(currentUserId, friendId);
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: AppColors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.group_remove), // Keep the icon
                                SizedBox(width: 10),
                                Text(
                                  'Remove', // Changed text to "Remove"
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.bold, // Bold text style
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCaregiverOptions(
      BuildContext context, String caregiverId) async {
    // Fetch caregiver's name and phone number asynchronously
    String caregiverName = await db.getUserName(caregiverId);
    DocumentSnapshot caregiverDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(caregiverId)
        .get();

    String phoneNumber = caregiverDoc['phoneNumber'] ??
        'Not available'; // Assuming phoneNumber field exists

    // Extract the timestamp for when the caregiver was added (from the healthcare map)
    var caregiverData = caregiverDoc['contacts']['healthcare'][currentUserId];

    String formattedTimestamp = 'Unknown';
    if (caregiverData is Timestamp) {
      formattedTimestamp =
          DateFormat('yyyy-MM-dd').format(caregiverData.toDate());
    } else if (caregiverData is Map) {
      // If the data is a Map, we might need to extract the timestamp from within it
      var timestamp = caregiverData[
          'timestamp']; // assuming the timestamp is stored as 'timestamp'
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
            caregiverName,
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0.0, vertical: 0.0),
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
                              children: [
                                Icon(Icons.call),
                                SizedBox(width: 10),
                                Text(
                                  'Call',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.bold, // Bold text style
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0.0, vertical: 0.0),
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: TextButton(
                            onPressed: () {
                              db.removeCaregiver(currentUserId,
                                  caregiverId); // Remove caregiver from the list
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: AppColors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons
                                    .group_remove), // Icon to indicate removal
                                SizedBox(width: 10),
                                Text(
                                  'Remove',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.bold, // Bold text style
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
