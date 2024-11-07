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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Friend request sent!')),
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
      appBar: AppBar(
        title: Text('Contacts'),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            iconSize: 30.0,
            onPressed: () => _showSearchModal(context),
          ),
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            iconSize: 30.0,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QRScannerPage()),
              );

              if (result != null) {
                // Return the barcode data back to the previous screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('QR Code detected')),
                );
                _handleQRScanResult(context, result);
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            children: [
              _buildHeader('Friends'),
              _buildFriendsList(),
              SizedBox(height: 20),
              _buildHeader('Friend Requests'),
              _buildRequestsList(),
            ],
          ),
        ),
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

                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
                          backgroundImage: AssetImage(
                              'lib/assets/images/shared/placeholder.png'),
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

                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
                          backgroundImage: AssetImage(
                              'lib/assets/images/shared/placeholder.png'),
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
        }
        return Container(); // In case no requests are found.
      },
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
}
