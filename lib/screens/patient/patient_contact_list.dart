import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/loader.dart';
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

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
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
        //         debugPrint('Could not launch $launchUri');
      }
    } else {
      //       debugPrint('Phone permission denied');
      showToast('Phone permission denied', backgroundColor: AppColors.red);
    }
  }

  Widget _buildNoContactsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.close_rounded, color: AppColors.black, size: 70),
          SizedBox(height: 20.0),
          Text("No Contacts Found", style: Textstyle.body),
        ],
      ),
    );
  }

  Widget _buildErrorContacts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.close_rounded, color: AppColors.black, size: 70),
          SizedBox(height: 20.0),
          Text("Error Finding Contacts", style: Textstyle.body),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Call $title', style: Textstyle.subheader),
        backgroundColor: AppColors.white,
        centerTitle: true,
        scrolledUnderElevation: 0.0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchContacts()
            .then((contacts) {
              // Debugging: Log the fetched contacts
              //               debugPrint('Fetched Contacts: ${contacts.length}');
              return contacts;
            })
            .catchError((error) {
              // Debugging: Log any error
              //               debugPrint('Error fetching contacts: $error');
              throw error;
            }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Loader.loaderPurple);
          } else if (snapshot.hasError) {
            //             debugPrint('Snapshot Error: ${snapshot.error}');
            return _buildErrorContacts();
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            //             debugPrint('No contacts found.');
            return _buildNoContactsFound();
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
