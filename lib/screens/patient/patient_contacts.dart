// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solace/services/database.dart';
import 'package:solace/services/log_service.dart';
import 'package:solace/themes/buttonstyle.dart';
import 'package:solace/themes/colors.dart';
import 'package:solace/themes/dropdownfield.dart';
import 'package:solace/themes/loader.dart';
import 'package:solace/themes/textformfield.dart';
import 'package:solace/themes/textstyle.dart';
import 'package:solace/utility/contact_utility.dart';
import 'package:url_launcher/url_launcher.dart';

class Contacts extends StatefulWidget {
  final String patientId;

  const Contacts({super.key, required this.patientId});

  @override
  ContactsScreenState createState() => ContactsScreenState();
}

class ContactsScreenState extends State<Contacts> {
  final DatabaseService databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LogService _logService = LogService();
  final ContactUtility contactUtil = ContactUtility();
  late final String patientId;
  List<Map<String, dynamic>> nurseContacts = [];
  List<Map<String, dynamic>> relativeContacts = [];

  String collectionName = 'patient';
  bool isLoading = true;
  late String patientName = '';

  @override
  void initState() {
    super.initState();
    patientId = widget.patientId;

    debugPrint("Current user id is: $patientId");
    _initializeContacts();
    _loadPatientName();
    debugPrint("Patient Name: $patientName");
  }

  Future<void> _loadPatientName() async {
    final name = await databaseService.fetchUserName(widget.patientId);
    if (mounted) {
      setState(() {
        patientName = name ?? 'Unknown';
      });
    }
    debugPrint("Patient Name: $patientName");
  }

  Future<void> _initializeContacts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final contacts = await contactUtil.getContacts(widget.patientId);
      debugPrint("Contacts: $contacts");

      setState(() {
        nurseContacts = contacts['nurse'] ?? [];
        relativeContacts = contacts['relative'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error initializing contacts: $e");
      setState(() {
        isLoading = false;
      });
    }
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
    }
  }

  Widget _buildContactsList(List<dynamic> contacts) {
    if (contacts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.gray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "No contacts available",
          textAlign: TextAlign.center,
          style: Textstyle.body,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final contactData = Map<String, dynamic>.from(contacts[index]);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.gray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${contactData['name']}",
                      style: Textstyle.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(contactData['phoneNumber'], style: Textstyle.body),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  _showContactDialog(contactData);
                },
                child: const Icon(
                  Icons.more_vert,
                  size: 24,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryContacts(String title, List<dynamic> contacts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Textstyle.subheader),
        const SizedBox(height: 10),
        _buildContactsList(contacts), // Use your existing method here
      ],
    );
  }

  Widget _buildContactsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryContacts("Nurse Contacts", nurseContacts),
          if (nurseContacts.isEmpty || relativeContacts.isEmpty)
            SizedBox(height: 10),
          _buildCategoryContacts("Relative Contacts", relativeContacts),
        ],
      ),
    );
  }

  void _showContactDialog(Map<String, dynamic> contactData) {
    debugPrint("Contact data: $contactData");
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            contactData['name'] ?? "Unknown Contact",
            style: Textstyle.subheader,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _makeCall(contactData['phoneNumber']);
                },
                child: Row(
                  children: [
                    const Icon(Icons.phone, color: AppColors.black, size: 24),
                    const SizedBox(width: 10),
                    Text('Call', style: Textstyle.body),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _editContact(contactData);
                },
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: AppColors.black, size: 24),
                    const SizedBox(width: 10),
                    Text('Edit Contact', style: Textstyle.body),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _deleteContact(contactData);
                },
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: AppColors.red, size: 24),
                    const SizedBox(width: 10),
                    Text('Delete Contact', style: Textstyle.error),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showToast(String message, {Color? backgroundColor}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor ?? AppColors.neon,
      textColor: AppColors.white,
      fontSize: 16.0,
    );
  }

  void _addContact() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController firstNameController =
            TextEditingController();
        final TextEditingController lastNameController =
            TextEditingController();
        final TextEditingController numberController = TextEditingController();
        final FocusNode firstNameFocusNode = FocusNode();
        final FocusNode lastNameFocusNode = FocusNode();
        final FocusNode numberFocusNode = FocusNode();
        final FocusNode categoryFocusNode = FocusNode();
        String category = "relative";

        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Add Contact", style: Textstyle.subheader),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: firstNameController,
                  focusNode: firstNameFocusNode,
                  labelText: 'First Name',
                  enabled: true,
                  validator:
                      (val) =>
                          val == null || val.isEmpty
                              ? 'First name is required'
                              : null,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: lastNameController,
                  focusNode: lastNameFocusNode,
                  labelText: 'Last Name',
                  enabled: true,
                  validator:
                      (val) =>
                          val == null || val.isEmpty
                              ? 'Last name is required'
                              : null,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: numberController,
                  focusNode: numberFocusNode,
                  labelText: 'Phone Number',
                  enabled: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Phone number is required';
                    }
                    if (!RegExp(r'^09\d{9}$').hasMatch(val)) {
                      return 'Invalid phone number format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                CustomDropdownField<String>(
                  value: category,
                  focusNode: categoryFocusNode,
                  labelText: 'Category',
                  enabled: true,
                  items: const ['relative', 'nurse'],
                  onChanged: (val) {
                    if (val != null) {
                      category = val;
                    }
                  },
                  validator:
                      (val) =>
                          val == null || val.isEmpty
                              ? 'Select a category'
                              : null,
                  displayItem: (item) => item.capitalize(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: Buttonstyle.buttonRed,
                        child: Text("Cancel", style: Textstyle.smallButton),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        style: Buttonstyle.buttonNeon,
                        onPressed: () async {
                          final user = _auth.currentUser;

                          if (user == null) {
                            showToast("Current user is not authenticated", 
                                backgroundColor: AppColors.red);
                            return;
                          }

                          if (firstNameController.text.trim().isEmpty ||
                              lastNameController.text.trim().isEmpty ||
                              numberController.text.trim().isEmpty) {
                            showToast("All fields are required.", 
                                backgroundColor: AppColors.red);
                            return;
                          }

                          final String firstName =
                              firstNameController.text.trim();
                          final String lastName =
                              lastNameController.text.trim();
                          final String phoneNumber =
                              numberController.text.trim();

                          // Ensure no double spaces
                          final cleanedFirstName = firstName.replaceAll(
                            RegExp(r'\s+'),
                            ' ',
                          );
                          final cleanedLastName = lastName.replaceAll(
                            RegExp(r'\s+'),
                            ' ',
                          );
                          final name = '$cleanedFirstName $cleanedLastName';

                          Map<String, dynamic> contactData = {
                            "name": name,
                            "phoneNumber": phoneNumber,
                            "category": category,
                            "createdAt": DateTime.now(),
                          };

                          try {
                            await contactUtil.addContact(
                              userId: widget.patientId,
                              category: category,
                              contactData: contactData,
                            );
                            await _logService.addLog(
                              userId: user.uid,
                              action:
                                  "Added contact $phoneNumber to patient $patientName",
                            );
                            showToast("Contact added successfully.");
                            _initializeContacts();
                            Navigator.pop(context);
                          } catch (e) {
                            showToast("Failed to add contact: $e",  
                                backgroundColor: AppColors.red);
                          }
                        },
                        child: Text(
                          "Add Contact",
                          style: Textstyle.smallButton,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editContact(Map<String, dynamic> contactData) {
    final TextEditingController firstNameController = TextEditingController(
      text:
          contactData['name'].split(
            " ",
          )[0], // Assuming 'name' is "FirstName LastName"
    );
    final TextEditingController lastNameController = TextEditingController(
      text:
          contactData['name'].split(" ").length > 1
              ? contactData['name'].split(" ")[1]
              : "",
    );
    final TextEditingController numberController = TextEditingController(
      text: contactData['phoneNumber'],
    );
    final FocusNode firstNameFocusNode = FocusNode();
    final FocusNode lastNameFocusNode = FocusNode();
    final FocusNode numberFocusNode = FocusNode();
    final FocusNode categoryFocusNode = FocusNode();
    String category = contactData['category'];
    String oldPhoneNumber = contactData['phoneNumber'];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Edit Contact", style: Textstyle.subheader),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: firstNameController,
                  focusNode: firstNameFocusNode,
                  labelText: 'First Name',
                  enabled: true,
                  validator:
                      (val) =>
                          val == null || val.isEmpty
                              ? 'First name is required'
                              : null,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: lastNameController,
                  focusNode: lastNameFocusNode,
                  labelText: 'Last Name',
                  enabled: true,
                  validator:
                      (val) =>
                          val == null || val.isEmpty
                              ? 'Last name is required'
                              : null,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: numberController,
                  focusNode: numberFocusNode,
                  labelText: 'Phone Number',
                  enabled: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Phone number is required';
                    }
                    if (!RegExp(r'^09\d{9}$').hasMatch(val)) {
                      return 'Invalid phone number format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                CustomDropdownField<String>(
                  value: category,
                  focusNode: categoryFocusNode,
                  labelText: 'Category',
                  enabled: true,
                  items: const ['relative', 'nurse'],
                  onChanged: (val) {
                    if (val != null) {
                      category = val;
                    }
                  },
                  validator:
                      (val) =>
                          val == null || val.isEmpty
                              ? 'Select a category'
                              : null,
                  displayItem: (item) => item.capitalize(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: Buttonstyle.buttonRed,
                        child: Text("Cancel", style: Textstyle.smallButton),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        style: Buttonstyle.buttonNeon,
                        onPressed: () async {
                          final user = _auth.currentUser;

                          if (user == null) {
                            showToast("Current user is not authenticated", 
                                backgroundColor: AppColors.red);
                            return;
                          }

                          if (firstNameController.text.trim().isEmpty ||
                              lastNameController.text.trim().isEmpty ||
                              numberController.text.trim().isEmpty) {
                            showToast("All fields are required.", 
                                backgroundColor: AppColors.red);
                            return;
                          }

                          final String firstName =
                              firstNameController.text.trim();
                          final String lastName =
                              lastNameController.text.trim();

                          // Ensure no double spaces
                          final cleanedFirstName = firstName.replaceAll(
                            RegExp(r'\s+'),
                            ' ',
                          );
                          final cleanedLastName = lastName.replaceAll(
                            RegExp(r'\s+'),
                            ' ',
                          );
                          final name = '$cleanedFirstName $cleanedLastName';

                          final updatedContact = {
                            'name': name,
                            'phoneNumber': numberController.text.trim(),
                            'category': category,
                          };

                          if (!RegExp(
                            r'^09\d{9}$',
                          ).hasMatch(updatedContact['phoneNumber']!)) {
                            showToast('Invalid phone number format.', 
                                backgroundColor: AppColors.red);
                            return;
                          }

                          try {
                            await contactUtil.editContact(
                              userId: widget.patientId,
                              category: contactData['category'],
                              updatedContact: updatedContact,
                              oldPhoneNumber: oldPhoneNumber,
                            );

                            Navigator.pop(context);
                            showToast("Contact updated successfully.");

                            await _logService.addLog(
                              userId: user.uid,
                              action:
                                  "Updated contact $oldPhoneNumber from patient $patientName",
                            );
                            _initializeContacts();
                          } catch (e) {
                            debugPrint("Error updating contact: $e");
                            showToast("Failed to update contact.", 
                                backgroundColor: AppColors.red);
                          }
                        },
                        child: Text("Save", style: Textstyle.smallButton),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteContact(Map<String, dynamic> contactData) {
    final String name = contactData['name'] ?? 'Contact';
    final String category = contactData['category'] ?? '';
    final String phoneNumber = contactData['phoneNumber'] ?? '';

    if (category.isEmpty || phoneNumber.isEmpty) {
      showToast("Invalid contact data.", 
          backgroundColor: AppColors.red);
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text("Delete Contact", style: Textstyle.subheader),
          content: Text(
            "Are you sure you want to delete $name?",
            style: Textstyle.body,
          ),
          actions: [
            TextButton(
              style: Buttonstyle.buttonNeon,
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: Textstyle.smallButton),
            ),
            TextButton(
              style: Buttonstyle.buttonRed,
              onPressed: () async {
                try {
                  final user = _auth.currentUser;

                  if (user == null) {
                    showToast("Current user is not authenticated", 
                        backgroundColor: AppColors.red);
                    return;
                  }

                  await contactUtil.deleteContact(
                    userId: widget.patientId,
                    category: category,
                    phoneNumberToDelete: phoneNumber,
                  );

                  await _logService.addLog(
                    userId: user.uid,
                    action:
                        "Deleted contact $phoneNumber from patient $patientName",
                  );
                  Navigator.pop(context);
                  showToast("$name deleted successfully.");
                  _initializeContacts();
                } catch (e) {
                  debugPrint("Error deleting contact: $e");
                  showToast("Failed to delete contact.", 
                      backgroundColor: AppColors.red);
                }
              },
              child: Text("Delete", style: Textstyle.smallButton),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0.0,
        title: Text('Contacts', style: Textstyle.subheader),
        actions: [
          GestureDetector(
            onTap: _addContact,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add, size: 24, color: AppColors.black),
                  SizedBox(width: 6),
                  Text(
                    "Add Contacts",
                    style: TextStyle(fontSize: 14, color: AppColors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body:
          isLoading ? Center(child: Loader.loaderPurple) : _buildContactsView(),
    );
  }
}
