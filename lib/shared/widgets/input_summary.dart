// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';

class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> inputs;
  final String uid;

  const ReceiptScreen({super.key, required this.inputs, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Summary'),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Assessment',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                'Vitals:',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              ...inputs['Vitals'].entries.map((entry) {
                return Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                );
              }).toList(), // Ensure the map is properly converted to a list
              const SizedBox(height: 20.0),
              Text(
                'Pain Assessment:',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 10.0),
              ...inputs['Pain Assessment'].entries.map((entry) {
                return Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                );
              }).toList(), // Ensure the map is properly converted to a list
              const SizedBox(height: 20),
              const Divider(thickness: 1.0),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () async {
                    try {
                      // Get the current timestamp
                      final timestamp = Timestamp.now();

                      // Prepare the data to be inserted
                      final trackingData = {
                        'timestamp': timestamp,
                        'Vitals': inputs['Vitals'],
                        'Pain Assessment': inputs['Pain Assessment'],
                      };

                      // Get reference to the patient's document in the 'tracking' collection
                      final trackingRef = FirebaseFirestore.instance
                          .collection('tracking')
                          .doc(uid);

                      // Get the document snapshot to check if the 'tracking' data exists
                      final docSnapshot = await trackingRef.get();

                      if (docSnapshot.exists) {
                        // If the document exists, update the 'tracking' array
                        await trackingRef.update({
                          'tracking': FieldValue.arrayUnion([trackingData])
                        }).catchError((e) {
                          print("Error storing data: $e");
                          // Show error snack bar if update fails
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error storing data: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        });
                      } else {
                        // If the document doesn't exist, create the document with the tracking data
                        await trackingRef.set({
                          'tracking': [trackingData]
                        }).catchError((e) {
                          print("Error storing data: $e");
                          // Show error snack bar if set fails
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error storing data: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        });
                      }

                      // Navigate back after successful submission
                      Navigator.pop(context);

                      // Show success snack bar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data submitted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      // Handle any unexpected errors
                      print("Unexpected error: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('An unexpected error occurred: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    backgroundColor: AppColors.neon,
                  ),
                  child: const Text(
                    'Submit Final',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
