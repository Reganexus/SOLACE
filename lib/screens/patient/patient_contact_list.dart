import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactList extends StatelessWidget {
  final String title;
  final Future<List<Map<String, dynamic>>> Function() fetchContacts;

  const ContactList({
    super.key,
    required this.title,
    required this.fetchContacts,
  });

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

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
      showToast('Phone permission denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(title, style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchContacts()
            .then((contacts) {
              // Debugging: Log the fetched contacts
              debugPrint('Fetched Contacts: ${contacts.length}');
              for (var contact in contacts) {
                debugPrint('Contact: $contact');
              }
              return contacts;
            })
            .catchError((error) {
              // Debugging: Log any error
              debugPrint('Error fetching contacts: $error');
              throw error;
            }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            debugPrint('Snapshot Error: ${snapshot.error}');
            return const Center(child: Text('Error loading contacts'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            debugPrint('No contacts found.');
            return const Center(child: Text('No contacts found'));
          }

          List<Map<String, dynamic>> contacts = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              var contact = contacts[index];
              String name = contact['name'] ?? 'No name available';
              String phone =
                  title == 'Doctors'
                      ? contact['phone']
                      : contact['phoneNumber'] ?? 'No phone available';
              String profileImageUrl = contact['profileImageUrl'] ?? '';

              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 10,
                ),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.gray,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage:
                          profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                              : const AssetImage(
                                    'lib/assets/images/shared/placeholder.png',
                                  )
                                  as ImageProvider,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: Textstyle.body,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone, color: AppColors.black),
                      onPressed: () async {
                        if (phone != 'No phone available') {
                          await _makeCall(phone);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No phone number available'),
                            ),
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
