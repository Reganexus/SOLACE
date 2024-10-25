import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/admin/admin_home.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/screens/user/user_home.dart';
import 'package:solace/services/database.dart';

class Home extends StatelessWidget {
  final CollectionReference userCollection = DatabaseService().userCollection;

  Home({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);
    if (user == null) {
      // If user is not logged in, show Authenticate screen
      return Authenticate();
    }

    // Use FutureBuilder to fetch the current user data from Firestore
    return FutureBuilder<DocumentSnapshot>(
      future: userCollection.doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading spinner while waiting for Firestore data
          return Text('Loading...');
        }

        if (snapshot.hasError) {
          // Handle any error that occurs while fetching data
          return Text('Error fetching user data');
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Check if the document has data before casting
          final userData = snapshot.data!.data();
          if (userData == null) {
            return UserHome(); // No data means new user
          }

          // Cast to Map<String, dynamic> after confirming it's not null
          var userMap = userData as Map<String, dynamic>;
          bool isAdmin = userMap['isAdmin'] ?? false;

          // Return the appropriate home screen based on isAdmin flag
          return isAdmin ? AdminHome() : UserHome();
        } else {
          // Handle the case where no user data is found
          return Text('User data not found');
        }
      },
    );
  }
}