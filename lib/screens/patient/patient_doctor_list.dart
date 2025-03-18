import 'package:flutter/material.dart';
import 'package:solace/themes/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactList extends StatelessWidget {
  final String title;
  final Future<List<Map<String, dynamic>>> Function() fetchContacts;

  const ContactList({super.key, required this.title, required this.fetchContacts});

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await Permission.phone.request().isGranted) {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        debugPrint('Could not launch $launchUri');
      }
    } else {
      debugPrint('Phone permission denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchContacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading contacts'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No contacts found'));
          }

          List<Map<String, dynamic>> contacts = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              var contact = contacts[index];
              String name = contact['name'] ?? 'No name available';
              String phone = contact['phone'] ?? 'No phone available';

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gray,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: contact['profileImageUrl'] != null &&
                          contact['profileImageUrl'].isNotEmpty
                          ? NetworkImage(contact['profileImageUrl'])
                          : const AssetImage('lib/assets/images/shared/placeholder.png')
                      as ImageProvider,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
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
                    icon: const Icon(Icons.phone, color: AppColors.black),
                    onPressed: () async {
                      if (phone != 'No phone available') {
                        await _makeCall(phone);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No phone number available')),
                        );
                      }
                    },
                  ),



              ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
