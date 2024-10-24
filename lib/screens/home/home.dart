import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solace/models/firestore_user.dart';
import 'package:solace/models/my_user.dart';
import 'package:solace/screens/admin/admin_home.dart';
import 'package:solace/screens/authenticate/authenticate.dart';
import 'package:solace/screens/user/user_home.dart';
import 'package:solace/services/auth.dart';
import 'package:solace/services/database.dart';

class Home extends StatelessWidget {
  Home({super.key});
  
  final CollectionReference userCollection = DatabaseService().userCollection;

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
          // Show a loading spinner or something while waiting for Firestore data
          return Text('Loading...');
        }

        if (snapshot.hasError) {
          // Handle any error that occurs while fetching data
          return Text('Error fetching user data');
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Extract the user data from the Firestore document
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          bool isAdmin = userData['isAdmin'] ?? false;

          // Return the appropriate home screen based on isAdmin flag
          if (isAdmin) {
            return AdminHome();
          } else {
            return UserHome();
          }
        } else {
          // If no user data is found, handle this case
          return Text('User data not found');
        }
      },
    );
  }
}
