import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/services/database.dart';
import 'package:solace/shared/widgets/qr_scanner.dart';

class Contacts extends StatelessWidget {
  final String userId;

  const Contacts({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Contacts"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _showSearchModal(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QRScannerPage(userId: userId)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading contacts"));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text("No contacts found"));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          var contacts = data['contacts'] ?? {
            'friends': [],
            'pending': [],
            'requests': [],
          };

          List friends = contacts['friends'] ?? [];
          List pending = contacts['pending'] ?? [];
          List requests = contacts['requests'] ?? [];

          return ListView(
            children: [
              _buildSectionTitle("Friends"),
              _buildContactsList(friends, context, isFriendList: true),
              _buildSectionTitle("Pending Requests"),
              _buildContactsList(pending, context, isPendingList: true),
              _buildSectionTitle("Requests Received"),
              _buildContactsList(requests, context, isRequestList: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper for contact lists
  Widget _buildContactsList(List contacts, BuildContext context, {bool isFriendList = false, bool isPendingList = false, bool isRequestList = false}) {
    if (contacts.isEmpty) {
      return Center(child: Text("No ${isFriendList ? 'friends' : isPendingList ? 'pending requests' : 'requests'} found"));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        String contactId = contacts[index]['userId'];

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(contactId).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return ListTile(
                title: Text("Loading..."),
                subtitle: Text(contactId),
              );
            }

            if (userSnapshot.hasError || !userSnapshot.hasData) {
              return ListTile(
                title: Text("Error loading name"),
                subtitle: Text(contactId),
              );
            }

            // Extract firstName, middleName, lastName
            var firstName = userSnapshot.data?.get('firstName').trim() ?? '';
            var middleName = userSnapshot.data?.get('middleName').trim() ?? '';
            var lastName = userSnapshot.data?.get('lastName').trim() ?? '';

            // Combine the name components
            String contactName = '$firstName ${middleName.isNotEmpty ? middleName + ' ' : ''}$lastName';

            return ListTile(
              title: Text(contactName.isEmpty ? "Unknown" : contactName),
              subtitle: Text(contactId),
              trailing: _buildContactActions(contactId, context, isFriendList, isPendingList, isRequestList),
            );
          },
        );
      },
    );
  }

  Widget _buildContactActions(String contactId, BuildContext context, bool isFriendList, bool isPendingList, bool isRequestList) {
    if (isFriendList) {
      return IconButton(
        icon: Icon(Icons.delete, color: Colors.red),
        onPressed: () async {
          await DatabaseService(uid: userId).removeFriend(userId, contactId);
        },
      );
    } else if (isPendingList) {
      return IconButton(
        icon: Icon(Icons.cancel, color: Colors.orange),
        onPressed: () async {
          await DatabaseService(uid: userId).rejectFriendRequest(userId, contactId);
        },
      );
    } else if (isRequestList) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.green),
            onPressed: () async {
              await DatabaseService(uid: userId).acceptFriendRequest(userId, contactId);
            },
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: () async {
              await DatabaseService(uid: userId).rejectFriendRequest(userId, contactId);
            },
          ),
        ],
      );
    }
    return SizedBox.shrink();
  }

  void _showSearchModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController userIdController = TextEditingController();
        return AlertDialog(
          title: Text('Enter User ID'),
          content: TextField(
            controller: userIdController,
            decoration: InputDecoration(hintText: 'User ID'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Send Request'),
              onPressed: () async {
                String targetUserId = userIdController.text;
                if (targetUserId.isNotEmpty) {
                  bool alreadySent = await _hasPendingRequest(targetUserId);
                  if (alreadySent) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request already sent or received')));
                    Navigator.of(context).pop();
                  } else {
                    await DatabaseService(uid: userId).sendFriendRequest(userId, targetUserId);
                    Navigator.of(context).pop(); // Close modal
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Friend request sent to $targetUserId')));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _hasPendingRequest(String targetUserId) async {
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    var contacts = userDoc.data()?['contacts'] ?? {'pending': []};
    var pending = contacts['pending'] ?? [];
    return pending.any((request) => request['userId'] == targetUserId);
  }
}
