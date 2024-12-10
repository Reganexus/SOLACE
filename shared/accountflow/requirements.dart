// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solace/shared/accountflow/waiting.dart';

class RequirementsScreen extends StatefulWidget {
  const RequirementsScreen({super.key});

  @override
  _RequirementsScreenState createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedInstitution;
  String? patientUid; // For caregiver role
  final List<String> institutions = ['Ruth Foundation'];
  String? userRole; // Nullable String
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        setState(() {
          userRole = userDoc['userRole'];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user role: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _verifyPatientUid(String uid) async {
    final patientRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final patientDoc = await patientRef.get();

    if (patientDoc.exists) {
      // Send verification request
      final caregiverUid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('verificationRequests').add({
        'caregiverUid': caregiverUid,
        'patientUid': uid,
        'authenticate': 'pending',
        'createdAt': DateTime.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification request sent to patient.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Patient UID not found.')),
      );
    }
  }

  Future<void> _submitApplication() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && _formKey.currentState!.validate()) {
        if (userRole == 'Patient' || userRole == 'Doctor') {
          // Update user document for patients or doctors
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'institution': selectedInstitution,
            'authenticate': 'pending', // Status for admin verification
          });
        } else if (userRole == 'Caregiver') {
          // Handle caregiver-specific logic
          await _verifyPatientUid(patientUid!);
        }

        // Navigate to the WaitingScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingScreen(
              userRole: userRole,
              institution: selectedInstitution,
              status: 'pending',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error submitting application: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit application.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userRole == null) {
      return Scaffold(
        body: Center(child: Text('Failed to load user role.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Requirements')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedInstitution,
                items: institutions
                    .map((institution) => DropdownMenuItem(
                          value: institution,
                          child: Text(institution),
                        ))
                    .toList(),
                onChanged: (value) => setState(() {
                  selectedInstitution = value;
                }),
                decoration: InputDecoration(labelText: 'Select Institution'),
                validator: (value) =>
                    value == null ? 'Please select an institution' : null,
              ),
              if (userRole == 'Caregiver')
                TextFormField(
                  decoration: InputDecoration(labelText: 'Patient UID'),
                  onChanged: (value) => setState(() {
                    patientUid = value;
                  }),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter patient UID'
                      : null,
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitApplication,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
