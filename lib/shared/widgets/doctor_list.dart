import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorList extends StatelessWidget {
  final String uid;

  const DoctorList({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Doctor List'),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection(
                'doctors') // Fetch all documents from the doctors collection
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading doctors'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No doctors found'));
          }

          List<QueryDocumentSnapshot> doctors = snapshot.data!.docs;

          return SingleChildScrollView(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
              child: Column(
                children: [
                  _buildDoctorList(doctors),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorList(List<QueryDocumentSnapshot> doctors) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        var doctor = doctors[index].data() as Map<String, dynamic>;

        String doctorFirstName = doctor['firstName'] ?? '';
        String doctorMiddleName = doctor['middleName'] ?? '';
        String doctorLastName = doctor['lastName'] ?? '';

        String doctorName =
            '$doctorFirstName ${doctorMiddleName.isNotEmpty ? '$doctorMiddleName ' : ''}$doctorLastName'
                .trim();

        String doctorPhone = doctor['phoneNumber'] ?? 'No phone available';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: doctor['profileImageUrl'] != null &&
                        doctor['profileImageUrl'].isNotEmpty
                    ? NetworkImage(doctor['profileImageUrl'])
                    : const AssetImage(
                            'lib/assets/images/shared/placeholder.png')
                        as ImageProvider,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  doctorName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () async {
                  if (doctorPhone != 'No phone available') {
                    final Uri phoneUri = Uri(scheme: 'tel', path: doctorPhone);
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cannot make a call')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('No phone number available')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
