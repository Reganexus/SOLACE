import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solace/themes/colors.dart';

class ShowQrPage extends StatelessWidget {
  final String fullName;
  final String uid;
  final String profileImageUrl; // This is the named parameter

  const ShowQrPage({
    super.key,
    required this.fullName,
    required this.uid,
    required this.profileImageUrl, // Make sure profileImageUrl is passed here
  });

  // Firestore reference for the user data
  Stream<DocumentSnapshot> _getUserProfileStream(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neon,
      appBar: AppBar(
        title: const Text('QR Code'),
        backgroundColor: AppColors.neon,
        scrolledUnderElevation: 0.0,
        elevation: 0.0,
        iconTheme: IconThemeData(color: AppColors.white), // Set back button color to white
        titleTextStyle: TextStyle(
          color: AppColors.white, // Set title text color to white
          fontSize: 20, // You can customize the font size if needed
          fontWeight: FontWeight.bold, // You can adjust the font weight as well
        ),
      ),

      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: AppColors.neon,
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: _getUserProfileStream(uid),
            builder: (context, snapshot) {
              // Handle loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Handle error state
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              // Handle no data state
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('No user data found'));
              }

              // Get user data from Firestore document
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              String profileImageUrl = userData['profileImageUrl'] ?? '';

              return Stack(
                alignment: AlignmentDirectional.topCenter,
                children: [
                  Positioned(
                    top: 200,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: 380,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: QrImageView(
                              data: uid,
                              version: QrVersions.auto,
                              size: 200.0,
                              gapless: false,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  fullName,
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow
                                      .ellipsis, // This will add ellipsis for overflowed text
                                  maxLines:
                                  1, // This ensures the text will be in one line and overflow as needed
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 110,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius:
                        const BorderRadius.all(Radius.circular(50)),
                        image: DecorationImage(
                          image: profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                              : const AssetImage(
                              'lib/assets/images/shared/placeholder.png')
                          as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(
                          color:
                          AppColors.white, // Set the border color to white
                          width: 10, // Set the border width to at least 2
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}