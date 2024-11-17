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
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('QR Code'),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        elevation: 0.0,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: AppColors.white,
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
                    top: 150,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: 400,
                      decoration: BoxDecoration(
                        color: AppColors.gray,
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
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 90,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(50)),
                        image: DecorationImage(
                          image: profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                              : const AssetImage('lib/assets/images/shared/placeholder.png') as ImageProvider,
                          fit: BoxFit.cover,
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
